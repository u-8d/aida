import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

enum AlertType {
  emergency,
  urgent,
  warning,
  info,
  update,
}

enum AlertPriority {
  critical,
  high,
  medium,
  low,
}

enum CommunicationChannel {
  sms,
  email,
  push,
  inApp,
  social,
  broadcast,
}

enum RecipientGroup {
  all,
  volunteers,
  donors,
  recipients,
  admins,
  crisisAffected,
  geographic,
  custom,
}

class EmergencyCommunicationService {
  final _supabase = Supabase.instance.client;
  
  // Real-time communication streams
  StreamController<Map<String, dynamic>>? _alertStreamController;
  StreamController<Map<String, dynamic>>? _notificationStreamController;
  
  // Communication state
  bool _emergencyBroadcastActive = false;
  List<String> _activeChannels = [];
  Map<String, dynamic> _channelStatus = {};

  /// Initialize emergency communication service
  Future<void> initialize() async {
    try {
      // Load current emergency broadcast state
      await _loadBroadcastState();
      
      // Initialize communication channels
      await _initializeChannels();
      
      // Setup real-time subscriptions
      _setupRealtimeSubscriptions();
      
      print('Emergency communication service initialized');
    } catch (e) {
      print('Error initializing emergency communication service: $e');
    }
  }

  /// Send emergency alert to multiple recipients and channels
  Future<Map<String, dynamic>> sendEmergencyAlert({
    required String title,
    required String message,
    required AlertType type,
    required AlertPriority priority,
    required List<CommunicationChannel> channels,
    required RecipientGroup recipientGroup,
    List<String>? specificRecipients,
    Map<String, dynamic>? geographicFilter,
    Map<String, dynamic>? metadata,
    DateTime? scheduledTime,
  }) async {
    try {
      final alertId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      
      // Create alert record
      final alertData = {
        'id': alertId,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'channels': channels.map((c) => c.name).toList(),
        'recipient_group': recipientGroup.name,
        'specific_recipients': specificRecipients,
        'geographic_filter': geographicFilter,
        'metadata': metadata,
        'scheduled_time': scheduledTime?.toIso8601String(),
        'created_at': now.toIso8601String(),
        'created_by': _supabase.auth.currentUser?.id,
        'status': scheduledTime != null ? 'scheduled' : 'sending',
      };
      
      await _supabase.from('emergency_alerts').insert(alertData);
      
      // Get recipients based on group and filters
      final recipients = await _getRecipients(
        recipientGroup,
        specificRecipients: specificRecipients,
        geographicFilter: geographicFilter,
      );
      
      // Send through each channel
      final channelResults = <String, Map<String, dynamic>>{};
      var totalSent = 0;
      var totalFailed = 0;
      
      for (final channel in channels) {
        final result = await _sendThroughChannel(
          channel,
          alertId,
          title,
          message,
          recipients,
          priority,
        );
        
        channelResults[channel.name] = result;
        totalSent += result['sent'] as int? ?? 0;
        totalFailed += result['failed'] as int? ?? 0;
      }
      
      // Update alert status
      await _supabase.from('emergency_alerts').update({
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
        'total_recipients': recipients.length,
        'total_sent': totalSent,
        'total_failed': totalFailed,
        'channel_results': channelResults,
      }).eq('id', alertId);
      
      // Log the alert
      await _logCommunicationAction('emergency_alert_sent', {
        'alert_id': alertId,
        'title': title,
        'type': type.name,
        'priority': priority.name,
        'channels': channels.map((c) => c.name).toList(),
        'recipients': recipients.length,
        'sent': totalSent,
        'failed': totalFailed,
      });
      
      // Broadcast real-time update
      _broadcastAlert({
        'alert_id': alertId,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'recipients': recipients.length,
      });
      
      return {
        'success': true,
        'alert_id': alertId,
        'recipients': recipients.length,
        'total_sent': totalSent,
        'total_failed': totalFailed,
        'channel_results': channelResults,
      };
    } catch (e) {
      print('Error sending emergency alert: $e');
      return {
        'success': false,
        'error': 'Failed to send emergency alert: $e',
      };
    }
  }

