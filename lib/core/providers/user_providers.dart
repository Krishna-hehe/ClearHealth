import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/user_repository.dart';
import '../cache_service.dart';

import '../models.dart';
import '../repositories/medication_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    ref.watch(supabaseServiceProvider),
    ref.watch(storageServiceProvider),
    CacheService(),
  );
});

// Phase 3: List of all family profiles
final userProfilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  return await ref.watch(userRepositoryProvider).getProfiles();
});

// Phase 3: Tracks which profile is currently selected for viewing
final selectedProfileIdProvider = StateProvider<String?>((ref) => null);

// Phase 3: The actual selected UserProfile object
final selectedProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  final profilesAsync = ref.watch(userProfilesProvider);
  final selectedId = ref.watch(selectedProfileIdProvider);

  return profilesAsync.whenData((profiles) {
    if (profiles.isEmpty) return null;
    if (selectedId == null) return profiles.first; // Default to first (Self)
    return profiles.firstWhere(
      (p) => p.id == selectedId,
      orElse: () => profiles.first,
    );
  });
});

// Legacy support: Maps selected profile back to Map for existing widgets
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final profileAsync = ref.watch(selectedProfileProvider);
  return profileAsync.value?.toJson();
});

final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(userRepositoryProvider).getProfileStream();
});

final notificationsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(userRepositoryProvider).getNotificationsStream();
});
final activePrescriptionsCountProvider = FutureProvider<int>((ref) async {
  return await ref.watch(userRepositoryProvider).getActivePrescriptionsCount();
});

final prescriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await ref.watch(userRepositoryProvider).getPrescriptions();
});



final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final profile = ref.watch(selectedProfileProvider).value;
  // If no profile selected (e.g. still loading), return empty or fetch for user default
  // Ideally rely on selectedProfileProvider
  return await ref
      .read(medicationRepositoryProvider)
      .getMedications(profileId: profile?.id);
});
