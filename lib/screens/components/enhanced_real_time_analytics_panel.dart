import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/real_time_analytics_service.dart';
import '../../config/app_theme.dart';

class EnhancedRealTimeAnalyticsPanel extends StatefulWidget {
  const EnhancedRealTimeAnalyticsPanel({super.key});

  @override
  State<EnhancedRealTimeAnalyticsPanel> createState() => _EnhancedRealTimeAnalyticsPanelState();
}

class _EnhancedRealTimeAnalyticsPanelState extends State<EnhancedRealTimeAnalyticsPanel>
    with TickerProviderStateMixin {
  final _analyticsService = RealTimeAnalyticsService();
  late TabController _tabController;
  
  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _liveMetrics = {};
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  bool _isLiveUpdateActive = false;
  
  StreamSubscription<Map<String, dynamic>>? _liveMetricsSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
    _startLiveUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveMetricsSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final analytics = await _analyticsService.getPlatformAnalytics();
      setState(() {
        _analyticsData = analytics;
        _alerts = List<Map<String, dynamic>>.from(analytics['alerts'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startLiveUpdates() {
    _isLiveUpdateActive = true;
    
    // Start live metrics stream
    _liveMetricsSubscription = _analyticsService.getLiveMetrics().listen(
      (metrics) {
        if (mounted) {
          setState(() {
            _liveMetrics = metrics;
          });
        }
      },
      onError: (error) {
        print('Live metrics stream error: $error');
      },
    );

    // Refresh full analytics every 2 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _loadInitialData();
    });
  }

  void _stopLiveUpdates() {
    _isLiveUpdateActive = false;
    _liveMetricsSubscription?.cancel();
    _refreshTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading analytics...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildPerformanceTab(),
              _buildSurgeTab(),
              _buildAlertsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.analytics, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          const Text(
            'Real-Time Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isLiveUpdateActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isLiveUpdateActive ? 'Live' : 'Offline',
                style: TextStyle(
                  color: _isLiveUpdateActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle_live':
                  if (_isLiveUpdateActive) {
                    _stopLiveUpdates();
                  } else {
                    _startLiveUpdates();
                  }
                  break;
                case 'clear_cache':
                  _analyticsService.clearCache();
                  _loadInitialData();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_live',
                child: Row(
                  children: [
                    Icon(_isLiveUpdateActive ? Icons.pause : Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(_isLiveUpdateActive ? 'Pause Live Updates' : 'Resume Live Updates'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Cache'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryBlue,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primaryBlue,
      tabs: [
        Tab(
          icon: const Icon(Icons.dashboard),
          text: 'Overview',
          child: _alerts.isNotEmpty ? 
            Badge(
              label: Text(_alerts.length.toString()),
              child: const Column(
                children: [
                  Icon(Icons.dashboard),
                  Text('Overview'),
                ],
              ),
            ) : null,
        ),
        const Tab(icon: Icon(Icons.speed), text: 'Performance'),
        const Tab(icon: Icon(Icons.trending_up), text: 'Surge'),
        Tab(
          icon: const Icon(Icons.warning),
          text: 'Alerts',
          child: _alerts.isNotEmpty ? 
            Badge(
              label: Text(_alerts.length.toString()),
              backgroundColor: Colors.red,
              child: const Column(
                children: [
                  Icon(Icons.warning),
                  Text('Alerts'),
                ],
              ),
            ) : null,
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final users = _analyticsData['users'] ?? {};
    final donations = _analyticsData['donations'] ?? {};
    final campaigns = _analyticsData['campaigns'] ?? {};
    final system = _analyticsData['system'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Live metrics row
          Row(
            children: [
              Expanded(child: _buildLiveMetricCard(
                'Active Now',
                '${_liveMetrics['active_sessions'] ?? 0}',
                Icons.people,
                Colors.blue,
                '+${_liveMetrics['recent_registrations_5m'] ?? 0} in 5m',
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildLiveMetricCard(
                'Live Donations',
                '${_liveMetrics['recent_donations_5m'] ?? 0}',
                Icons.volunteer_activism,
                Colors.green,
                '₹${(_liveMetrics['recent_amount_5m'] ?? 0.0).toStringAsFixed(0)} in 5m',
              )),
            ],
          ),
          const SizedBox(height: 16),
          
          // Key metrics grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Total Users',
                '${users['total'] ?? 0}',
                '+${users['new_24h'] ?? 0} today',
                Icons.people,
                Colors.blue,
              ),
              _buildMetricCard(
                'Total Donations',
                '${donations['count_24h'] ?? 0}',
                '₹${(donations['amount_24h'] ?? 0.0).toStringAsFixed(0)} today',
                Icons.attach_money,
                Colors.green,
              ),
              _buildMetricCard(
                'Active Campaigns',
                '${campaigns['total'] ?? 0}',
                '${campaigns['emergency_active'] ?? 0} emergency',
                Icons.campaign,
                Colors.orange,
              ),
              _buildMetricCard(
                'System Health',
                '${(system['uptime_percent'] ?? 0.0).toStringAsFixed(1)}%',
                '${system['response_time_ms'] ?? 0}ms response',
                Icons.health_and_safety,
                _getHealthColor(system['uptime_percent'] ?? 0.0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Growth trends
          _buildGrowthTrendsCard(users, donations, campaigns),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final system = _analyticsData['system'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildPerformanceMetric(
                'Response Time',
                '${_liveMetrics['response_time'] ?? system['response_time_ms'] ?? 0} ms',
                _getPerformanceColor((_liveMetrics['response_time'] ?? system['response_time_ms'] ?? 0).toDouble(), 200, 500),
                Icons.speed,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildPerformanceMetric(
                'System Load',
                '${(_liveMetrics['system_load'] ?? system['cpu_usage_percent'] ?? 0).toStringAsFixed(1)}%',
                _getPerformanceColor((_liveMetrics['system_load'] ?? system['cpu_usage_percent'] ?? 0).toDouble(), 70, 90),
                Icons.memory,
              )),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildPerformanceMetric(
                'Error Rate',
                '${(system['error_rate_percent'] ?? 0.0).toStringAsFixed(2)}%',
                _getPerformanceColor((system['error_rate_percent'] ?? 0.0), 1, 3),
                Icons.error,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildPerformanceMetric(
                'DB Connections',
                '${system['database_connections'] ?? 0}',
                _getPerformanceColor((system['database_connections'] ?? 0).toDouble(), 50, 80),
                Icons.storage,
              )),
            ],
          ),
          const SizedBox(height: 20),
          
          // System status overview
          _buildSystemStatusCard(system),
        ],
      ),
    );
  }

  Widget _buildSurgeTab() {
    final surge = _analyticsData['surge'] ?? {};
    final hourlyData = surge['hourly_breakdown'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (surge['is_surge_detected'] == true) 
            _buildSurgeAlert(surge),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildSurgeMetric(
                'Registrations/Hour',
                '${(surge['avg_registrations_per_hour'] ?? 0.0).toStringAsFixed(1)}',
                'Average rate',
                Icons.person_add,
                Colors.blue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSurgeMetric(
                'Donations/Hour',
                '${(surge['avg_donations_per_hour'] ?? 0.0).toStringAsFixed(1)}',
                'Average rate',
                Icons.volunteer_activism,
                Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSurgeIntensityCard(surge),
          const SizedBox(height: 16),
          
          if (hourlyData.isNotEmpty)
            _buildHourlyActivityChart(hourlyData),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'System Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_alerts.length} Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _alerts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 48, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'All Systems Operational',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text('No alerts at this time'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthTrendsCard(Map<String, dynamic> users, Map<String, dynamic> donations, Map<String, dynamic> campaigns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Growth Trends (7 days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTrendItem(
                  'Users',
                  '${users['growth_rate_7d']?.toStringAsFixed(1) ?? '0.0'}%',
                  (users['growth_rate_7d'] ?? 0.0) >= 0,
                )),
                Expanded(child: _buildTrendItem(
                  'Donations',
                  '${donations['growth_rate_7d']?.toStringAsFixed(1) ?? '0.0'}%',
                  (donations['growth_rate_7d'] ?? 0.0) >= 0,
                )),
                Expanded(child: _buildTrendItem(
                  'Campaigns',
                  '${campaigns['recent_7d'] ?? 0}',
                  true,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, bool isPositive) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetric(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(Map<String, dynamic> system) {
    final uptime = system['uptime_percent'] ?? 100.0;
    final connections = system['active_connections'] ?? 0;
    final memory = system['memory_usage_percent'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Uptime', '${uptime.toStringAsFixed(2)}%', uptime >= 99.0),
            _buildStatusRow('Active Connections', '$connections', connections < 1000),
            _buildStatusRow('Memory Usage', '${memory}%', memory < 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            color: isGood ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGood ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeAlert(Map<String, dynamic> surge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity Surge Detected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Intensity: ${(surge['surge_intensity'] ?? 0.0).toStringAsFixed(1)}x normal',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeMetric(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeIntensityCard(Map<String, dynamic> surge) {
    final intensity = surge['surge_intensity'] ?? 0.0;
    final registrationSurges = List<String>.from(surge['registration_surges'] ?? []);
    final donationSurges = List<String>.from(surge['donation_surges'] ?? []);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Surge Analysis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Max Intensity: ${intensity.toStringAsFixed(1)}x'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSurgeIntensityColor(intensity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getSurgeIntensityLabel(intensity),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (registrationSurges.isNotEmpty || donationSurges.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (registrationSurges.isNotEmpty)
                Text('Registration surges: ${registrationSurges.join(", ")}'),
              if (donationSurges.isNotEmpty)
                Text('Donation surges: ${donationSurges.join(", ")}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyActivityChart(Map<String, Map<String, int>> hourlyData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '24-Hour Activity Pattern',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hourlyData.length,
                itemBuilder: (context, index) {
                  final hour = hourlyData.keys.elementAt(index);
                  final data = hourlyData[hour]!;
                  return _buildHourlyBar(hour, data['registrations']!, data['donations']!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyBar(String hour, int registrations, int donations) {
    final maxValue = 50; // Scale based on your data
    final regHeight = (registrations / maxValue * 60).clamp(0, 60).toDouble();
    final donHeight = (donations / maxValue * 60).clamp(0, 60).toDouble();
    
    return Container(
      width: 40,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 8,
                  height: regHeight,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 8,
                  height: donHeight,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${hour}h',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final title = alert['title'] as String;
    final message = alert['message'] as String;
    final timestamp = DateTime.parse(alert['timestamp'] as String);
    
    Color alertColor;
    IconData alertIcon;
    
    switch (severity) {
      case 'critical':
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case 'warning':
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(alertIcon, color: alertColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: alertColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            severity.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getHealthColor(double uptime) {
    if (uptime >= 99.5) return Colors.green;
    if (uptime >= 98.0) return Colors.orange;
    return Colors.red;
  }

  Color _getPerformanceColor(double value, double warningThreshold, double criticalThreshold) {
    if (value < warningThreshold) return Colors.green;
    if (value < criticalThreshold) return Colors.orange;
    return Colors.red;
  }

  Color _getSurgeIntensityColor(double intensity) {
    if (intensity < 1.5) return Colors.green;
    if (intensity < 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getSurgeIntensityLabel(double intensity) {
    if (intensity < 1.5) return 'NORMAL';
    if (intensity < 3.0) return 'MODERATE';
    return 'HIGH';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
