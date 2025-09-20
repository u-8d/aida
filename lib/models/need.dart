import 'package:json_annotation/json_annotation.dart';

part 'need.g.dart';

@JsonSerializable()
class Need {
  final String id;
  final String recipientId;
  final String recipientName;
  final String recipientType; // 'ngo' or 'individual'
  final String title;
  final String description;
  final List<String> requiredTags;
  final String city;
  final UrgencyLevel urgency;
  final NeedStatus status;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final int quantity;
  final int? fulfilledQuantity;

  Need({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.recipientType,
    required this.title,
    required this.description,
    required this.requiredTags,
    required this.city,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.fulfilledAt,
    required this.quantity,
    this.fulfilledQuantity,
  });

  factory Need.fromJson(Map<String, dynamic> json) => _$NeedFromJson(json);
  Map<String, dynamic> toJson() => _$NeedToJson(this);
}

enum UrgencyLevel {
  low,
  medium,
  high,
  urgent,
}

enum NeedStatus {
  unmet,
  partialMatch,
  fulfilled,
  cancelled,
}
