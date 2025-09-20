// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatConversation _$ChatConversationFromJson(Map<String, dynamic> json) =>
    ChatConversation(
      id: json['id'] as String,
      donationId: json['donationId'] as String,
      donorId: json['donorId'] as String,
      donorName: json['donorName'] as String,
      receiverId: json['receiverId'] as String,
      receiverName: json['receiverName'] as String,
      receiverType: json['receiverType'] as String,
      donationTitle: json['donationTitle'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$ChatConversationToJson(ChatConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'donationId': instance.donationId,
      'donorId': instance.donorId,
      'donorName': instance.donorName,
      'receiverId': instance.receiverId,
      'receiverName': instance.receiverName,
      'receiverType': instance.receiverType,
      'donationTitle': instance.donationTitle,
      'messages': instance.messages,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'isActive': instance.isActive,
    };
