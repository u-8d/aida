import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/admin_user.dart';
import '../models/disaster_campaign.dart';
import '../services/admin_service.dart';

enum AdminAuthState {
  loggedOut,
  loggingIn,
  loggedIn,
  error,
}

class AdminAppState extends ChangeNotifier {
  AdminAuthState _authState = AdminAuthState.loggedOut;
  AdminUser? _currentAdmin;
  String? _errorMessage;
  
  // Dashboard data
  Map<String, dynamic> _analyticsData = {};
  List<DisasterCampaign> _disasterCampaigns = [];
  Map<String, dynamic> _userStats = {};
  
  // Loading states
  bool _isLoadingAnalytics = false;
  bool _isLoadingCampaigns = false;
  bool _isLoadingUserStats = false;

  // Getters
  AdminAuthState get authState => _authState;
  AdminUser? get currentAdmin => _currentAdmin;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get analyticsData => _analyticsData;
  List<DisasterCampaign> get disasterCampaigns => _disasterCampaigns;
  Map<String, dynamic> get userStats => _userStats;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isLoadingCampaigns => _isLoadingCampaigns;
  bool get isLoadingUserStats => _isLoadingUserStats;

  /// Authenticate admin user
  Future<bool> signInAdmin(String email, String password) async {
    _authState = AdminAuthState.loggingIn;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Attempting admin sign in for: $email');
      }

      final admin = await AdminService.authenticateAdmin(email, password);
      
      if (admin != null) {
        _currentAdmin = admin;
        _authState = AdminAuthState.loggedIn;
        
        if (kDebugMode) {
          print('Admin sign in successful: ${admin.roleDisplayName}');
        }

        // Load initial dashboard data
        await _loadInitialData();
        
        notifyListeners();
        return true;
      } else {
        _authState = AdminAuthState.error;
        _errorMessage = 'Invalid admin credentials or insufficient permissions';
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Admin sign in error: $e');
      }
      
      _authState = AdminAuthState.error;
      _errorMessage = 'Authentication failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Load initial dashboard data
  Future<void> _loadInitialData() async {
    await Future.wait([
      refreshAnalytics(),
      refreshDisasterCampaigns(),
      refreshUserStats(),
    ]);
  }

