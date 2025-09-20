import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

enum CrisisLevel {
  none,
  low,
  medium,
  high,
  critical,
}

enum CrisisType {
  earthquake,
  flood,
  hurricane,
  wildfire,
  pandemic,
  cyberAttack,
  powerOutage,
  other,
}

enum AutomationLevel {
  manual,
  semiAuto,
  fullyAuto,
}

class CrisisModeService {
  final _supabase = Supabase.instance.client;
  
  // Crisis state management
  bool _isCrisisModeActive = false;
  CrisisLevel _currentCrisisLevel = CrisisLevel.none;
  CrisisType? _currentCrisisType;
  DateTime? _crisisStartTime;
  
  // Automation settings
  AutomationLevel _automationLevel = AutomationLevel.semiAuto;
  Map<String, dynamic> _automationRules = {};
  
  // Real-time monitoring
  Timer? _monitoringTimer;
  StreamController<Map<String, dynamic>>? _crisisStreamController;
  
  // Getters
  bool get isCrisisModeActive => _isCrisisModeActive;
  CrisisLevel get currentCrisisLevel => _currentCrisisLevel;
  CrisisType? get currentCrisisType => _currentCrisisType;
  DateTime? get crisisStartTime => _crisisStartTime;
  AutomationLevel get automationLevel => _automationLevel;
  
  Stream<Map<String, dynamic>> get crisisUpdates {
    _crisisStreamController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _crisisStreamController!.stream;
  }

  /// Initialize crisis mode service
  Future<void> initialize() async {
    try {
      // Load current crisis state from database
      await _loadCrisisState();
      
      // Start monitoring if crisis mode is active
      if (_isCrisisModeActive) {
        _startMonitoring();
      }
      
      print('Crisis mode service initialized');
    } catch (e) {
      print('Error initializing crisis mode service: $e');
    }
  }

  /// Activate crisis mode with specified level and type
  Future<bool> activateCrisisMode({
    required CrisisLevel level,
    required CrisisType type,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      
      // Update local state
      _isCrisisModeActive = true;
      _currentCrisisLevel = level;
      _currentCrisisType = type;
      _crisisStartTime = now;
      
      // Save crisis state to database
      await _supabase.from('crisis_events').insert({
        'crisis_type': type.name,
        'crisis_level': level.name,
        'description': description,
        'metadata': metadata,
        'started_at': now.toIso8601String(),
        'is_active': true,
        'activated_by': _supabase.auth.currentUser?.id,
      });
      
      // Update system configuration
      await _updateSystemConfiguration();
      
      // Start monitoring and automation
      _startMonitoring();
      
      // Trigger immediate surge response
      await _triggerSurgeResponse();
      
      // Log the activation
      await _logCrisisAction('crisis_activated', {
        'level': level.name,
        'type': type.name,
        'description': description,
      });
      
      // Broadcast crisis activation
      _broadcastCrisisUpdate('activated', {
        'level': level.name,
        'type': type.name,
        'startTime': now.toIso8601String(),
      });
      
      print('Crisis mode activated: ${level.name} ${type.name}');
      return true;
    } catch (e) {
      print('Error activating crisis mode: $e');
      return false;
    }
  }

  /// Deactivate crisis mode
  Future<bool> deactivateCrisisMode({
    String? reason,
    Map<String, dynamic>? summary,
  }) async {
    try {
      final now = DateTime.now();
      
      // Update database
      await _supabase.from('crisis_events')
          .update({
            'ended_at': now.toIso8601String(),
            'is_active': false,
            'deactivation_reason': reason,
            'summary': summary,
          })
          .eq('is_active', true);
      
      // Reset local state
      final previousLevel = _currentCrisisLevel;
      final previousType = _currentCrisisType;
      
      _isCrisisModeActive = false;
      _currentCrisisLevel = CrisisLevel.none;
      _currentCrisisType = null;
      _crisisStartTime = null;
      
      // Stop monitoring
      _stopMonitoring();
      
      // Reset system configuration
      await _resetSystemConfiguration();
      
      // Log the deactivation
      await _logCrisisAction('crisis_deactivated', {
        'previous_level': previousLevel.name,
        'previous_type': previousType?.name,
        'reason': reason,
        'duration_minutes': _crisisStartTime != null 
          ? now.difference(_crisisStartTime!).inMinutes 
          : 0,
      });
      
      // Broadcast crisis deactivation
      _broadcastCrisisUpdate('deactivated', {
        'endTime': now.toIso8601String(),
        'reason': reason,
      });
      
      print('Crisis mode deactivated');
      return true;
    } catch (e) {
      print('Error deactivating crisis mode: $e');
      return false;
    }
  }

