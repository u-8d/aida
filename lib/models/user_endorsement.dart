class UserEndorsement {
  final String id;
  final String endorserId;
  final String endorsedUserId;
  final DateTime createdAt;

  UserEndorsement({
    required this.id,
    required this.endorserId,
    required this.endorsedUserId,
    required this.createdAt,
  });

  factory UserEndorsement.fromJson(Map<String, dynamic> json) {
    return UserEndorsement(
      id: json['id'] as String,
      endorserId: json['endorser_id'] as String,
      endorsedUserId: json['endorsed_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endorser_id': endorserId,
      'endorsed_user_id': endorsedUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
