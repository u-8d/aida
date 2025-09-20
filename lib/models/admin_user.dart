import 'user.dart';

/// Admin user roles for disaster response platform
enum AdminRole {
  superAdmin,
  disasterCoordinator,
  crisisModerator,
  analyticsViewer,
  userSupport,
}

/// Permissions for admin roles
enum AdminPermission {
  // System-wide permissions
  systemAdmin,
  
  // Crisis management permissions
  crisisModeToggle,
  disasterCampaignCreate,
  disasterCampaignManage,
  emergencyResourceAllocation,
  
  // User management permissions
  userVerification,
  userBulkOperations,
  userEmergencySupport,
  
  // Analytics permissions
  realTimeAnalytics,
  surgeMonitoring,
  systemPerformance,
  
  // Moderation permissions
  contentModeration,
  platformModeration,
}

/// Crisis severity levels
enum CrisisLevel {
  low,
  moderate,
  high,
  critical,
  emergency,
}

class AdminUser extends User {
  final AdminRole adminRole;
  final List<AdminPermission> permissions;
  final bool isCrisisMode;
  final CrisisLevel? currentCrisisLevel;
  final DateTime? lastActiveSession;
  final List<String> managedDisasterCampaigns;
  final Map<String, dynamic> securitySettings;
  final bool mfaEnabled;
  final DateTime? mfaVerifiedAt;
  
