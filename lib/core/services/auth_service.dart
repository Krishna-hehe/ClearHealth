import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'audit_service.dart';

class AuthService {
  final SupabaseClient _client;
  final AuditService? _auditService; // Optional for now to avoid breaking tests immediately

  AuthService(this._client, [this._auditService]);

  // Authentication
  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      _auditService?.log(AuditAction.login, details: 'User signed up', resourceId: response.user!.id);
    }
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    if (response.user != null) {
      _auditService?.log(AuditAction.login, details: 'User signed in', resourceId: response.user!.id);
    }
    return response;
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
    );
     // Note: OAuth callback handling needs to happen where the auth state change is listened to for full audit, 
     // but we can't easily hook it here without callback logic. 
     // Relies on onAuthStateChange listener elsewhere or just accepts simple sign-in logging.
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
    );
  }


  Future<void> signOut() async {
    final userId = _client.auth.currentUser?.id;
    await _client.auth.signOut();
    if (userId != null) {
      _auditService?.log(AuditAction.logout, details: 'User signed out', resourceId: userId);
    }
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
