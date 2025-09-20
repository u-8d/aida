// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  chatId: json['chatId'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  message: json['message'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatId': instance.chatId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$MessageTypeEnumMap[instance.type]!,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.system: 'system',
};
