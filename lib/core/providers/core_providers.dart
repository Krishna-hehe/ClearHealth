import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import '../ai_service.dart';
import '../storage_service.dart';
import '../vector_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/sync_service.dart';
import '../app_config.dart';
import '../services/input_validation_service.dart';
import '../services/rate_limiter_service.dart';
import '../cache_service.dart';

// --- Core Infrastructure Providers ---

final inputValidationServiceProvider = Provider<InputValidationService>((ref) {
  return InputValidationService();
});

final rateLimiterProvider = Provider<RateLimiterService>((ref) {
  return RateLimiterService();
});

final syncBoxProvider = Provider<Box>((ref) {
  return Hive.box('sync_queue'); // Init handled in main or CacheService
});

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final box = ref.watch(syncBoxProvider);
  return SyncService(box);
});

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
  // CacheService is singleton, can instantiate directly or via provider if we had one
  // Assuming singleton usage as seen in other files
  return AiService(
    apiKey: AppConfig.geminiApiKey,
    chatApiKey: AppConfig.labSenseChatApiKey,
    vectorService: vectorService,
    cacheService: CacheService(),
  );
});
