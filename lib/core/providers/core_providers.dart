import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import '../ai_service.dart';
import '../storage_service.dart';
import '../vector_service.dart';
import '../app_config.dart';

// --- Core Infrastructure Providers ---

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

final vectorServiceProvider = Provider<VectorService>((ref) {
  final client = ref.read(supabaseClientProvider);
  return VectorService(client, apiKey: AppConfig.geminiApiKey);
});

final aiServiceProvider = Provider<AiService>((ref) {
  final vectorService = ref.read(vectorServiceProvider);
  return AiService(
    apiKey: AppConfig.geminiApiKey,
    chatApiKey: AppConfig.labSenseChatApiKey,
    vectorService: vectorService
  );
});
