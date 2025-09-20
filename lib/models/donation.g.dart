// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Donation _$DonationFromJson(Map<String, dynamic> json) => Donation(
  id: json['id'] as String,
  donorId: json['donor_id'] as String,
  itemName: json['item_name'] as String,
  description: json['description'] as String,
  contextDescription: json['context_description'] as String?,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  imageUrl: json['image_url'] as String,
  city: json['city'] as String,
  status: $enumDecode(_$DonationStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
  matchedAt: json['matched_at'] == null
      ? null
      : DateTime.parse(json['matched_at'] as String),
  matchedRecipientId: json['matched_recipient_id'] as String?,
  matchedRecipientName: json['matched_recipient_name'] as String?,
);

Map<String, dynamic> _$DonationToJson(Donation instance) => <String, dynamic>{
  'id': instance.id,
  'donor_id': instance.donorId,
  'item_name': instance.itemName,
  'description': instance.description,
  'context_description': instance.contextDescription,
  'tags': instance.tags,
  'image_url': instance.imageUrl,
  'city': instance.city,
  'status': _$DonationStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'matched_at': instance.matchedAt?.toIso8601String(),
  'matched_recipient_id': instance.matchedRecipientId,
  'matched_recipient_name': instance.matchedRecipientName,
};

const _$DonationStatusEnumMap = {
  DonationStatus.available: 'available',
  DonationStatus.pendingMatch: 'pendingMatch',
  DonationStatus.matchFound: 'matchFound',
  DonationStatus.readyForPickup: 'readyForPickup',
  DonationStatus.donationCompleted: 'donationCompleted',
  DonationStatus.cancelled: 'cancelled',
};
