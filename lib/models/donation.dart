import 'package:json_annotation/json_annotation.dart';

part 'donation.g.dart';

@JsonSerializable()
class Donation {
  final String id;
  @JsonKey(name: 'donor_id')
  final String donorId;
  @JsonKey(name: 'item_name')
  final String itemName;
  final String description;
  @JsonKey(name: 'context_description')
  final String? contextDescription; // Optional context for AI analysis
  final List<String> tags;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final String city;
  final DonationStatus status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'matched_at')
  final DateTime? matchedAt;
  @JsonKey(name: 'matched_recipient_id')
  final String? matchedRecipientId;
  @JsonKey(name: 'matched_recipient_name')
  final String? matchedRecipientName;

  Donation({
    required this.id,
    required this.donorId,
    required this.itemName,
    required this.description,
    this.contextDescription,
    required this.tags,
    required this.imageUrl,
    required this.city,
    required this.status,
    required this.createdAt,
    this.matchedAt,
    this.matchedRecipientId,
    this.matchedRecipientName,
  });

  factory Donation.fromJson(Map<String, dynamic> json) => _$DonationFromJson(json);
  Map<String, dynamic> toJson() => _$DonationToJson(this);

  Donation copyWith({
    String? id,
    String? donorId,
    String? itemName,
    String? description,
    String? contextDescription,
    List<String>? tags,
    String? imageUrl,
    String? city,
    DonationStatus? status,
    DateTime? createdAt,
    DateTime? matchedAt,
    String? matchedRecipientId,
    String? matchedRecipientName,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      contextDescription: contextDescription ?? this.contextDescription,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      city: city ?? this.city,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      matchedAt: matchedAt ?? this.matchedAt,
      matchedRecipientId: matchedRecipientId ?? this.matchedRecipientId,
      matchedRecipientName: matchedRecipientName ?? this.matchedRecipientName,
    );
  }
}

enum DonationStatus {
  available,
  pendingMatch,
  matchFound,
  readyForPickup,
  donationCompleted,
  cancelled,
}
