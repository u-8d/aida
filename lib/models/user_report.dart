class UserReport {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminNotes,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedUserId: json['reported_user_id'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at'] as String) 
          : null,
      adminNotes: json['admin_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'description': description,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'admin_notes': adminNotes,
    };
  }
}

enum ReportStatus {
  pending,
  reviewed,
  resolved,
  dismissed,
}
