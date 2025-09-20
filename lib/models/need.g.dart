// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'need.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Need _$NeedFromJson(Map<String, dynamic> json) => Need(
  id: json['id'] as String,
  recipientId: json['recipientId'] as String,
  recipientName: json['recipientName'] as String,
  recipientType: json['recipientType'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  requiredTags: (json['requiredTags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  city: json['city'] as String,
  urgency: $enumDecode(_$UrgencyLevelEnumMap, json['urgency']),
  status: $enumDecode(_$NeedStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  fulfilledAt: json['fulfilledAt'] == null
      ? null
      : DateTime.parse(json['fulfilledAt'] as String),
  quantity: (json['quantity'] as num).toInt(),
  fulfilledQuantity: (json['fulfilledQuantity'] as num?)?.toInt(),
);

Map<String, dynamic> _$NeedToJson(Need instance) => <String, dynamic>{
  'id': instance.id,
  'recipientId': instance.recipientId,
  'recipientName': instance.recipientName,
  'recipientType': instance.recipientType,
  'title': instance.title,
  'description': instance.description,
  'requiredTags': instance.requiredTags,
  'city': instance.city,
  'urgency': _$UrgencyLevelEnumMap[instance.urgency]!,
  'status': _$NeedStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'fulfilledAt': instance.fulfilledAt?.toIso8601String(),
  'quantity': instance.quantity,
  'fulfilledQuantity': instance.fulfilledQuantity,
};

const _$UrgencyLevelEnumMap = {
  UrgencyLevel.low: 'low',
  UrgencyLevel.medium: 'medium',
  UrgencyLevel.high: 'high',
  UrgencyLevel.urgent: 'urgent',
};

const _$NeedStatusEnumMap = {
  NeedStatus.unmet: 'unmet',
  NeedStatus.partialMatch: 'partialMatch',
  NeedStatus.fulfilled: 'fulfilled',
  NeedStatus.cancelled: 'cancelled',
};
