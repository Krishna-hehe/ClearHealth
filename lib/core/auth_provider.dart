import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (state) => state.session?.user,
      loading: () => null,
      error: (err, stack) => null,
    );
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
