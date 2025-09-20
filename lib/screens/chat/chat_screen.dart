import 'package:aida2/models/supabase_user.dart';
import 'package:aida2/providers/supabase_app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi there! Is there any help needed in the flood-affected areas?",
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      senderName: "Me",
    ),
    ChatMessage(
      text: "Hello! Yes, there's a flood relief center 2km away that urgently needs warm clothing.",
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      senderName: "AIDA Assistant",
    ),
    ChatMessage(
      text: "That's perfect! What sizes do they need most?",
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      senderName: "Me",
    ),
    ChatMessage(
      text: "They especially need children's winter clothes and adult medium/large sizes.",
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      senderName: "AIDA Assistant",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        final currentUser = appState.currentUser;

        return Scaffold(
          body: Column(
            children: [
              if (currentUser != null) _buildChatHeader(context, currentUser),
              // Chat messages list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              
              // Message input area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey.withOpacity(0.1),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: "chat_send_fab",
                      onPressed: _sendMessage,
                      mini: true,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatHeader(BuildContext context, SupabaseUser currentUser) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: const Icon(Icons.support_agent, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AIDA Assistant",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Online',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.support_agent, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: message.isMe ? const Radius.circular(4) : const Radius.circular(18),
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe 
                          ? Colors.white 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isMe 
                          ? Colors.white70 
                          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isMe) ...[
            const SizedBox(width: 8),
            Consumer<SupabaseAppState>(
              builder: (context, appState, child) {
                final currentUser = appState.currentUser;
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    currentUser?.name.isNotEmpty == true ? currentUser!.name[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text.trim(),
        isMe: true,
        timestamp: DateTime.now(),
        senderName: "Me",
      ));
    });

    _messageController.clear();

    // Simulate a response after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Thank you for your message! We'll get back to you soon.",
            isMe: false,
            timestamp: DateTime.now(),
            senderName: "AIDA Assistant",
          ));
        });
      }
    });
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String senderName;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.senderName,
  });
}
