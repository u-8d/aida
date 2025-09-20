import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user.dart';
import '../models/disaster_campaign.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Authenticate admin user with special privileges
  static Future<AdminUser?> authenticateAdmin(String email, String password) async {
    try {
      if (kDebugMode) {
        print('Attempting admin authentication for: $email');
      }

      // Check predefined admin credentials
      if (!_isValidAdminCredentials(email, password)) {
        if (kDebugMode) {
          print('Invalid admin credentials provided');
        }
        return null;
      }

      // Return predefined admin user based on credentials
      return _getPredefinedAdmin(email);
    } catch (e) {
      if (kDebugMode) {
        print('Admin authentication error: $e');
      }
      return null;
    }
  }

  /// Check if provided credentials match predefined admin accounts
  static bool _isValidAdminCredentials(String email, String password) {
    final predefinedAdmins = _getPredefinedAdminCredentials();
    return predefinedAdmins.containsKey(email) && predefinedAdmins[email] == password;
  }

  /// Get predefined admin credentials
  static Map<String, String> _getPredefinedAdminCredentials() {
    return {
      'admin@aida.org': 'admin123',
      'superadmin@aida.org': 'super123',
      'crisis@aida.org': 'crisis123',
      'analyst@aida.org': 'analyst123',
      'support@aida.org': 'support123',
    };
  }

  /// Get predefined admin user based on email
  static AdminUser _getPredefinedAdmin(String email) {
    final now = DateTime.now();
    
    switch (email) {
      case 'superadmin@aida.org':
        return AdminUser(
          id: 'admin_super_001',
          name: 'Super Administrator',
          email: email,
          phone: '+1-555-0001',
          city: 'Headquarters',
          adminRole: AdminRole.superAdmin,
          permissions: AdminRolePermissions.getPermissionsForRole(AdminRole.superAdmin),
          createdAt: now,
          lastActiveSession: now,
          isVerified: true,
          isCrisisMode: false,
          managedDisasterCampaigns: [],
          securitySettings: {},
          mfaEnabled: false,
        );
      case 'crisis@aida.org':
        return AdminUser(
          id: 'admin_crisis_001',
          name: 'Crisis Manager',
          email: email,
          phone: '+1-555-0002',
          city: 'Emergency Center',
          adminRole: AdminRole.disasterCoordinator,
          permissions: AdminRolePermissions.getPermissionsForRole(AdminRole.disasterCoordinator),
          createdAt: now,
          lastActiveSession: now,
          isVerified: true,
          isCrisisMode: false,
          managedDisasterCampaigns: [],
          securitySettings: {},
          mfaEnabled: false,
        );
      case 'analyst@aida.org':
        return AdminUser(
          id: 'admin_analyst_001',
          name: 'Data Analyst',
          email: email,
          phone: '+1-555-0003',
          city: 'Analytics Hub',
          adminRole: AdminRole.analyticsViewer,
          permissions: AdminRolePermissions.getPermissionsForRole(AdminRole.analyticsViewer),
          createdAt: now,
          lastActiveSession: now,
          isVerified: true,
          isCrisisMode: false,
          managedDisasterCampaigns: [],
          securitySettings: {},
          mfaEnabled: false,
        );
      case 'support@aida.org':
        return AdminUser(
          id: 'admin_support_001',
          name: 'Support Agent',
          email: email,
          phone: '+1-555-0004',
          city: 'Support Center',
          adminRole: AdminRole.userSupport,
          permissions: AdminRolePermissions.getPermissionsForRole(AdminRole.userSupport),
          createdAt: now,
          lastActiveSession: now,
          isVerified: true,
          isCrisisMode: false,
          managedDisasterCampaigns: [],
          securitySettings: {},
          mfaEnabled: false,
        );
      default: // admin@aida.org
        return AdminUser(
          id: 'admin_content_001',
          name: 'Content Moderator',
          email: email,
          phone: '+1-555-0005',
          city: 'Moderation Center',
          adminRole: AdminRole.crisisModerator,
          permissions: AdminRolePermissions.getPermissionsForRole(AdminRole.crisisModerator),
          createdAt: now,
          lastActiveSession: now,
          isVerified: true,
          isCrisisMode: false,
          managedDisasterCampaigns: [],
          securitySettings: {},
          mfaEnabled: false,
        );
    }
  }

  /// Get admin profile by user ID
  static Future<AdminUser?> getAdminProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .eq('user_type', 'admin')
          .single();

      return AdminUser.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching admin profile: $e');
      }
      return null;
    }
  }

  /// Create a new admin user (only by super-admin)
  static Future<AdminUser?> createAdminUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String city,
    required AdminRole role,
    required String createdByAdminId,
  }) async {
    try {
      // Verify creator is super-admin
      final creator = await getAdminProfile(createdByAdminId);
      if (creator?.adminRole != AdminRole.superAdmin) {
        throw Exception('Only super-admins can create new admin users');
      }

      // Create auth user
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      // Create admin profile
      final adminData = {
        'id': authResponse.user!.id,
        'name': name,
        'email': email,
        'phone': phone,
        'city': city,
        'user_type': 'admin',
        'admin_role': role.toString().split('.').last,
        'permissions': AdminRolePermissions.getPermissionsForRole(role)
            .map((p) => p.toString().split('.').last)
            .toList(),
        'created_at': DateTime.now().toIso8601String(),
        'is_verified': true,
        'is_crisis_mode': false,
        'managed_disaster_campaigns': <String>[],
        'security_settings': <String, dynamic>{},
        'mfa_enabled': false,
      };

      await _supabase.from('users').insert(adminData);

      return AdminUser.fromJson(adminData);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin user: $e');
      }
      return null;
    }
  }

  /// Update admin user profile
  static Future<bool> updateAdminProfile(AdminUser admin) async {
    try {
      final updateData = admin.toJson();
      updateData['last_updated'] = DateTime.now().toIso8601String();

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', admin.id);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin profile: $e');
      }
      return false;
    }
  }

  /// Get all admin users (super-admin only)
  static Future<List<AdminUser>> getAllAdminUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_type', 'admin')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => AdminUser.fromJson(data))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching admin users: $e');
      }
      return [];
    }
  }

  /// Toggle crisis mode (disaster-coordinator and super-admin only)
  static Future<bool> toggleCrisisMode(
    String adminId,
    bool isEnabled,
    CrisisLevel? crisisLevel,
  ) async {
    try {
      final admin = await getAdminProfile(adminId);
      if (admin == null || !admin.canManageCrisis()) {
        throw Exception('Insufficient permissions to manage crisis mode');
      }

      final updateData = {
        'is_crisis_mode': isEnabled,
        'current_crisis_level': crisisLevel?.toString().split('.').last,
        'last_updated': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', adminId);

      // Log crisis mode change
      await _logAdminAction(
        adminId,
        'crisis_mode_toggle',
        'Crisis mode ${isEnabled ? 'enabled' : 'disabled'}${crisisLevel != null ? ' at $crisisLevel level' : ''}',
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling crisis mode: $e');
      }
      return false;
    }
  }

  /// Create disaster campaign
  static Future<DisasterCampaign?> createDisasterCampaign(
    DisasterCampaign campaign,
    String createdByAdminId,
  ) async {
    try {
      final admin = await getAdminProfile(createdByAdminId);
      if (admin == null || !admin.canCreateDisasterCampaigns()) {
        throw Exception('Insufficient permissions to create disaster campaigns');
      }

      final campaignData = campaign.toJson();
      campaignData['created_by'] = createdByAdminId;
      campaignData['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('disaster_campaigns')
          .insert(campaignData)
          .select()
          .single();

      await _logAdminAction(
        createdByAdminId,
        'disaster_campaign_create',
        'Created disaster campaign: ${campaign.title}',
      );

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating disaster campaign: $e');
      }
      return null;
    }
  }

  /// Get all disaster campaigns
  static Future<List<DisasterCampaign>> getDisasterCampaigns({
    CampaignStatus? status,
    bool activeOnly = false,
  }) async {
    try {
      var query = _supabase.from('disaster_campaigns').select();

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }

      if (activeOnly) {
        query = query.or('status.eq.active,status.eq.urgent');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((data) => DisasterCampaign.fromJson(data))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching disaster campaigns: $e');
      }
      return [];
    }
  }

  /// Update disaster campaign
  static Future<bool> updateDisasterCampaign(
    DisasterCampaign campaign,
    String updatedByAdminId,
  ) async {
    try {
      final admin = await getAdminProfile(updatedByAdminId);
      if (admin == null || !admin.canCreateDisasterCampaigns()) {
        throw Exception('Insufficient permissions to update disaster campaigns');
      }

      final updateData = campaign.toJson();
      updateData['last_updated'] = DateTime.now().toIso8601String();
      updateData['updated_by'] = updatedByAdminId;

      await _supabase
          .from('disaster_campaigns')
          .update(updateData)
          .eq('id', campaign.id);

      await _logAdminAction(
        updatedByAdminId,
        'disaster_campaign_update',
        'Updated disaster campaign: ${campaign.title}',
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating disaster campaign: $e');
      }
      return false;
    }
  }

  /// Get real-time analytics data
  static Future<Map<String, dynamic>> getRealtimeAnalytics() async {
    try {
      // This would typically involve complex queries
      // For now, we'll return mock data structure
      
      return {
        'user_surge': {
          'current_active_users': 0, // Real-time active users
          'hourly_registrations': 0, // New registrations this hour
          'daily_growth': 0.0, // Percentage growth today
          'peak_concurrent_users': 0, // Today's peak
        },
        'donation_velocity': {
          'donations_per_hour': 0, // Donations in last hour
          'total_today': 0, // Total donations today
          'average_processing_time': 0.0, // In minutes
          'completion_rate': 0.0, // Percentage of successful donations
        },
        'matching_efficiency': {
          'matches_per_hour': 0, // Matches created in last hour
          'auto_match_success_rate': 0.0, // Percentage of auto-matches
          'average_match_time': 0.0, // Time to match in hours
          'pending_matches': 0, // Unresolved matches
        },
        'system_performance': {
          'response_time_ms': 0.0, // Average API response time
          'error_rate': 0.0, // Percentage of failed requests
          'uptime_percentage': 99.9, // System uptime
          'database_load': 0.0, // Database utilization percentage
        },
        'crisis_metrics': {
          'active_campaigns': 0, // Currently active disaster campaigns
          'urgent_needs': 0, // High-priority unmet needs
          'emergency_mode_status': false, // Is emergency mode active
          'resource_fulfillment_rate': 0.0, // Percentage of needs fulfilled
        },
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching real-time analytics: $e');
      }
      return {};
    }
  }

  /// Get user management statistics
  static Future<Map<String, dynamic>> getUserManagementStats() async {
    try {
      // This would involve complex user queries
      return {
        'total_users': 0,
        'verified_users': 0,
        'pending_verification': 0,
        'active_donors': 0,
        'active_recipients': 0,
        'flagged_accounts': 0,
        'new_registrations_today': 0,
        'user_types_breakdown': {
          'donor': 0,
          'ngo': 0,
          'individual': 0,
          'admin': 0,
        },
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user management stats: $e');
      }
      return {};
    }
  }

  /// Log admin actions for audit trail
  static Future<void> _logAdminAction(
    String adminId,
    String action,
    String description,
  ) async {
    try {
      await _supabase.from('admin_audit_log').insert({
        'admin_id': adminId,
        'action': action,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'ip_address': 'unknown', // Would get from request context
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error logging admin action: $e');
      }
    }
  }

  /// Verify admin session and update last active
  static Future<bool> verifyAndUpdateSession(String adminId) async {
    try {
      await _supabase
          .from('users')
          .update({'last_active_session': DateTime.now().toIso8601String()})
          .eq('id', adminId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin session: $e');
      }
      return false;
    }
  }

  /// Sign out admin
  static Future<void> signOutAdmin() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out admin: $e');
      }
    }
  }
}
