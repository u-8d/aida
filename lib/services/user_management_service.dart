import 'package:supabase_flutter/supabase_flutter.dart';

enum UserVerificationStatus {
  pending,
  verified,
  rejected,
  flagged,
  suspended,
}

enum BulkUserOperation {
  verify,
  suspend,
  unsuspend,
  flag,
  unflag,
  delete,
  sendMessage,
  exportData,
}

class UserManagementService {
  final _supabase = Supabase.instance.client;

  /// Get paginated users with filtering and search
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 50,
    String? searchQuery,
    UserVerificationStatus? verificationStatus,
    String? userType,
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool? isActive,
    String? sortBy = 'created_at',
    bool sortAscending = false,
  }) async {
    try {
      var query = _supabase
          .from('users')
          .select('id, email, name, user_type, created_at, last_sign_in_at, verification_status, is_suspended, phone_number, location, total_donations, total_received');

      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,email.ilike.%$searchQuery%,phone_number.ilike.%$searchQuery%');
      }

      if (verificationStatus != null) {
        query = query.eq('verification_status', verificationStatus.name);
      }

      if (userType != null && userType.isNotEmpty) {
        query = query.eq('user_type', userType);
      }

      if (createdAfter != null) {
        query = query.gte('created_at', createdAfter.toIso8601String());
      }

      if (createdBefore != null) {
        query = query.lte('created_at', createdBefore.toIso8601String());
      }

      if (isActive != null) {
        if (isActive) {
          query = query.not('last_sign_in_at', 'is', null);
        }
        // Skip filtering for inactive users for now due to API constraints
      }

      // Apply sorting
      final sortedQuery = query.order(sortBy ?? 'created_at', ascending: sortAscending);

      // Apply pagination
      final offset = (page - 1) * limit;
      final paginatedQuery = sortedQuery.range(offset, offset + limit - 1);

      final response = await paginatedQuery;
      
      // For now, we'll estimate total count based on response
      final totalCount = response.length < limit ? response.length + offset : (page * limit) + 1;

      return {
        'users': response,
        'total': totalCount,
        'page': page,
        'limit': limit,
        'total_pages': (totalCount / limit).ceil(),
        'has_next': response.length == limit,
        'has_previous': page > 1,
      };
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get detailed user information
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      // Get user basic info
      final userResponse = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      // Get user's donations
      final donationsResponse = await _supabase
          .from('donations')
          .select('id, amount, status, created_at, donation_type, campaign_id')
          .eq('donor_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      // Get user's requests (if they're a recipient)
      final requestsResponse = await _supabase
          .from('donation_requests')
          .select('id, title, description, status, created_at, category')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      // Get user activity log
      final activityResponse = await _supabase
          .from('user_activity_log')
          .select('id, action, details, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      // Calculate user statistics
      final totalDonated = donationsResponse.fold<double>(
        0.0,
        (sum, donation) => sum + (donation['amount'] as num? ?? 0).toDouble(),
      );

      final donationCount = donationsResponse.length;
      final requestCount = requestsResponse.length;

      return {
        'user': userResponse,
        'donations': donationsResponse,
        'requests': requestsResponse,
        'activity': activityResponse,
        'statistics': {
          'total_donated': totalDonated,
          'donation_count': donationCount,
          'request_count': requestCount,
          'avg_donation': donationCount > 0 ? totalDonated / donationCount : 0.0,
          'last_activity': activityResponse.isNotEmpty ? activityResponse.first['created_at'] : null,
        },
      };
    } catch (e) {
      print('Error fetching user details: $e');
      throw Exception('Failed to fetch user details: $e');
    }
  }

  /// Update user verification status
  Future<bool> updateUserVerificationStatus(
    String userId,
    UserVerificationStatus status,
    String? adminNotes,
  ) async {
    try {
      await _supabase
          .from('users')
          .update({
            'verification_status': status.name,
            'verified_at': status == UserVerificationStatus.verified ? DateTime.now().toIso8601String() : null,
            'admin_notes': adminNotes,
          })
          .eq('id', userId);

      // Log the action
      await _logUserAction(userId, 'verification_status_updated', {
        'new_status': status.name,
        'admin_notes': adminNotes,
      });

      return true;
    } catch (e) {
      print('Error updating user verification status: $e');
      return false;
    }
  }

  /// Suspend or unsuspend user
  Future<bool> updateUserSuspensionStatus(
    String userId,
    bool isSuspended,
    String? reason,
  ) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_suspended': isSuspended,
            'suspension_reason': isSuspended ? reason : null,
            'suspended_at': isSuspended ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', userId);

      // Log the action
      await _logUserAction(userId, isSuspended ? 'user_suspended' : 'user_unsuspended', {
        'reason': reason,
      });

      return true;
    } catch (e) {
      print('Error updating user suspension status: $e');
      return false;
    }
  }

  /// Bulk operations on multiple users
  Future<Map<String, dynamic>> performBulkOperation(
    List<String> userIds,
    BulkUserOperation operation,
    Map<String, dynamic>? parameters,
  ) async {
    final results = <String, bool>{};
    var successCount = 0;
    var errorCount = 0;
    final errors = <String>[];

    try {
      for (final userId in userIds) {
        try {
          bool success = false;

          switch (operation) {
            case BulkUserOperation.verify:
              success = await updateUserVerificationStatus(
                userId,
                UserVerificationStatus.verified,
                parameters?['admin_notes'] as String?,
              );
              break;
            
            case BulkUserOperation.suspend:
              success = await updateUserSuspensionStatus(
                userId,
                true,
                parameters?['reason'] as String?,
              );
              break;
            
            case BulkUserOperation.unsuspend:
              success = await updateUserSuspensionStatus(
                userId,
                false,
                null,
              );
              break;
            
            case BulkUserOperation.flag:
              success = await _flagUser(userId, parameters?['reason'] as String?);
              break;
            
            case BulkUserOperation.unflag:
              success = await _unflagUser(userId);
              break;
            
            case BulkUserOperation.delete:
              success = await _deleteUser(userId, parameters?['reason'] as String?);
              break;
            
            case BulkUserOperation.sendMessage:
              success = await _sendMessageToUser(
                userId,
                parameters?['subject'] as String? ?? '',
                parameters?['message'] as String? ?? '',
              );
              break;
            
            case BulkUserOperation.exportData:
              // This would be handled differently - export user data
              success = await _exportUserData(userId);
              break;
          }

          results[userId] = success;
          if (success) {
            successCount++;
          } else {
            errorCount++;
            errors.add('Failed operation for user $userId');
          }
        } catch (e) {
          results[userId] = false;
          errorCount++;
          errors.add('Error for user $userId: $e');
        }
      }

      // Log bulk operation
      await _logBulkOperation(operation, userIds.length, successCount, errorCount);

      return {
        'success': true,
        'total_processed': userIds.length,
        'success_count': successCount,
        'error_count': errorCount,
        'results': results,
        'errors': errors,
      };
    } catch (e) {
      print('Error performing bulk operation: $e');
      return {
        'success': false,
        'error': 'Failed to perform bulk operation: $e',
        'total_processed': userIds.length,
        'success_count': successCount,
        'error_count': errorCount,
        'results': results,
        'errors': errors,
      };
    }
  }

  /// Get user statistics and analytics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));
      final last7Days = now.subtract(const Duration(days: 7));
      final last30Days = now.subtract(const Duration(days: 30));

      // Get user data in batches to calculate statistics
      final allUsers = await _supabase
          .from('users')
          .select('id, created_at, verification_status, user_type, last_sign_in_at, is_suspended');

      final totalUsers = allUsers.length;

      // Calculate new registrations
      var newUsers24h = 0;
      var newUsers7d = 0;
      var newUsers30d = 0;
      var activeUsers7d = 0;
      var suspendedUsers = 0;

      final verificationDistribution = <String, int>{};
      final typeDistribution = <String, int>{};

      for (final user in allUsers) {
        final createdAt = DateTime.parse(user['created_at'] as String);
        final lastSignIn = user['last_sign_in_at'] != null ? DateTime.parse(user['last_sign_in_at'] as String) : null;
        final verificationStatus = user['verification_status'] as String? ?? 'pending';
        final userType = user['user_type'] as String? ?? 'individual';
        final isSuspended = user['is_suspended'] as bool? ?? false;

        if (createdAt.isAfter(last24Hours)) newUsers24h++;
        if (createdAt.isAfter(last7Days)) newUsers7d++;
        if (createdAt.isAfter(last30Days)) newUsers30d++;
        if (lastSignIn != null && lastSignIn.isAfter(last7Days)) activeUsers7d++;
        if (isSuspended) suspendedUsers++;

        verificationDistribution[verificationStatus] = (verificationDistribution[verificationStatus] ?? 0) + 1;
        typeDistribution[userType] = (typeDistribution[userType] ?? 0) + 1;
      }

      final pendingVerification = verificationDistribution['pending'] ?? 0;
      final flaggedUsers = verificationDistribution['flagged'] ?? 0;

      return {
        'total_users': totalUsers,
        'new_users_24h': newUsers24h,
        'new_users_7d': newUsers7d,
        'new_users_30d': newUsers30d,
        'active_users_7d': activeUsers7d,
        'suspended_users': suspendedUsers,
        'verification_distribution': verificationDistribution,
        'type_distribution': typeDistribution,
        'users_requiring_attention': pendingVerification + flaggedUsers,
        'growth_rate_7d': _calculateGrowthRate(newUsers7d, newUsers30d - newUsers7d),
        'activity_rate': totalUsers > 0 ? (activeUsers7d / totalUsers) * 100 : 0.0,
      };
    } catch (e) {
      print('Error fetching user analytics: $e');
      throw Exception('Failed to fetch user analytics: $e');
    }
  }

  /// Search users by various criteria
  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
    List<String>? searchFields,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email, phone_number, user_type, verification_status, created_at')
          .or('name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Get users requiring admin attention
  Future<List<Map<String, dynamic>>> getUsersRequiringAttention() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email, user_type, verification_status, created_at, last_sign_in_at, admin_notes')
          .or('verification_status.eq.pending,verification_status.eq.flagged,is_suspended.eq.true')
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users requiring attention: $e');
      throw Exception('Failed to fetch users requiring attention: $e');
    }
  }

  /// Emergency user support operations
  Future<Map<String, dynamic>> getEmergencyUserSupport(String userId) async {
    try {
      final userDetails = await getUserDetails(userId);
      
      // Get recent transactions and activities
      final recentTransactions = await _supabase
          .from('donations')
          .select('id, amount, status, created_at, donation_type')
          .or('donor_id.eq.$userId,recipient_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(5);

      // Check for any active disputes or issues
      final disputes = await _supabase
          .from('user_disputes')
          .select('id, type, status, description, created_at')
          .eq('user_id', userId)
          .eq('status', 'open');

      // Get emergency contact info if available
      final emergencyContacts = await _supabase
          .from('user_emergency_contacts')
          .select('name, phone, relationship')
          .eq('user_id', userId);

      return {
        'user_details': userDetails,
        'recent_transactions': recentTransactions,
        'open_disputes': disputes,
        'emergency_contacts': emergencyContacts,
        'support_status': _generateSupportStatus(userDetails['user'], recentTransactions, disputes),
      };
    } catch (e) {
      print('Error fetching emergency user support: $e');
      throw Exception('Failed to fetch emergency user support: $e');
    }
  }

  // Helper methods
  Future<bool> _flagUser(String userId, String? reason) async {
    try {
      await _supabase
          .from('users')
          .update({
            'verification_status': UserVerificationStatus.flagged.name,
            'flag_reason': reason,
            'flagged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await _logUserAction(userId, 'user_flagged', {'reason': reason});
      return true;
    } catch (e) {
      print('Error flagging user: $e');
      return false;
    }
  }

  Future<bool> _unflagUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'verification_status': UserVerificationStatus.verified.name,
            'flag_reason': null,
            'flagged_at': null,
          })
          .eq('id', userId);

      await _logUserAction(userId, 'user_unflagged', {});
      return true;
    } catch (e) {
      print('Error unflagging user: $e');
      return false;
    }
  }

  Future<bool> _deleteUser(String userId, String? reason) async {
    try {
      // Soft delete - mark as deleted instead of actually deleting
      await _supabase
          .from('users')
          .update({
            'is_deleted': true,
            'deletion_reason': reason,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await _logUserAction(userId, 'user_deleted', {'reason': reason});
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  Future<bool> _sendMessageToUser(String userId, String subject, String message) async {
    try {
      // Insert into user notifications/messages table
      await _supabase
          .from('user_notifications')
          .insert({
            'user_id': userId,
            'type': 'admin_message',
            'title': subject,
            'message': message,
            'created_at': DateTime.now().toIso8601String(),
          });

      await _logUserAction(userId, 'admin_message_sent', {
        'subject': subject,
        'message': message,
      });
      return true;
    } catch (e) {
      print('Error sending message to user: $e');
      return false;
    }
  }

  Future<bool> _exportUserData(String userId) async {
    try {
      // This would generate a data export for the user
      // For now, just log the action
      await _logUserAction(userId, 'data_export_requested', {});
      return true;
    } catch (e) {
      print('Error exporting user data: $e');
      return false;
    }
  }

  Future<void> _logUserAction(String userId, String action, Map<String, dynamic> details) async {
    try {
      await _supabase
          .from('user_activity_log')
          .insert({
            'user_id': userId,
            'action': action,
            'details': details,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error logging user action: $e');
    }
  }

  Future<void> _logBulkOperation(BulkUserOperation operation, int totalUsers, int successCount, int errorCount) async {
    try {
      await _supabase
          .from('admin_activity_log')
          .insert({
            'action': 'bulk_user_operation',
            'details': {
              'operation': operation.name,
              'total_users': totalUsers,
              'success_count': successCount,
              'error_count': errorCount,
            },
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error logging bulk operation: $e');
    }
  }

  double _calculateGrowthRate(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100.0;
  }

  Map<String, dynamic> _generateSupportStatus(
    Map<String, dynamic> user,
    List<dynamic> transactions,
    List<dynamic> disputes,
  ) {
    final isSuspended = user['is_suspended'] as bool? ?? false;
    final verificationStatus = user['verification_status'] as String? ?? 'pending';
    final hasOpenDisputes = disputes.isNotEmpty;
    
    String status;
    String priority;
    List<String> issues = [];

    if (isSuspended) {
      status = 'suspended';
      priority = 'high';
      issues.add('Account is suspended');
    } else if (hasOpenDisputes) {
      status = 'disputed';
      priority = 'high';
      issues.add('Has open disputes');
    } else if (verificationStatus == 'flagged') {
      status = 'flagged';
      priority = 'medium';
      issues.add('Account is flagged');
    } else if (verificationStatus == 'pending') {
      status = 'pending_verification';
      priority = 'low';
      issues.add('Pending verification');
    } else {
      status = 'normal';
      priority = 'low';
    }

    return {
      'status': status,
      'priority': priority,
      'issues': issues,
      'requires_immediate_attention': priority == 'high',
    };
  }
}