  /// Refresh analytics data
  Future<void> refreshAnalytics() async {
    if (_currentAdmin == null || !_currentAdmin!.canAccessAnalytics()) {
      return;
    }

    _isLoadingAnalytics = true;
    notifyListeners();

    try {
      _analyticsData = await AdminService.getRealtimeAnalytics();
      if (kDebugMode) {
        print('Analytics data refreshed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing analytics: $e');
      }
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  /// Refresh disaster campaigns
  Future<void> refreshDisasterCampaigns() async {
    if (_currentAdmin == null) return;

    _isLoadingCampaigns = true;
    notifyListeners();

    try {
      _disasterCampaigns = await AdminService.getDisasterCampaigns();
      if (kDebugMode) {
        print('Disaster campaigns refreshed: ${_disasterCampaigns.length} campaigns');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing disaster campaigns: $e');
      }
    } finally {
      _isLoadingCampaigns = false;
      notifyListeners();
    }
  }

  /// Refresh user statistics
  Future<void> refreshUserStats() async {
    if (_currentAdmin == null || !_currentAdmin!.canManageUsers()) {
      return;
    }

    _isLoadingUserStats = true;
    notifyListeners();

    try {
      _userStats = await AdminService.getUserManagementStats();
      if (kDebugMode) {
        print('User stats refreshed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing user stats: $e');
      }
    } finally {
      _isLoadingUserStats = false;
      notifyListeners();
    }
  }

  /// Toggle crisis mode
  Future<bool> toggleCrisisMode(bool isEnabled, CrisisLevel? level) async {
    if (_currentAdmin == null || !_currentAdmin!.canManageCrisis()) {
      return false;
    }

    try {
      final success = await AdminService.toggleCrisisMode(
        _currentAdmin!.id,
        isEnabled,
        level,
      );

      if (success) {
        // Update current admin state
        _currentAdmin = _currentAdmin!.copyWith(
          isCrisisMode: isEnabled,
          currentCrisisLevel: level,
          lastActiveSession: DateTime.now(),
        );
        
        if (kDebugMode) {
          print('Crisis mode toggled: $isEnabled');
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling crisis mode: $e');
      }
      return false;
    }
  }

  /// Create disaster campaign
  Future<DisasterCampaign?> createDisasterCampaign(DisasterCampaign campaign) async {
    if (_currentAdmin == null || !_currentAdmin!.canCreateDisasterCampaigns()) {
      return null;
    }

    try {
      final createdCampaign = await AdminService.createDisasterCampaign(
        campaign,
        _currentAdmin!.id,
      );

      if (createdCampaign != null) {
        _disasterCampaigns.insert(0, createdCampaign);
        
        if (kDebugMode) {
          print('Disaster campaign created: ${createdCampaign.title}');
        }
        
        notifyListeners();
        return createdCampaign;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating disaster campaign: $e');
      }
      return null;
    }
  }

  /// Update disaster campaign
  Future<bool> updateDisasterCampaign(DisasterCampaign campaign) async {
    if (_currentAdmin == null || !_currentAdmin!.canCreateDisasterCampaigns()) {
      return false;
    }

    try {
      final success = await AdminService.updateDisasterCampaign(
        campaign,
        _currentAdmin!.id,
      );

      if (success) {
        final index = _disasterCampaigns.indexWhere((c) => c.id == campaign.id);
        if (index != -1) {
          _disasterCampaigns[index] = campaign;
        }
        
        if (kDebugMode) {
          print('Disaster campaign updated: ${campaign.title}');
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating disaster campaign: $e');
      }
      return false;
    }
  }

  /// Get active disaster campaigns
  List<DisasterCampaign> get activeCampaigns {
    return _disasterCampaigns.where((campaign) =>
        campaign.status == CampaignStatus.active ||
        campaign.status == CampaignStatus.urgent
    ).toList();
  }

  /// Get urgent disaster campaigns
  List<DisasterCampaign> get urgentCampaigns {
    return _disasterCampaigns.where((campaign) =>
        campaign.status == CampaignStatus.urgent ||
        campaign.overallPriority == ResourcePriority.critical ||
        campaign.overallPriority == ResourcePriority.emergency
    ).toList();
  }

  /// Update admin session
  Future<void> updateSession() async {
    if (_currentAdmin == null) return;

    try {
      await AdminService.verifyAndUpdateSession(_currentAdmin!.id);
      
      _currentAdmin = _currentAdmin!.copyWith(
        lastActiveSession: DateTime.now(),
      );
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin session: $e');
      }
    }
  }

  /// Sign out admin
  Future<void> signOut() async {
    try {
      await AdminService.signOutAdmin();
      
      if (kDebugMode) {
        print('Admin signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during admin sign out: $e');
      }
    } finally {
      _authState = AdminAuthState.loggedOut;
      _currentAdmin = null;
      _errorMessage = null;
      _analyticsData = {};
      _disasterCampaigns = [];
      _userStats = {};
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    if (_authState == AdminAuthState.error) {
      _authState = AdminAuthState.loggedOut;
    }
    notifyListeners();
  }

  /// Check if current admin has specific permission
  bool hasPermission(AdminPermission permission) {
    return _currentAdmin?.hasPermission(permission) ?? false;
  }

  /// Get formatted analytics summary
  String get analyticsSummary {
    if (_analyticsData.isEmpty) return 'No data available';
    
    final userSurge = _analyticsData['user_surge'] as Map<String, dynamic>?;
    final donationVelocity = _analyticsData['donation_velocity'] as Map<String, dynamic>?;
    
    final activeUsers = userSurge?['current_active_users'] ?? 0;
    final donationsToday = donationVelocity?['total_today'] ?? 0;
    
    return '$activeUsers active users, $donationsToday donations today';
  }

  /// Get system health status
  String get systemHealthStatus {
    if (_analyticsData.isEmpty) return 'Unknown';
    
    final performance = _analyticsData['system_performance'] as Map<String, dynamic>?;
    final errorRate = (performance?['error_rate'] ?? 0.0) as double;
    final uptime = (performance?['uptime_percentage'] ?? 0.0) as double;
    
    if (errorRate > 5.0 || uptime < 95.0) {
      return 'Degraded';
    } else if (errorRate > 1.0 || uptime < 99.0) {
      return 'Warning';
    } else {
      return 'Healthy';
    }
  }
}
