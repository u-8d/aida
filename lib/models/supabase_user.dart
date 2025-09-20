class SupabaseUser {
  final String id;
  final String email;
  final String name;
  final String userType;
  final String? city;
  final String? phone;
  final DateTime createdAt;
  final String? profilePictureUrl;
  final bool isVerified;
  final String? bio;
  final int endorsementCount;
  final int reportCount;
  final bool isActive;

  SupabaseUser({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.city,
    this.phone,
    required this.createdAt,
    this.profilePictureUrl,
    this.isVerified = false,
    this.bio,
    this.endorsementCount = 0,
    this.reportCount = 0,
    this.isActive = true,
  });

  factory SupabaseUser.fromJson(Map<String, dynamic> json) {
    return SupabaseUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: json['user_type'] as String,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profilePictureUrl: json['profile_picture_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      bio: json['bio'] as String?,
      endorsementCount: json['endorsement_count'] as int? ?? 0,
      reportCount: json['report_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'user_type': userType,
      'city': city,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'profile_picture_url': profilePictureUrl,
      'is_verified': isVerified,
      'bio': bio,
      'endorsement_count': endorsementCount,
      'report_count': reportCount,
      'is_active': isActive,
    };
  }

  // Helper method to convert from your existing User model
  factory SupabaseUser.fromUser(dynamic user) {
    return SupabaseUser(
      id: user.id,
      email: user.email,
      name: user.name,
      userType: user.userType.toString().split('.').last,
      city: user.city,
      phone: user.phone,
      createdAt: user.createdAt,
      isVerified: user.isVerified ?? false,
    );
  }

  // Helper method to create copy with updated fields
  SupabaseUser copyWith({
    String? id,
    String? email,
    String? name,
    String? userType,
    String? city,
    String? phone,
    DateTime? createdAt,
    String? profilePictureUrl,
    bool? isVerified,
    String? bio,
    int? endorsementCount,
    int? reportCount,
    bool? isActive,
  }) {
    return SupabaseUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
      endorsementCount: endorsementCount ?? this.endorsementCount,
      reportCount: reportCount ?? this.reportCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
