import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../services/ai_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final currentUser = context.read<AppState>().currentUser;
    if (currentUser == null) return;

    // Create user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.conversation.id,
      senderId: currentUser.id,
      senderName: currentUser.name,
      message: messageText,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    // Clear input and add message
    _messageController.clear();
    context.read<AppState>().addMessageToConversation(widget.conversation.id, userMessage);
    _scrollToBottom();

    // If talking to AI, generate response
    if (widget.conversation.receiverType == 'ai') {
      setState(() {
        _isAiTyping = true;
      });

      try {
        // Get donation for context
        final donation = context.read<AppState>().donations.firstWhere(
          (d) => d.id == widget.conversation.donationId,
        );

        // Get updated conversation with the new message
        final updatedConversation = context.read<AppState>()
            .getChatConversationById(widget.conversation.id);
        
        if (updatedConversation != null) {
          // Generate AI response
          final aiResponse = await AiChatService.generateReply(
            updatedConversation.messages,
            widget.conversation.receiverName,
            donation,
          );

          // Create AI message
          final aiMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chatId: widget.conversation.id,
            senderId: widget.conversation.receiverId,
            senderName: widget.conversation.receiverName,
            message: aiResponse,
            timestamp: DateTime.now(),
            type: MessageType.text,
          );

          // Add AI message
          if (mounted) {
            context.read<AppState>().addMessageToConversation(widget.conversation.id, aiMessage);
            _scrollToBottom();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message. Please try again.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAiTyping = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.conversation.receiverType == 'ai' 
                  ? Colors.blue.shade100 
                  : Colors.green.shade100,
              child: Icon(
                widget.conversation.receiverType == 'ai' 
                    ? Icons.smart_toy 
                    : Icons.person,
                size: 16,
                color: widget.conversation.receiverType == 'ai' 
                    ? Colors.blue.shade700 
                    : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.conversation.receiverName,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (widget.conversation.receiverType == 'ai')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    widget.conversation.donationTitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final conversation = appState.getChatConversationById(widget.conversation.id);
          if (conversation == null) {
            return const Center(child: Text('Conversation not found'));
          }

          return Column(
            children: [
              // Messages list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: conversation.messages.length + (_isAiTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == conversation.messages.length && _isAiTyping) {
                      // Typing indicator
                      return _buildTypingIndicator();
                    }

                    final message = conversation.messages[index];
                    final isCurrentUser = message.senderId == appState.currentUser?.id;
                    
                    return _buildMessageBubble(message, isCurrentUser);
                  },
                ),
              ),
              // Message input
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: widget.conversation.receiverType == 'ai' 
                  ? Colors.blue.shade100 
                  : Colors.green.shade100,
              child: Icon(
                widget.conversation.receiverType == 'ai' 
                    ? Icons.smart_toy 
                    : Icons.person,
                size: 12,
                color: widget.conversation.receiverType == 'ai' 
                    ? Colors.blue.shade700 
                    : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.person,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: widget.conversation.receiverType == 'ai' 
                ? Colors.blue.shade100 
                : Colors.green.shade100,
            child: Icon(
              widget.conversation.receiverType == 'ai' 
                  ? Icons.smart_toy 
                  : Icons.person,
              size: 12,
              color: widget.conversation.receiverType == 'ai' 
                  ? Colors.blue.shade700 
                  : Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
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
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: "donor_chat_send_fab",
            onPressed: _sendMessage,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
