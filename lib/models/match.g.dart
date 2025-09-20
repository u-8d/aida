// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Match _$MatchFromJson(Map<String, dynamic> json) => Match(
  id: json['id'] as String,
  donationId: json['donationId'] as String,
  needId: json['needId'] as String,
  donorId: json['donorId'] as String,
  recipientId: json['recipientId'] as String,
  matchScore: (json['matchScore'] as num).toDouble(),
  status: $enumDecode(_$MatchStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  acceptedAt: json['acceptedAt'] == null
      ? null
      : DateTime.parse(json['acceptedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  chatId: json['chatId'] as String?,
);

Map<String, dynamic> _$MatchToJson(Match instance) => <String, dynamic>{
  'id': instance.id,
  'donationId': instance.donationId,
  'needId': instance.needId,
  'donorId': instance.donorId,
  'recipientId': instance.recipientId,
  'matchScore': instance.matchScore,
  'status': _$MatchStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'acceptedAt': instance.acceptedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'chatId': instance.chatId,
};

const _$MatchStatusEnumMap = {
  MatchStatus.pending: 'pending',
  MatchStatus.accepted: 'accepted',
  MatchStatus.rejected: 'rejected',
  MatchStatus.completed: 'completed',
  MatchStatus.cancelled: 'cancelled',
};
