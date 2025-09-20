import 'package:json_annotation/json_annotation.dart';
import 'chat_message.dart';

part 'chat_conversation.g.dart';

@JsonSerializable()
class ChatConversation {
  final String id;
  final String donationId;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;
  final String receiverType; // 'ai' or 'human'
  final String donationTitle;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final bool isActive;

  ChatConversation({
    required this.id,
    required this.donationId,
    required this.donorId,
    required this.donorName,
    required this.receiverId,
    required this.receiverName,
    required this.receiverType,
    required this.donationTitle,
    required this.messages,
    required this.createdAt,
    this.lastMessageAt,
    this.isActive = true,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) => _$ChatConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ChatConversationToJson(this);

  ChatConversation copyWith({
    String? id,
    String? donationId,
    String? donorId,
    String? donorName,
    String? receiverId,
    String? receiverName,
    String? receiverType,
    String? donationTitle,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isActive,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      donationId: donationId ?? this.donationId,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverType: receiverType ?? this.receiverType,
      donationTitle: donationTitle ?? this.donationTitle,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
