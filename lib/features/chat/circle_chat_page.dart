import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/services/chat_service.dart';
import '../../core/providers.dart'; // Ensure this provides authServiceProvider

class CircleChatPage extends ConsumerStatefulWidget {
  final String circleId;
  final String circleName;

  const CircleChatPage({
    super.key, 
    required this.circleId,
    required this.circleName,
  });

  @override
  ConsumerState<CircleChatPage> createState() => _CircleChatPageState();
}

class _CircleChatPageState extends ConsumerState<CircleChatPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  void _sendMessage() async {
    final content = _messageCtrl.text.trim();
    if (content.isEmpty) return;

    _messageCtrl.clear();
    try {
      await ref.read(chatServiceProvider).sendMessage(widget.circleId, content);
      // Auto scroll handled by connection, but we can jump to bottom
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(circleMessagesProvider(widget.circleId));
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.circleName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1), 
          child: Container(color: AppColors.border, height: 1)
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                 if (messages.isEmpty) {
                   return const Center(
                     child: Text('No messages yet. Say hello! 👋', style: TextStyle(color: AppColors.secondary)),
                   );
                 }
                 
                 // Auto-scroll on new data? A simple way is to build list reverse, or use a key
                 // For now, standard ListView builder
                 
                 return ListView.builder(
                   controller: _scrollCtrl,
                   padding: const EdgeInsets.all(16),
                   itemCount: messages.length,
                   itemBuilder: (context, index) {
                     final msg = messages[index];
                     final isMe = msg['sender_id'] == currentUser?.id;
                     return _buildMessageBubble(msg, isMe);
                   },
                 );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(
          msg['content'] ?? '',
          style: TextStyle(color: isMe ? Colors.white : AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
               controller: _messageCtrl,
               decoration: InputDecoration(
                 hintText: 'Type a message...',
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(24),
                   borderSide: BorderSide.none,
                 ),
                 filled: true,
                 fillColor: const Color(0xFFF9FAFB),
                 contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
               ),
               onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