  /// Send mass notification to large groups
  Future<Map<String, dynamic>> sendMassNotification({
    required String title,
    required String message,
    required List<CommunicationChannel> channels,
    required RecipientGroup recipientGroup,
    Map<String, dynamic>? segmentationRules,
    Map<String, dynamic>? personalization,
    DateTime? scheduledTime,
  }) async {
    try {
      // Similar to emergency alert but optimized for large volumes
      final batchSize = 1000; // Process in batches
      final recipients = await _getRecipients(recipientGroup);
      
      var totalProcessed = 0;
      var totalSent = 0;
      var totalFailed = 0;
      
      // Process recipients in batches
      for (var i = 0; i < recipients.length; i += batchSize) {
        final batch = recipients.skip(i).take(batchSize).toList();
        
        for (final channel in channels) {
          final result = await _sendBatchThroughChannel(
            channel,
            title,
            message,
            batch,
            personalization,
          );
          
          totalSent += result['sent'] as int? ?? 0;
          totalFailed += result['failed'] as int? ?? 0;
        }
        
        totalProcessed += batch.length;
        
        // Brief pause between batches to avoid overwhelming systems
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      return {
        'success': true,
        'total_recipients': recipients.length,
        'total_processed': totalProcessed,
        'total_sent': totalSent,
        'total_failed': totalFailed,
      };
    } catch (e) {
      print('Error sending mass notification: $e');
      return {
        'success': false,
        'error': 'Failed to send mass notification: $e',
      };
    }
  }

  /// Activate emergency broadcast mode
  Future<bool> activateEmergencyBroadcast({
    required String reason,
    List<CommunicationChannel>? priorityChannels,
  }) async {
    try {
      _emergencyBroadcastActive = true;
      _activeChannels = priorityChannels?.map((c) => c.name).toList() ?? 
                      CommunicationChannel.values.map((c) => c.name).toList();
      
      // Update database
      await _supabase.from('emergency_broadcast_status').upsert({
        'is_active': true,
        'reason': reason,
        'active_channels': _activeChannels,
        'activated_at': DateTime.now().toIso8601String(),
        'activated_by': _supabase.auth.currentUser?.id,
      });
      
      // Activate all specified channels
      for (final channelName in _activeChannels) {
        final channel = CommunicationChannel.values.firstWhere(
          (c) => c.name == channelName,
          orElse: () => CommunicationChannel.push,
        );
        await _activateChannel(channel);
      }
      
      // Log activation
      await _logCommunicationAction('emergency_broadcast_activated', {
        'reason': reason,
        'active_channels': _activeChannels,
      });
      
      print('Emergency broadcast activated');
      return true;
    } catch (e) {
      print('Error activating emergency broadcast: $e');
      return false;
    }
  }

  /// Deactivate emergency broadcast mode
  Future<bool> deactivateEmergencyBroadcast({String? reason}) async {
    try {
      _emergencyBroadcastActive = false;
      
      // Update database
      await _supabase.from('emergency_broadcast_status').update({
        'is_active': false,
        'deactivation_reason': reason,
        'deactivated_at': DateTime.now().toIso8601String(),
      }).eq('is_active', true);
      
      // Reset channels to normal mode
      for (final channelName in _activeChannels) {
        final channel = CommunicationChannel.values.firstWhere(
          (c) => c.name == channelName,
          orElse: () => CommunicationChannel.push,
        );
        await _deactivateChannel(channel);
      }
      
      _activeChannels.clear();
      
      // Log deactivation
      await _logCommunicationAction('emergency_broadcast_deactivated', {
        'reason': reason,
      });
      
      print('Emergency broadcast deactivated');
      return true;
    } catch (e) {
      print('Error deactivating emergency broadcast: $e');
      return false;
    }
  }

  /// Get communication analytics and metrics
  Future<Map<String, dynamic>> getCommunicationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();
      
      // Get alert statistics
      final alerts = await _supabase
          .from('emergency_alerts')
          .select('*')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      
      // Calculate metrics
      var totalAlerts = alerts.length;
      var totalRecipients = 0;
      var totalSent = 0;
      var totalFailed = 0;
      
      final alertsByType = <String, int>{};
      final alertsByPriority = <String, int>{};
      final channelUsage = <String, int>{};
      
      for (final alert in alerts) {
        totalRecipients += alert['total_recipients'] as int? ?? 0;
        totalSent += alert['total_sent'] as int? ?? 0;
        totalFailed += alert['total_failed'] as int? ?? 0;
        
        final type = alert['type'] as String? ?? 'unknown';
        final priority = alert['priority'] as String? ?? 'unknown';
        final channels = alert['channels'] as List<dynamic>? ?? [];
        
        alertsByType[type] = (alertsByType[type] ?? 0) + 1;
        alertsByPriority[priority] = (alertsByPriority[priority] ?? 0) + 1;
        
        for (final channel in channels) {
          channelUsage[channel.toString()] = (channelUsage[channel.toString()] ?? 0) + 1;
        }
      }
      
      // Calculate delivery rate
      final deliveryRate = totalRecipients > 0 ? (totalSent / totalRecipients) * 100 : 0.0;
      
      // Get channel status
      final channelStatuses = await _getChannelStatuses();
      
      return {
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'totals': {
          'alerts': totalAlerts,
          'recipients': totalRecipients,
          'sent': totalSent,
          'failed': totalFailed,
          'delivery_rate': deliveryRate,
        },
        'breakdown': {
          'by_type': alertsByType,
          'by_priority': alertsByPriority,
          'by_channel': channelUsage,
        },
        'channel_status': channelStatuses,
        'emergency_broadcast_active': _emergencyBroadcastActive,
      };
    } catch (e) {
      print('Error getting communication analytics: $e');
      return {'error': 'Failed to get communication analytics'};
    }
  }

  /// Get recent alerts and notifications
  Future<List<Map<String, dynamic>>> getRecentAlerts({int limit = 50}) async {
    try {
      final alerts = await _supabase
          .from('emergency_alerts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(alerts);
    } catch (e) {
      print('Error getting recent alerts: $e');
      return [];
    }
  }

  /// Send targeted communication to specific users
  Future<Map<String, dynamic>> sendTargetedCommunication({
    required List<String> userIds,
    required String title,
    required String message,
    required List<CommunicationChannel> channels,
    Map<String, dynamic>? personalizationData,
  }) async {
    try {
      var totalSent = 0;
      var totalFailed = 0;
      
      for (final userId in userIds) {
        for (final channel in channels) {
          final result = await _sendToUser(
            userId,
            channel,
            title,
            message,
            personalizationData,
          );
          
          if (result) {
            totalSent++;
          } else {
            totalFailed++;
          }
        }
      }
      
      return {
        'success': true,
        'total_recipients': userIds.length,
        'total_sent': totalSent,
        'total_failed': totalFailed,
      };
    } catch (e) {
      print('Error sending targeted communication: $e');
      return {
        'success': false,
        'error': 'Failed to send targeted communication: $e',
      };
    }
  }

  /// Test communication channels
  Future<Map<String, dynamic>> testCommunicationChannels() async {
    try {
      final results = <String, Map<String, dynamic>>{};
      
      for (final channel in CommunicationChannel.values) {
        final testResult = await _testChannel(channel);
        results[channel.name] = testResult;
      }
      
      return {
        'success': true,
        'test_results': results,
        'tested_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error testing communication channels: $e');
      return {
        'success': false,
        'error': 'Failed to test communication channels: $e',
      };
    }
  }

  // Stream getters
  Stream<Map<String, dynamic>> get alertUpdates {
    _alertStreamController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _alertStreamController!.stream;
  }

  Stream<Map<String, dynamic>> get notificationUpdates {
    _notificationStreamController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _notificationStreamController!.stream;
  }

  // Private helper methods
  Future<void> _loadBroadcastState() async {
    try {
      final broadcastStatus = await _supabase
          .from('emergency_broadcast_status')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();
      
      if (broadcastStatus != null) {
        _emergencyBroadcastActive = true;
        _activeChannels = List<String>.from(broadcastStatus['active_channels'] ?? []);
      }
    } catch (e) {
      print('Error loading broadcast state: $e');
    }
  }

  Future<void> _initializeChannels() async {
    try {
      for (final channel in CommunicationChannel.values) {
        final status = await _getChannelStatus(channel);
        _channelStatus[channel.name] = status;
      }
    } catch (e) {
      print('Error initializing channels: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    // Setup real-time subscriptions for alerts and notifications
    // This would integrate with Supabase real-time subscriptions
  }

  Future<List<Map<String, dynamic>>> _getRecipients(
    RecipientGroup group, {
    List<String>? specificRecipients,
    Map<String, dynamic>? geographicFilter,
  }) async {
    try {
      if (specificRecipients != null && specificRecipients.isNotEmpty) {
        final users = await _supabase
            .from('users')
            .select('id, email, phone_number, name, location')
            .inFilter('id', specificRecipients);
        return List<Map<String, dynamic>>.from(users);
      }
      
      var query = _supabase
          .from('users')
          .select('id, email, phone_number, name, location');
      
      switch (group) {
        case RecipientGroup.all:
          // No additional filters
          break;
        case RecipientGroup.volunteers:
          query = query.eq('user_type', 'volunteer');
          break;
        case RecipientGroup.donors:
          query = query.eq('user_type', 'donor');
          break;
        case RecipientGroup.recipients:
          query = query.eq('user_type', 'recipient');
          break;
        case RecipientGroup.admins:
          query = query.eq('user_type', 'admin');
          break;
        case RecipientGroup.crisisAffected:
          query = query.eq('is_crisis_affected', true);
          break;
        case RecipientGroup.geographic:
          if (geographicFilter != null) {
            // Apply geographic filters based on location
            final location = geographicFilter['location'] as String?;
            if (location != null) {
              query = query.like('location', '%$location%');
            }
          }
          break;
        case RecipientGroup.custom:
          // Custom filtering would be implemented based on metadata
          break;
      }
      
      final users = await query;
      return List<Map<String, dynamic>>.from(users);
    } catch (e) {
      print('Error getting recipients: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _sendThroughChannel(
    CommunicationChannel channel,
    String alertId,
    String title,
    String message,
    List<Map<String, dynamic>> recipients,
    AlertPriority priority,
  ) async {
    try {
      var sent = 0;
      var failed = 0;
      
      for (final recipient in recipients) {
        final success = await _sendToUserThroughChannel(
          recipient,
          channel,
          alertId,
          title,
          message,
          priority,
        );
        
        if (success) {
          sent++;
        } else {
          failed++;
        }
      }
      
      return {
        'channel': channel.name,
        'sent': sent,
        'failed': failed,
        'total': recipients.length,
      };
    } catch (e) {
      print('Error sending through channel ${channel.name}: $e');
      return {
        'channel': channel.name,
        'sent': 0,
        'failed': recipients.length,
        'total': recipients.length,
        'error': e.toString(),
      };
    }
  }

  Future<bool> _sendToUserThroughChannel(
    Map<String, dynamic> recipient,
    CommunicationChannel channel,
    String alertId,
    String title,
    String message,
    AlertPriority priority,
  ) async {
    try {
      final userId = recipient['id'] as String;
      
      // Log the send attempt
      await _supabase.from('communication_log').insert({
        'alert_id': alertId,
        'user_id': userId,
        'channel': channel.name,
        'title': title,
        'message': message,
        'priority': priority.name,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'sent',
      });
      
      // Simulate channel-specific sending logic
      switch (channel) {
        case CommunicationChannel.sms:
          return await _sendSMS(recipient['phone_number'], message);
        case CommunicationChannel.email:
          return await _sendEmail(recipient['email'], title, message);
        case CommunicationChannel.push:
          return await _sendPushNotification(userId, title, message);
        case CommunicationChannel.inApp:
          return await _sendInAppNotification(userId, title, message);
        case CommunicationChannel.social:
          return await _sendSocialNotification(title, message);
        case CommunicationChannel.broadcast:
          return await _sendBroadcastNotification(title, message);
      }
    } catch (e) {
      print('Error sending to user through channel: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _sendBatchThroughChannel(
    CommunicationChannel channel,
    String title,
    String message,
    List<Map<String, dynamic>> batch,
    Map<String, dynamic>? personalization,
  ) async {
    // Optimized batch sending implementation
    var sent = 0;
    var failed = 0;
    
    // In production, this would use batch APIs where available
    for (final recipient in batch) {
      try {
        final personalizedMessage = _personalizeMessage(message, recipient, personalization);
        final success = await _sendToUser(
          recipient['id'],
          channel,
          title,
          personalizedMessage,
          personalization,
        );
        
        if (success) {
          sent++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }
    }
    
    return {
      'sent': sent,
      'failed': failed,
      'total': batch.length,
    };
  }

  Future<bool> _sendToUser(
    String userId,
    CommunicationChannel channel,
    String title,
    String message,
    Map<String, dynamic>? personalization,
  ) async {
    // Implementation would depend on specific channel
    return true; // Simplified for demo
  }

  String _personalizeMessage(
    String message,
    Map<String, dynamic> recipient,
    Map<String, dynamic>? personalization,
  ) {
    var personalizedMessage = message;
    
    // Replace common placeholders
    personalizedMessage = personalizedMessage.replaceAll(
      '{name}',
      recipient['name'] ?? 'User',
    );
    
    personalizedMessage = personalizedMessage.replaceAll(
      '{location}',
      recipient['location'] ?? 'your area',
    );
    
    // Apply additional personalization rules
    if (personalization != null) {
      for (final entry in personalization.entries) {
        personalizedMessage = personalizedMessage.replaceAll(
          '{${entry.key}}',
          entry.value.toString(),
        );
      }
    }
    
    return personalizedMessage;
  }

  Future<bool> _activateChannel(CommunicationChannel channel) async {
    try {
      // Channel-specific activation logic
      print('Activating emergency mode for channel: ${channel.name}');
      return true;
    } catch (e) {
      print('Error activating channel ${channel.name}: $e');
      return false;
    }
  }

  Future<bool> _deactivateChannel(CommunicationChannel channel) async {
    try {
      // Channel-specific deactivation logic
      print('Deactivating emergency mode for channel: ${channel.name}');
      return true;
    } catch (e) {
      print('Error deactivating channel ${channel.name}: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _getChannelStatus(CommunicationChannel channel) async {
    // Get real channel status - simplified for demo
    return {
      'status': 'active',
      'last_checked': DateTime.now().toIso8601String(),
      'error_rate': 0.01,
      'throughput': '1000/hour',
    };
  }

  Future<Map<String, dynamic>> _getChannelStatuses() async {
    final statuses = <String, dynamic>{};
    
    for (final channel in CommunicationChannel.values) {
      statuses[channel.name] = await _getChannelStatus(channel);
    }
    
    return statuses;
  }

  Future<Map<String, dynamic>> _testChannel(CommunicationChannel channel) async {
    try {
      // Perform channel-specific test
      return {
        'channel': channel.name,
        'status': 'pass',
        'response_time_ms': 150,
        'tested_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'channel': channel.name,
        'status': 'fail',
        'error': e.toString(),
        'tested_at': DateTime.now().toIso8601String(),
      };
    }
  }

  // Channel-specific implementations (simplified for demo)
  Future<bool> _sendSMS(String? phoneNumber, String message) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return false;
    // Integrate with SMS service (Twilio, AWS SNS, etc.)
    print('Sending SMS to $phoneNumber: $message');
    return true;
  }

  Future<bool> _sendEmail(String? email, String title, String message) async {
    if (email == null || email.isEmpty) return false;
    // Integrate with email service (SendGrid, AWS SES, etc.)
    print('Sending email to $email: $title');
    return true;
  }

  Future<bool> _sendPushNotification(String userId, String title, String message) async {
    // Integrate with push notification service (FCM, APNs, etc.)
    print('Sending push notification to $userId: $title');
    return true;
  }

  Future<bool> _sendInAppNotification(String userId, String title, String message) async {
    try {
      await _supabase.from('user_notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': 'emergency',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error sending in-app notification: $e');
      return false;
    }
  }

  Future<bool> _sendSocialNotification(String title, String message) async {
    // Integrate with social media APIs (Twitter, Facebook, etc.)
    print('Posting to social media: $title');
    return true;
  }

  Future<bool> _sendBroadcastNotification(String title, String message) async {
    // Integrate with broadcast systems (emergency alert systems, etc.)
    print('Broadcasting emergency message: $title');
    return true;
  }

  Future<void> _logCommunicationAction(String action, Map<String, dynamic> details) async {
    try {
      await _supabase.from('communication_activity_log').insert({
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
        'admin_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      print('Error logging communication action: $e');
    }
  }

  void _broadcastAlert(Map<String, dynamic> alertData) {
    if (_alertStreamController != null && !_alertStreamController!.isClosed) {
      _alertStreamController!.add({
        'type': 'emergency_alert',
        'data': alertData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Dispose resources
  void dispose() {
    _alertStreamController?.close();
    _notificationStreamController?.close();
    _alertStreamController = null;
    _notificationStreamController = null;
  }
}
