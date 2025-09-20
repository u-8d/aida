import 'package:supabase_flutter/supabase_flutter.dart';

class RealTimeAnalyticsService {
  final _supabase = Supabase.instance.client;
  
  // Cache for analytics data with timestamps
  Map<String, dynamic> _analyticsCache = {};
  DateTime? _lastCacheUpdate;
  static const _cacheValidityDuration = Duration(minutes: 2);

  /// Get comprehensive platform analytics
  Future<Map<String, dynamic>> getPlatformAnalytics() async {
    // Return cached data if still valid
    if (_isAnalyticsCacheValid()) {
      return _analyticsCache;
    }

    try {
      final analytics = await _fetchPlatformAnalytics();
      _analyticsCache = analytics;
      _lastCacheUpdate = DateTime.now();
      return analytics;
    } catch (e) {
      print('Error fetching platform analytics: $e');
      // Return cached data if available, otherwise empty structure
      return _analyticsCache.isNotEmpty ? _analyticsCache : _getEmptyAnalytics();
    }
  }

  /// Fetch real-time analytics from database
  Future<Map<String, dynamic>> _fetchPlatformAnalytics() async {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));
    final last30Days = now.subtract(const Duration(days: 30));

    // Execute all queries in parallel for better performance
    final futures = await Future.wait([
      _getUserAnalytics(last24Hours, last7Days, last30Days),
      _getDonationAnalytics(last24Hours, last7Days, last30Days),
      _getCampaignAnalytics(last24Hours, last7Days, last30Days),
      _getSystemPerformance(),
      _getGeographicAnalytics(),
      _getSurgeAnalytics(last24Hours),
    ]);

    return {
      'timestamp': now.toIso8601String(),
      'users': futures[0],
      'donations': futures[1],
      'campaigns': futures[2],
      'system': futures[3],
      'geographic': futures[4],
      'surge': futures[5],
      'alerts': await _getSystemAlerts(),
    };
  }

  /// Get user analytics (registrations, active users, demographics)
  Future<Map<String, dynamic>> _getUserAnalytics(
    DateTime last24Hours,
    DateTime last7Days,
    DateTime last30Days,
  ) async {
    try {
      // Total users
      final totalUsersResponse = await _supabase
          .from('users')
          .select('id')
          .count(CountOption.exact);

      // New registrations in different time periods
      final registrations24h = await _supabase
          .from('users')
          .select('id')
          .gte('created_at', last24Hours.toIso8601String())
          .count(CountOption.exact);

      final registrations7d = await _supabase
          .from('users')
          .select('id')
          .gte('created_at', last7Days.toIso8601String())
          .count(CountOption.exact);

      final registrations30d = await _supabase
          .from('users')
          .select('id')
          .gte('created_at', last30Days.toIso8601String())
          .count(CountOption.exact);

      // Active users (users who logged in recently)
      final activeUsers24h = await _supabase
          .from('users')
          .select('id')
          .gte('last_sign_in_at', last24Hours.toIso8601String())
          .count(CountOption.exact);

      // User types distribution
      final userTypes = await _supabase
          .from('users')
          .select('user_type')
          .not('user_type', 'is', null);

      final typeDistribution = <String, int>{};
      for (final user in userTypes) {
        final type = user['user_type'] as String? ?? 'unknown';
        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
      }

      return {
        'total': totalUsersResponse.count,
        'new_24h': registrations24h.count,
        'new_7d': registrations7d.count,
        'new_30d': registrations30d.count,
        'active_24h': activeUsers24h.count,
        'type_distribution': typeDistribution,
        'growth_rate_7d': _calculateGrowthRate(registrations7d.count, registrations30d.count - registrations7d.count),
      };
    } catch (e) {
      print('Error fetching user analytics: $e');
      return _getEmptyUserAnalytics();
    }
  }

  /// Get donation analytics (volume, value, velocity)
  Future<Map<String, dynamic>> _getDonationAnalytics(
    DateTime last24Hours,
    DateTime last7Days,
    DateTime last30Days,
  ) async {
    try {
      // Total donations
      final totalDonationsResponse = await _supabase
          .from('donations')
          .select('id, amount')
          .count(CountOption.exact);

      // Recent donations
      final donations24h = await _supabase
          .from('donations')
          .select('amount')
          .gte('created_at', last24Hours.toIso8601String());

      final donations7d = await _supabase
          .from('donations')
          .select('amount')
          .gte('created_at', last7Days.toIso8601String());

      final donations30d = await _supabase
          .from('donations')
          .select('amount')
          .gte('created_at', last30Days.toIso8601String());

      // Calculate totals and averages
      final totalAmount24h = donations24h.fold<double>(
        0.0,
        (sum, donation) => sum + (donation['amount'] as num? ?? 0).toDouble(),
      );

      final totalAmount7d = donations7d.fold<double>(
        0.0,
        (sum, donation) => sum + (donation['amount'] as num? ?? 0).toDouble(),
      );

      final totalAmount30d = donations30d.fold<double>(
        0.0,
        (sum, donation) => sum + (donation['amount'] as num? ?? 0).toDouble(),
      );

      // Donation velocity (donations per hour)
      final velocity24h = donations24h.length / 24.0;
      final velocity7d = donations7d.length / (7.0 * 24.0);

      // Average donation amount
      final avgDonation24h = donations24h.isEmpty ? 0.0 : totalAmount24h / donations24h.length;
      final avgDonation7d = donations7d.isEmpty ? 0.0 : totalAmount7d / donations7d.length;

      return {
        'total_count': totalDonationsResponse.count,
        'count_24h': donations24h.length,
        'count_7d': donations7d.length,
        'count_30d': donations30d.length,
        'amount_24h': totalAmount24h,
        'amount_7d': totalAmount7d,
        'amount_30d': totalAmount30d,
        'avg_amount_24h': avgDonation24h,
        'avg_amount_7d': avgDonation7d,
        'velocity_per_hour_24h': velocity24h,
        'velocity_per_hour_7d': velocity7d,
        'growth_rate_7d': _calculateGrowthRate(donations7d.length, donations30d.length - donations7d.length),
      };
    } catch (e) {
      print('Error fetching donation analytics: $e');
      return _getEmptyDonationAnalytics();
    }
  }

  /// Get campaign analytics (active campaigns, success rates, resource utilization)
  Future<Map<String, dynamic>> _getCampaignAnalytics(
    DateTime last24Hours,
    DateTime last7Days,
    DateTime last30Days,
  ) async {
    try {
      // Total campaigns
      final totalCampaigns = await _supabase
          .from('disaster_campaigns')
          .select('id, status, disaster_type, is_emergency_mode, completion_percentage')
          .count(CountOption.exact);

      // Campaign status distribution
      final campaigns = await _supabase
          .from('disaster_campaigns')
          .select('status, disaster_type, is_emergency_mode, completion_percentage, created_at');

      final statusDistribution = <String, int>{};
      final typeDistribution = <String, int>{};
      var emergencyCount = 0;
      var completedCount = 0;
      var totalCompletionRate = 0.0;

      for (final campaign in campaigns) {
        final status = campaign['status'] as String;
        final type = campaign['disaster_type'] as String;
        final isEmergency = campaign['is_emergency_mode'] as bool? ?? false;
        final completion = (campaign['completion_percentage'] as num? ?? 0).toDouble();

        statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;
        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
        
        if (isEmergency) emergencyCount++;
        if (status == 'completed') completedCount++;
        totalCompletionRate += completion;
      }

      final avgCompletionRate = campaigns.isEmpty ? 0.0 : totalCompletionRate / campaigns.length;

      // Recent campaign activity
      final recentCampaigns = campaigns.where((c) {
        final createdAt = DateTime.parse(c['created_at'] as String);
        return createdAt.isAfter(last7Days);
      }).length;

      return {
        'total': totalCampaigns.count,
        'recent_7d': recentCampaigns,
        'emergency_active': emergencyCount,
        'completed': completedCount,
        'avg_completion_rate': avgCompletionRate,
        'status_distribution': statusDistribution,
        'type_distribution': typeDistribution,
        'success_rate': campaigns.isEmpty ? 0.0 : (completedCount / campaigns.length) * 100,
      };
    } catch (e) {
      print('Error fetching campaign analytics: $e');
      return _getEmptyCampaignAnalytics();
    }
  }

  /// Get system performance metrics
  Future<Map<String, dynamic>> _getSystemPerformance() async {
    final now = DateTime.now();
    
    // Simulate system metrics (in a real app, these would come from monitoring services)
    return {
      'response_time_ms': 150 + (DateTime.now().millisecond % 100), // Simulated
      'error_rate_percent': 0.5 + (DateTime.now().millisecond % 10) * 0.1, // Simulated
      'uptime_percent': 99.9, // Simulated
      'active_connections': 1250 + (DateTime.now().second % 500), // Simulated
      'memory_usage_percent': 65 + (DateTime.now().second % 20), // Simulated
      'cpu_usage_percent': 45 + (DateTime.now().second % 30), // Simulated
      'database_connections': 25 + (DateTime.now().second % 10), // Simulated
      'last_updated': now.toIso8601String(),
    };
  }

  /// Get geographic distribution of users and donations
  Future<Map<String, dynamic>> _getGeographicAnalytics() async {
    try {
      // This would typically integrate with location data
      // For now, returning simulated data structure
      return {
        'user_distribution': {
          'Karnataka': 450,
          'Maharashtra': 380,
          'Tamil Nadu': 320,
          'Delhi': 280,
          'Gujarat': 250,
          'Rajasthan': 200,
          'Other': 150,
        },
        'donation_heatmap': {
          'Karnataka': 125000,
          'Maharashtra': 98000,
          'Tamil Nadu': 87000,
          'Delhi': 75000,
          'Gujarat': 65000,
          'Rajasthan': 45000,
          'Other': 35000,
        },
        'active_campaigns_by_state': {
          'Karnataka': 3,
          'Maharashtra': 2,
          'Tamil Nadu': 4,
          'Delhi': 1,
          'Gujarat': 2,
          'Rajasthan': 3,
        },
      };
    } catch (e) {
      print('Error fetching geographic analytics: $e');
      return {'user_distribution': {}, 'donation_heatmap': {}, 'active_campaigns_by_state': {}};
    }
  }

  /// Get surge analytics (detect unusual spikes in activity)
  Future<Map<String, dynamic>> _getSurgeAnalytics(DateTime last24Hours) async {
    try {
      // Get hourly breakdown of the last 24 hours
      final hourlyData = <String, Map<String, int>>{};
      
      for (int i = 0; i < 24; i++) {
        final hourStart = last24Hours.add(Duration(hours: i));
        final hourEnd = hourStart.add(const Duration(hours: 1));
        
        // Get registrations for this hour
        final registrations = await _supabase
            .from('users')
            .select('id')
            .gte('created_at', hourStart.toIso8601String())
            .lt('created_at', hourEnd.toIso8601String())
            .count(CountOption.exact);

        // Get donations for this hour
        final donations = await _supabase
            .from('donations')
            .select('id')
            .gte('created_at', hourStart.toIso8601String())
            .lt('created_at', hourEnd.toIso8601String())
            .count(CountOption.exact);

        hourlyData[hourStart.hour.toString().padLeft(2, '0')] = {
          'registrations': registrations.count,
          'donations': donations.count,
        };
      }

      // Calculate surge indicators
      final avgRegistrationsPerHour = hourlyData.values
          .map((h) => h['registrations']!)
          .reduce((a, b) => a + b) / 24.0;
      
      final avgDonationsPerHour = hourlyData.values
          .map((h) => h['donations']!)
          .reduce((a, b) => a + b) / 24.0;

      // Detect surges (activity > 200% of average)
      final surgeThreshold = 2.0;
      final registrationSurges = <String>[];
      final donationSurges = <String>[];

      hourlyData.forEach((hour, data) {
        if (data['registrations']! > avgRegistrationsPerHour * surgeThreshold) {
          registrationSurges.add(hour);
        }
        if (data['donations']! > avgDonationsPerHour * surgeThreshold) {
          donationSurges.add(hour);
        }
      });

      return {
        'hourly_breakdown': hourlyData,
        'avg_registrations_per_hour': avgRegistrationsPerHour,
        'avg_donations_per_hour': avgDonationsPerHour,
        'registration_surges': registrationSurges,
        'donation_surges': donationSurges,
        'is_surge_detected': registrationSurges.isNotEmpty || donationSurges.isNotEmpty,
        'surge_intensity': _calculateSurgeIntensity(hourlyData, avgRegistrationsPerHour, avgDonationsPerHour),
      };
    } catch (e) {
      print('Error fetching surge analytics: $e');
      return _getEmptySurgeAnalytics();
    }
  }

  /// Get system alerts and notifications
  Future<List<Map<String, dynamic>>> _getSystemAlerts() async {
    final alerts = <Map<String, dynamic>>[];
    
    try {
      // Check for various alert conditions
      final analytics = await _fetchPlatformAnalytics();
      
      // User surge alert
      final surgData = analytics['surge'] as Map<String, dynamic>;
      if (surgData['is_surge_detected'] == true) {
        alerts.add({
          'type': 'surge',
          'severity': 'warning',
          'title': 'User Activity Surge Detected',
          'message': 'Unusual spike in user registrations or donations detected',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      // System performance alerts
      final systemData = analytics['system'] as Map<String, dynamic>;
      if (systemData['response_time_ms'] > 500) {
        alerts.add({
          'type': 'performance',
          'severity': 'warning',
          'title': 'High Response Time',
          'message': 'System response time is above normal threshold',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      if (systemData['error_rate_percent'] > 2.0) {
        alerts.add({
          'type': 'error',
          'severity': 'critical',
          'title': 'High Error Rate',
          'message': 'System error rate is above acceptable threshold',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      // Campaign alerts
      final campaignData = analytics['campaigns'] as Map<String, dynamic>;
      if (campaignData['emergency_active'] > 0) {
        alerts.add({
          'type': 'emergency',
          'severity': 'critical',
          'title': 'Emergency Campaigns Active',
          'message': '${campaignData['emergency_active']} emergency campaigns require attention',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

    } catch (e) {
      print('Error generating system alerts: $e');
    }

    return alerts;
  }

  /// Get real-time metrics for live monitoring
  Stream<Map<String, dynamic>> getLiveMetrics() async* {
    while (true) {
      try {
        final metrics = await _fetchLiveMetrics();
        yield metrics;
        await Future.delayed(const Duration(seconds: 10)); // Update every 10 seconds
      } catch (e) {
        print('Error in live metrics stream: $e');
        await Future.delayed(const Duration(seconds: 30)); // Retry after 30 seconds on error
      }
    }
  }

  /// Fetch metrics optimized for real-time updates
  Future<Map<String, dynamic>> _fetchLiveMetrics() async {
    final now = DateTime.now();
    final last5Minutes = now.subtract(const Duration(minutes: 5));

    // Get recent activity
    final recentRegistrations = await _supabase
        .from('users')
        .select('id')
        .gte('created_at', last5Minutes.toIso8601String())
        .count(CountOption.exact);

    final recentDonations = await _supabase
        .from('donations')
        .select('id, amount')
        .gte('created_at', last5Minutes.toIso8601String());

    final recentAmount = recentDonations.fold<double>(
      0.0,
      (sum, donation) => sum + (donation['amount'] as num? ?? 0).toDouble(),
    );

    // Active sessions (simulated)
    final activeSessions = 850 + (DateTime.now().second % 200);

    return {
      'timestamp': now.toIso8601String(),
      'recent_registrations_5m': recentRegistrations.count,
      'recent_donations_5m': recentDonations.length,
      'recent_amount_5m': recentAmount,
      'active_sessions': activeSessions,
      'system_load': (45 + DateTime.now().second % 30).toDouble(),
      'response_time': (120 + DateTime.now().millisecond % 80).toDouble(),
    };
  }

  // Helper methods
  bool _isAnalyticsCacheValid() {
    return _lastCacheUpdate != null && 
           DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
  }

  double _calculateGrowthRate(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100.0;
  }

  double _calculateSurgeIntensity(
    Map<String, Map<String, int>> hourlyData,
    double avgRegistrations,
    double avgDonations,
  ) {
    double maxIntensity = 0.0;
    
    hourlyData.forEach((hour, data) {
      final regIntensity = avgRegistrations > 0 ? data['registrations']! / avgRegistrations : 1.0;
      final donIntensity = avgDonations > 0 ? data['donations']! / avgDonations : 1.0;
      final intensity = (regIntensity + donIntensity) / 2.0;
      
      if (intensity > maxIntensity) {
        maxIntensity = intensity;
      }
    });
    
    return maxIntensity;
  }

  // Empty data structures for error handling
  Map<String, dynamic> _getEmptyAnalytics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'users': _getEmptyUserAnalytics(),
      'donations': _getEmptyDonationAnalytics(),
      'campaigns': _getEmptyCampaignAnalytics(),
      'system': _getEmptySystemAnalytics(),
      'geographic': {'user_distribution': {}, 'donation_heatmap': {}},
      'surge': _getEmptySurgeAnalytics(),
      'alerts': <Map<String, dynamic>>[],
    };
  }

  Map<String, dynamic> _getEmptyUserAnalytics() {
    return {
      'total': 0,
      'new_24h': 0,
      'new_7d': 0,
      'new_30d': 0,
      'active_24h': 0,
      'type_distribution': <String, int>{},
      'growth_rate_7d': 0.0,
    };
  }

  Map<String, dynamic> _getEmptyDonationAnalytics() {
    return {
      'total_count': 0,
      'count_24h': 0,
      'count_7d': 0,
      'count_30d': 0,
      'amount_24h': 0.0,
      'amount_7d': 0.0,
      'amount_30d': 0.0,
      'avg_amount_24h': 0.0,
      'avg_amount_7d': 0.0,
      'velocity_per_hour_24h': 0.0,
      'velocity_per_hour_7d': 0.0,
      'growth_rate_7d': 0.0,
    };
  }

  Map<String, dynamic> _getEmptyCampaignAnalytics() {
    return {
      'total': 0,
      'recent_7d': 0,
      'emergency_active': 0,
      'completed': 0,
      'avg_completion_rate': 0.0,
      'status_distribution': <String, int>{},
      'type_distribution': <String, int>{},
      'success_rate': 0.0,
    };
  }

  Map<String, dynamic> _getEmptySystemAnalytics() {
    return {
      'response_time_ms': 0,
      'error_rate_percent': 0.0,
      'uptime_percent': 100.0,
      'active_connections': 0,
      'memory_usage_percent': 0,
      'cpu_usage_percent': 0,
      'database_connections': 0,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getEmptySurgeAnalytics() {
    return {
      'hourly_breakdown': <String, Map<String, int>>{},
      'avg_registrations_per_hour': 0.0,
      'avg_donations_per_hour': 0.0,
      'registration_surges': <String>[],
      'donation_surges': <String>[],
      'is_surge_detected': false,
      'surge_intensity': 0.0,
    };
  }

  /// Clear analytics cache to force refresh
  void clearCache() {
    _analyticsCache.clear();
    _lastCacheUpdate = null;
  }
}