  /// Update crisis level during active crisis
  Future<bool> updateCrisisLevel(CrisisLevel newLevel, {String? reason}) async {
    if (!_isCrisisModeActive) return false;
    
    try {
      final previousLevel = _currentCrisisLevel;
      _currentCrisisLevel = newLevel;
      
      // Update database
      await _supabase.from('crisis_events')
          .update({
            'crisis_level': newLevel.name,
            'level_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('is_active', true);
      
      // Update system configuration based on new level
      await _updateSystemConfiguration();
      
      // Log the update
      await _logCrisisAction('crisis_level_updated', {
        'previous_level': previousLevel.name,
        'new_level': newLevel.name,
        'reason': reason,
      });
      
      // Broadcast level change
      _broadcastCrisisUpdate('level_updated', {
        'previousLevel': previousLevel.name,
        'newLevel': newLevel.name,
        'reason': reason,
      });
      
      return true;
    } catch (e) {
      print('Error updating crisis level: $e');
      return false;
    }
  }

  /// Get current crisis status and metrics
  Future<Map<String, dynamic>> getCrisisStatus() async {
    try {
      if (!_isCrisisModeActive) {
        return {
          'is_active': false,
          'level': 'none',
          'uptime_minutes': 0,
        };
      }
      
      final now = DateTime.now();
      final uptimeMinutes = _crisisStartTime != null 
        ? now.difference(_crisisStartTime!).inMinutes 
        : 0;
      
      // Get real-time metrics
      final metrics = await _getCrisisMetrics();
      
      return {
        'is_active': true,
        'level': _currentCrisisLevel.name,
        'type': _currentCrisisType?.name,
        'started_at': _crisisStartTime?.toIso8601String(),
        'uptime_minutes': uptimeMinutes,
        'automation_level': _automationLevel.name,
        'metrics': metrics,
        'active_automations': _getActiveAutomations(),
      };
    } catch (e) {
      print('Error getting crisis status: $e');
      return {'error': 'Failed to get crisis status'};
    }
  }

  /// Configure automation settings
  Future<bool> configureAutomation({
    required AutomationLevel level,
    Map<String, dynamic>? rules,
  }) async {
    try {
      _automationLevel = level;
      if (rules != null) {
        _automationRules = rules;
      }
      
      // Save to database
      await _supabase.from('crisis_automation_config').upsert({
        'automation_level': level.name,
        'rules': _automationRules,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Apply automation changes if crisis is active
      if (_isCrisisModeActive) {
        await _applyAutomationRules();
      }
      
      return true;
    } catch (e) {
      print('Error configuring automation: $e');
      return false;
    }
  }

  /// Get surge capacity recommendations
  Future<Map<String, dynamic>> getSurgeCapacityRecommendations() async {
    try {
      final metrics = await _getCrisisMetrics();
      
      // Calculate surge requirements based on current load
      final userSurge = metrics['user_registration_rate'] as double? ?? 0.0;
      final donationSurge = metrics['donation_rate'] as double? ?? 0.0;
      final requestSurge = metrics['help_request_rate'] as double? ?? 0.0;
      
      // Determine capacity recommendations
      final recommendations = <String, dynamic>{};
      
      if (userSurge > 100) { // More than 100 users per hour
        recommendations['user_management'] = {
          'action': 'scale_up',
          'recommended_capacity': '2x',
          'reason': 'High user registration rate',
        };
      }
      
      if (donationSurge > 50) { // More than 50 donations per hour
        recommendations['payment_processing'] = {
          'action': 'scale_up',
          'recommended_capacity': '3x',
          'reason': 'High donation volume',
        };
      }
      
      if (requestSurge > 75) { // More than 75 requests per hour
        recommendations['support_team'] = {
          'action': 'scale_up',
          'recommended_capacity': '4x',
          'reason': 'High help request volume',
        };
      }
      
      // Infrastructure recommendations
      if (_currentCrisisLevel == CrisisLevel.critical) {
        recommendations['database'] = {
          'action': 'enable_read_replicas',
          'reason': 'Critical crisis level requires maximum availability',
        };
        
        recommendations['cdn'] = {
          'action': 'activate_edge_caching',
          'reason': 'Distribute load during critical crisis',
        };
      }
      
      return {
        'surge_metrics': metrics,
        'recommendations': recommendations,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting surge capacity recommendations: $e');
      return {'error': 'Failed to get recommendations'};
    }
  }

  /// Execute emergency procedures
  Future<Map<String, dynamic>> executeEmergencyProcedures() async {
    try {
      final results = <String, dynamic>{};
      
      // 1. Activate emergency resource pools
      results['resource_pools'] = await _activateEmergencyResourcePools();
      
      // 2. Enable auto-matching for urgent requests
      results['auto_matching'] = await _enableUrgentAutoMatching();
      
      // 3. Scale up critical services
      results['service_scaling'] = await _scaleUpCriticalServices();
      
      // 4. Activate emergency communication channels
      results['communication'] = await _activateEmergencyChannels();
      
      // 5. Deploy emergency workflows
      results['workflows'] = await _deployEmergencyWorkflows();
      
      return {
        'success': true,
        'procedures_executed': results,
        'executed_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error executing emergency procedures: $e');
      return {
        'success': false,
        'error': 'Failed to execute emergency procedures: $e',
      };
    }
  }

  /// Get crisis timeline and events
  Future<List<Map<String, dynamic>>> getCrisisTimeline({int limit = 50}) async {
    try {
      final timeline = await _supabase
          .from('crisis_timeline')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(timeline);
    } catch (e) {
      print('Error getting crisis timeline: $e');
      return [];
    }
  }

  // Private helper methods
  Future<void> _loadCrisisState() async {
    try {
      final activeCrisis = await _supabase
          .from('crisis_events')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();
      
      if (activeCrisis != null) {
        _isCrisisModeActive = true;
        _currentCrisisLevel = CrisisLevel.values.firstWhere(
          (level) => level.name == activeCrisis['crisis_level'],
          orElse: () => CrisisLevel.medium,
        );
        _currentCrisisType = CrisisType.values.firstWhere(
          (type) => type.name == activeCrisis['crisis_type'],
          orElse: () => CrisisType.other,
        );
        _crisisStartTime = DateTime.parse(activeCrisis['started_at']);
      }
    } catch (e) {
      print('Error loading crisis state: $e');
    }
  }

  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performMonitoringCheck();
    });
  }

  void _stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  Future<void> _performMonitoringCheck() async {
    try {
      // Check system metrics
      final metrics = await _getCrisisMetrics();
      
      // Auto-escalate if needed
      if (_automationLevel != AutomationLevel.manual) {
        await _checkAutoEscalation(metrics);
      }
      
      // Apply automation rules
      await _applyAutomationRules();
      
      // Broadcast monitoring update
      _broadcastCrisisUpdate('monitoring_update', {
        'metrics': metrics,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error in monitoring check: $e');
    }
  }

  Future<Map<String, dynamic>> _getCrisisMetrics() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      // Get user registration rate
      final newUsers = await _supabase
          .from('users')
          .select('id')
          .gte('created_at', oneHourAgo.toIso8601String());
      
      // Get donation rate
      final newDonations = await _supabase
          .from('donations')
          .select('id')
          .gte('created_at', oneHourAgo.toIso8601String());
      
      // Get help request rate
      final newRequests = await _supabase
          .from('donation_requests')
          .select('id')
          .gte('created_at', oneHourAgo.toIso8601String());
      
      // Calculate system load (simplified)
      final systemLoad = (newUsers.length + newDonations.length + newRequests.length) / 3.0;
      
      return {
        'user_registration_rate': newUsers.length.toDouble(),
        'donation_rate': newDonations.length.toDouble(),
        'help_request_rate': newRequests.length.toDouble(),
        'system_load': systemLoad,
        'load_level': _categorizeLoad(systemLoad),
        'collected_at': now.toIso8601String(),
      };
    } catch (e) {
      print('Error getting crisis metrics: $e');
      return {
        'user_registration_rate': 0.0,
        'donation_rate': 0.0,
        'help_request_rate': 0.0,
        'system_load': 0.0,
        'load_level': 'normal',
        'error': 'Failed to collect metrics',
      };
    }
  }

  String _categorizeLoad(double load) {
    if (load > 200) return 'critical';
    if (load > 100) return 'high';
    if (load > 50) return 'medium';
    if (load > 20) return 'elevated';
    return 'normal';
  }

  Future<void> _checkAutoEscalation(Map<String, dynamic> metrics) async {
    final systemLoad = metrics['system_load'] as double? ?? 0.0;
    
    // Auto-escalation rules
    if (systemLoad > 200 && _currentCrisisLevel != CrisisLevel.critical) {
      await updateCrisisLevel(CrisisLevel.critical, reason: 'Auto-escalated due to critical system load');
    } else if (systemLoad > 100 && _currentCrisisLevel == CrisisLevel.low) {
      await updateCrisisLevel(CrisisLevel.high, reason: 'Auto-escalated due to high system load');
    } else if (systemLoad > 50 && _currentCrisisLevel == CrisisLevel.low) {
      await updateCrisisLevel(CrisisLevel.medium, reason: 'Auto-escalated due to elevated system load');
    }
  }

  Future<void> _updateSystemConfiguration() async {
    try {
      final config = _getConfigurationForLevel(_currentCrisisLevel);
      
      // Update system settings in database
      await _supabase.from('system_configuration').upsert({
        'crisis_mode_active': _isCrisisModeActive,
        'crisis_level': _currentCrisisLevel.name,
        'configuration': config,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('System configuration updated for crisis level: ${_currentCrisisLevel.name}');
    } catch (e) {
      print('Error updating system configuration: $e');
    }
  }

  Map<String, dynamic> _getConfigurationForLevel(CrisisLevel level) {
    switch (level) {
      case CrisisLevel.critical:
        return {
          'auto_verify_users': true,
          'auto_match_urgent_requests': true,
          'priority_processing': true,
          'emergency_contacts_enabled': true,
          'rate_limit_relaxed': true,
          'cache_ttl_reduced': true,
        };
      case CrisisLevel.high:
        return {
          'auto_verify_users': true,
          'auto_match_urgent_requests': true,
          'priority_processing': true,
          'emergency_contacts_enabled': false,
          'rate_limit_relaxed': false,
          'cache_ttl_reduced': true,
        };
      case CrisisLevel.medium:
        return {
          'auto_verify_users': false,
          'auto_match_urgent_requests': true,
          'priority_processing': false,
          'emergency_contacts_enabled': false,
          'rate_limit_relaxed': false,
          'cache_ttl_reduced': false,
        };
      case CrisisLevel.low:
        return {
          'auto_verify_users': false,
          'auto_match_urgent_requests': false,
          'priority_processing': false,
          'emergency_contacts_enabled': false,
          'rate_limit_relaxed': false,
          'cache_ttl_reduced': false,
        };
      case CrisisLevel.none:
        return {
          'auto_verify_users': false,
          'auto_match_urgent_requests': false,
          'priority_processing': false,
          'emergency_contacts_enabled': false,
          'rate_limit_relaxed': false,
          'cache_ttl_reduced': false,
        };
    }
  }

  Future<void> _resetSystemConfiguration() async {
    await _updateSystemConfiguration();
  }

  Future<void> _triggerSurgeResponse() async {
    try {
      // Enable surge handling features
      await _supabase.from('surge_response_log').insert({
        'event_type': 'surge_response_activated',
        'crisis_level': _currentCrisisLevel.name,
        'triggered_at': DateTime.now().toIso8601String(),
      });
      
      print('Surge response triggered');
    } catch (e) {
      print('Error triggering surge response: $e');
    }
  }

  Future<void> _applyAutomationRules() async {
    if (_automationLevel == AutomationLevel.manual) return;
    
    try {
      // Apply configured automation rules
      for (final rule in _automationRules.entries) {
        await _executeAutomationRule(rule.key, rule.value);
      }
    } catch (e) {
      print('Error applying automation rules: $e');
    }
  }

  Future<void> _executeAutomationRule(String ruleName, dynamic ruleConfig) async {
    // Implementation would depend on specific rule types
    print('Executing automation rule: $ruleName');
  }

  List<String> _getActiveAutomations() {
    final automations = <String>[];
    
    if (_isCrisisModeActive) {
      automations.add('Crisis monitoring');
      
      if (_automationLevel != AutomationLevel.manual) {
        automations.add('Auto-escalation');
      }
      
      if (_currentCrisisLevel == CrisisLevel.critical || _currentCrisisLevel == CrisisLevel.high) {
        automations.add('Priority processing');
        automations.add('Emergency resource allocation');
      }
    }
    
    return automations;
  }

  Future<Map<String, dynamic>> _activateEmergencyResourcePools() async {
    // Implementation for emergency resource pool activation
    return {'status': 'activated', 'pools': ['volunteer', 'financial', 'supplies']};
  }

  Future<Map<String, dynamic>> _enableUrgentAutoMatching() async {
    // Implementation for urgent request auto-matching
    return {'status': 'enabled', 'threshold': 'urgent_priority'};
  }

  Future<Map<String, dynamic>> _scaleUpCriticalServices() async {
    // Implementation for service scaling
    return {'status': 'scaled', 'services': ['database', 'api', 'notifications']};
  }

  Future<Map<String, dynamic>> _activateEmergencyChannels() async {
    // Implementation for emergency communication activation
    return {'status': 'activated', 'channels': ['sms', 'email', 'push']};
  }

  Future<Map<String, dynamic>> _deployEmergencyWorkflows() async {
    // Implementation for emergency workflow deployment
    return {'status': 'deployed', 'workflows': ['rapid_response', 'resource_allocation']};
  }

  Future<void> _logCrisisAction(String action, Map<String, dynamic> details) async {
    try {
      await _supabase.from('crisis_timeline').insert({
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
        'admin_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      print('Error logging crisis action: $e');
    }
  }

  void _broadcastCrisisUpdate(String eventType, Map<String, dynamic> data) {
    if (_crisisStreamController != null && !_crisisStreamController!.isClosed) {
      _crisisStreamController!.add({
        'event_type': eventType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Dispose resources
  void dispose() {
    _stopMonitoring();
    _crisisStreamController?.close();
    _crisisStreamController = null;
  }
}
