import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client;

  ChatService(this._client);

  // Stream messages for a specific circle
  Stream<List<Map<String, dynamic>>> getMessagesStream(String circleId) {
    return _client
        .from('circle_messages')
        .stream(primaryKey: ['id'])
        .eq('circle_id', circleId)
        .order('created_at')
        .map((data) => data);
  }

  // Send a message
  Future<void> sendMessage(String circleId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No user logged in');

    await _client.from('circle_messages').insert({
      'circle_id': circleId,
      'sender_id': userId,
      'content': content,
    });
  }
}

// Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(Supabase.instance.client);
});

// Stream provider for messages (family: circleId)
final circleMessagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, circleId) {
  final service = ref.watch(chatServiceProvider);
  return service.getMessagesStream(circleId);
});
