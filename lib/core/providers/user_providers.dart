import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/user_repository.dart';
import '../cache_service.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(supabaseServiceProvider), CacheService());
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await ref.watch(userRepositoryProvider).getProfile();
});

final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(userRepositoryProvider).getProfileStream();
});

final notificationsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(userRepositoryProvider).getNotificationsStream();
});
final activePrescriptionsCountProvider = FutureProvider<int>((ref) async {
  return await ref.watch(userRepositoryProvider).getActivePrescriptionsCount();
});

final prescriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.watch(userRepositoryProvider).getPrescriptions();
});

final healthCirclesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.watch(userRepositoryProvider).getHealthCircles();
});
