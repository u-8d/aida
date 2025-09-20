import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/donation.dart';

class AiChatService {
  static String get _apiKey => ApiConfig.geminiApiKey;
  static String get _baseUrl => ApiConfig.geminiBaseUrl;

  // Generate AI receiver names for prototyping
  static List<String> _aiReceiverNames = [
    'Priya Sharma',
    'Rajesh Kumar', 
    'Anita Devi',
    'Vikram Singh',
    'Sunita Patel',
    'Ravi Gupta',
    'Meera Joshi',
    'Suresh Reddy',
    'Kavita Mehta',
    'Arjun Nair'
  ];

  static String getRandomAiReceiverName() {
    final random = DateTime.now().millisecondsSinceEpoch % _aiReceiverNames.length;
    return _aiReceiverNames[random];
  }

  static Future<String> generateInitialMessage(Donation donation, String receiverName) async {
    if (!ApiConfig.isGeminiConfigured) {
      // Fallback message for demo in Hindi
      return "हैलो! मैंने आपका ${donation.itemName} देखा है और मुझे इसकी जरूरत है। क्या आप बता सकते हैं कि यह कैसी हालत में है?";
    }

    try {
      final prompt = """
You are ${receiverName}, a Hindi-speaking person in India who just saw a donation posting. You are writing the first message to the donor in Hindi.

Donation Details:
- Item: ${donation.itemName}
- Description: ${donation.description}
- Tags: ${donation.tags.join(', ')}
- Location: ${donation.city}

Write a short, natural first message in Hindi expressing genuine interest in the donation. Be polite, friendly and explain briefly why you need it. Keep it conversational like how people actually text in India - mix of Hindi and some English words is fine. Keep it under 2 lines.

Write ONLY the message text in Hindi, nothing else.
""";

      final response = await _makeGeminiRequest(prompt);
      return response.isNotEmpty ? response : "हैलो! मैंने आपका ${donation.itemName} देखा है और मुझे इसकी जरूरत है। क्या आप बता सकते हैं कि यह कैसी हालत में है?";
    } catch (e) {
      if (kDebugMode) {
        print('Error generating initial message: $e');
      }
      return "हैलो! मैंने आपका ${donation.itemName} देखा है और मुझे इसकी जरूरत है। क्या आप बता सकते हैं कि यह कैसी हालत में है?";
    }
  }

  static Future<String> generateReply(
    List<ChatMessage> conversationHistory, 
    String receiverName,
    Donation donation,
  ) async {
    if (!ApiConfig.isGeminiConfigured) {
      // Simple fallback responses for demo in Hindi
      final lastMessage = conversationHistory.last.message.toLowerCase();
      if (lastMessage.contains('कब') || lastMessage.contains('when') || lastMessage.contains('time')) {
        return "मैं flexible हूं। आपको कब सुविधा होगी?";
      } else if (lastMessage.contains('कहां') || lastMessage.contains('where') || lastMessage.contains('location')) {
        return "मैं आपके पास आ सकता हूं। कहां मिलना ठीक रहेगा?";
      } else if (lastMessage.contains('condition') || lastMessage.contains('हालत')) {
        return "बहुत अच्छा! धन्यवाद! आपका donation काम आएगा।";
      } else {
        return "बहुत-बहुत धन्यवाद भाई! कब pickup हो सकता है?";
      }
    }

    try {
      // Build conversation context
      String conversationContext = "Previous conversation:\n";
      for (var message in conversationHistory) {
        final role = message.senderId == receiverName ? "You (${receiverName})" : "Donor (${message.senderName})";
        conversationContext += "$role: ${message.message}\n";
      }

      final prompt = """
You are ${receiverName}, a Hindi-speaking person who needs the donated item. You're having a natural conversation with the donor in Hindi.

Donation Details:
- Item: ${donation.itemName}
- Description: ${donation.description}
- Tags: ${donation.tags.join(', ')}
- Location: ${donation.city}

$conversationContext

The donor just sent: "${conversationHistory.last.message}"

Respond naturally as ${receiverName} in Hindi. Be grateful, helpful, and human-like. Keep responses short (1-2 lines max). Answer their questions, ask relevant follow-up questions, and work towards arranging pickup/delivery. Use natural Indian texting style - mix Hindi with some English words is fine.

Write ONLY your response message in Hindi, nothing else.
""";

      final response = await _makeGeminiRequest(prompt);
      return response.isNotEmpty ? response : "धन्यवाद! मुझे यह donation बहुत काम आएगा।";
    } catch (e) {
      if (kDebugMode) {
        print('Error generating AI reply: $e');
      }
      return "धन्यवाद! मुझे यह donation बहुत काम आएगा।";
    }
  }

  static Future<String> _makeGeminiRequest(String prompt) async {
    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.8, // Higher temperature for more natural conversation
          'maxOutputTokens': 80, // Reduced for shorter responses (1-2 lines)
          'topP': 0.9,
          'topK': 40,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          return responseData['candidates'][0]['content']['parts'][0]['text'] ?? '';
        }
      } else {
        if (kDebugMode) {
          print('Gemini API error: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error making Gemini request: $e');
      }
    }
    
    return '';
  }

  static Future<ChatConversation> createConversationForDonation(Donation donation) async {
    final receiverName = getRandomAiReceiverName();
    final receiverId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final conversationId = 'chat_${donation.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Generate initial AI message
    final initialMessage = await generateInitialMessage(donation, receiverName);
    
    // Create chat message
    final chatMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: conversationId,
      senderId: receiverId,
      senderName: receiverName,
      message: initialMessage,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    
    // Create conversation
    final conversation = ChatConversation(
      id: conversationId,
      donationId: donation.id,
      donorId: donation.donorId,
      donorName: 'Donor', // This should be passed from the actual donor name
      receiverId: receiverId,
      receiverName: receiverName,
      receiverType: 'ai',
      donationTitle: donation.itemName,
      messages: [chatMessage],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      isActive: true,
    );
    
    return conversation;
  }
}