  AdminUser({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String city,
    required this.adminRole,
    required this.permissions,
    required DateTime createdAt,
    bool isVerified = false,
    this.isCrisisMode = false,
    this.currentCrisisLevel,
    this.lastActiveSession,
    this.managedDisasterCampaigns = const [],
    this.securitySettings = const {},
    this.mfaEnabled = false,
    this.mfaVerifiedAt,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          city: city,
          userType: UserType.admin,
          createdAt: createdAt,
          isVerified: isVerified,
        );

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
      adminRole: AdminRole.values.firstWhere(
        (role) => role.toString().split('.').last == json['admin_role'],
        orElse: () => AdminRole.userSupport,
      ),
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((p) => AdminPermission.values.firstWhere(
              (perm) => perm.toString().split('.').last == p,
              orElse: () => AdminPermission.contentModeration,
            ))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
      isCrisisMode: json['is_crisis_mode'] as bool? ?? false,
      currentCrisisLevel: json['current_crisis_level'] != null
          ? CrisisLevel.values.firstWhere(
              (level) => level.toString().split('.').last == json['current_crisis_level'],
              orElse: () => CrisisLevel.low,
            )
          : null,
      lastActiveSession: json['last_active_session'] != null
          ? DateTime.parse(json['last_active_session'] as String)
          : null,
      managedDisasterCampaigns: (json['managed_disaster_campaigns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      securitySettings: (json['security_settings'] as Map<String, dynamic>?) ?? {},
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      mfaVerifiedAt: json['mfa_verified_at'] != null
          ? DateTime.parse(json['mfa_verified_at'] as String)
          : null,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'user_type': 'admin',
      'admin_role': adminRole.toString().split('.').last,
      'permissions': permissions.map((p) => p.toString().split('.').last).toList(),
      'created_at': createdAt.toIso8601String(),
      'is_verified': isVerified,
      'is_crisis_mode': isCrisisMode,
      'current_crisis_level': currentCrisisLevel?.toString().split('.').last,
      'last_active_session': lastActiveSession?.toIso8601String(),
      'managed_disaster_campaigns': managedDisasterCampaigns,
      'security_settings': securitySettings,
      'mfa_enabled': mfaEnabled,
      'mfa_verified_at': mfaVerifiedAt?.toIso8601String(),
    };
  }

  /// Check if admin has specific permission
  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission);
  }

  /// Check if admin can manage crisis mode
  bool canManageCrisis() {
    return hasPermission(AdminPermission.crisisModeToggle) ||
           adminRole == AdminRole.superAdmin ||
           adminRole == AdminRole.disasterCoordinator;
  }

  /// Check if admin can access analytics
  bool canAccessAnalytics() {
    return hasPermission(AdminPermission.realTimeAnalytics) ||
           hasPermission(AdminPermission.surgeMonitoring) ||
           hasPermission(AdminPermission.systemPerformance) ||
           adminRole == AdminRole.superAdmin ||
           adminRole == AdminRole.analyticsViewer;
  }

  /// Check if admin can manage users
  bool canManageUsers() {
    return hasPermission(AdminPermission.userVerification) ||
           hasPermission(AdminPermission.userBulkOperations) ||
           hasPermission(AdminPermission.userEmergencySupport) ||
           adminRole == AdminRole.superAdmin ||
           adminRole == AdminRole.userSupport;
  }

  /// Check if admin can create disaster campaigns
  bool canCreateDisasterCampaigns() {
    return hasPermission(AdminPermission.disasterCampaignCreate) ||
           adminRole == AdminRole.superAdmin ||
           adminRole == AdminRole.disasterCoordinator;
  }

  /// Check if admin can moderate content
  bool canModerateContent() {
    return hasPermission(AdminPermission.contentModeration) ||
           hasPermission(AdminPermission.platformModeration) ||
           adminRole == AdminRole.superAdmin ||
           adminRole == AdminRole.crisisModerator;
  }

  /// Get role display name
  String get roleDisplayName {
    switch (adminRole) {
      case AdminRole.superAdmin:
        return 'Super Administrator';
      case AdminRole.disasterCoordinator:
        return 'Disaster Response Coordinator';
      case AdminRole.crisisModerator:
        return 'Crisis Moderator';
      case AdminRole.analyticsViewer:
        return 'Analytics Viewer';
      case AdminRole.userSupport:
        return 'User Support Specialist';
    }
  }

  /// Get crisis level display name
  String get crisisLevelDisplayName {
    if (currentCrisisLevel == null) return 'Normal Operations';
    
    switch (currentCrisisLevel!) {
      case CrisisLevel.low:
        return 'Low Alert';
      case CrisisLevel.moderate:
        return 'Moderate Alert';
      case CrisisLevel.high:
        return 'High Alert';
      case CrisisLevel.critical:
        return 'Critical Alert';
      case CrisisLevel.emergency:
        return 'Emergency Alert';
    }
  }

  /// Check if session is active and valid
  bool get isSessionActive {
    if (lastActiveSession == null) return false;
    
    final sessionTimeout = Duration(hours: 8); // 8-hour session timeout
    final now = DateTime.now();
    
    return now.difference(lastActiveSession!) < sessionTimeout;
  }

  /// Check if MFA is required and valid
  bool get isMfaValid {
    if (!mfaEnabled) return true; // MFA not required
    if (mfaVerifiedAt == null) return false; // MFA not verified
    
    final mfaTimeout = Duration(hours: 1); // 1-hour MFA timeout
    final now = DateTime.now();
    
    return now.difference(mfaVerifiedAt!) < mfaTimeout;
  }

  /// Create copy with updated properties
  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? city,
    DateTime? createdAt,
    bool? isVerified,
    AdminRole? adminRole,
    List<AdminPermission>? permissions,
    bool? isCrisisMode,
    CrisisLevel? currentCrisisLevel,
    DateTime? lastActiveSession,
    List<String>? managedDisasterCampaigns,
    Map<String, dynamic>? securitySettings,
    bool? mfaEnabled,
    DateTime? mfaVerifiedAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      adminRole: adminRole ?? this.adminRole,
      permissions: permissions ?? this.permissions,
      isCrisisMode: isCrisisMode ?? this.isCrisisMode,
      currentCrisisLevel: currentCrisisLevel ?? this.currentCrisisLevel,
      lastActiveSession: lastActiveSession ?? this.lastActiveSession,
      managedDisasterCampaigns: managedDisasterCampaigns ?? this.managedDisasterCampaigns,
      securitySettings: securitySettings ?? this.securitySettings,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      mfaVerifiedAt: mfaVerifiedAt ?? this.mfaVerifiedAt,
    );
  }
}

/// Default permissions for each admin role
class AdminRolePermissions {
  static List<AdminPermission> getPermissionsForRole(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AdminPermission.values; // All permissions
        
      case AdminRole.disasterCoordinator:
        return [
          AdminPermission.crisisModeToggle,
          AdminPermission.disasterCampaignCreate,
          AdminPermission.disasterCampaignManage,
          AdminPermission.emergencyResourceAllocation,
          AdminPermission.realTimeAnalytics,
          AdminPermission.surgeMonitoring,
          AdminPermission.systemPerformance,
          AdminPermission.userEmergencySupport,
        ];
        
      case AdminRole.crisisModerator:
        return [
          AdminPermission.contentModeration,
          AdminPermission.platformModeration,
          AdminPermission.userEmergencySupport,
          AdminPermission.realTimeAnalytics,
        ];
        
      case AdminRole.analyticsViewer:
        return [
          AdminPermission.realTimeAnalytics,
          AdminPermission.surgeMonitoring,
          AdminPermission.systemPerformance,
        ];
        
      case AdminRole.userSupport:
        return [
          AdminPermission.userVerification,
          AdminPermission.userBulkOperations,
          AdminPermission.userEmergencySupport,
          AdminPermission.contentModeration,
        ];
    }
  }
}
