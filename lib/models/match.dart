import 'package:json_annotation/json_annotation.dart';

part 'match.g.dart';

@JsonSerializable()
class Match {
  final String id;
  final String donationId;
  final String needId;
  final String donorId;
  final String recipientId;
  final double matchScore;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? chatId;

  Match({
    required this.id,
    required this.donationId,
    required this.needId,
    required this.donorId,
    required this.recipientId,
    required this.matchScore,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.chatId,
  });

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);
  Map<String, dynamic> toJson() => _$MatchToJson(this);
}

enum MatchStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled,
}
