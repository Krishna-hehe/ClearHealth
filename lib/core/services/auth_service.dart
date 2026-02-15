import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_service.dart';

class AuthService {
  final SupabaseClient _client;
  final AuditService _auditService;

  AuthService(this._client, this._auditService);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      _auditService.log(
        AuditAction.loginSuccess,
        details: 'User $email signed in.',
      );
    }
    return response;
  }

  Future<AuthResponse> signUp(String email, String password, {String? firstName}) async {
    final Map<String, dynamic> data = {};
    if (firstName != null && firstName.isNotEmpty) {
      data['first_name'] = firstName;
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: data.isNotEmpty ? data : null, // Pass data only if not empty
    );
    if (response.user != null) {
      _auditService.log(
        AuditAction.signupSuccess,
        details: 'User $email signed up.',
      );
    }
    return response;
  }

  Future<AuthResponse> signInWithGoogle() async {
    // Placeholder for Google Sign-In
    _auditService.log(
      AuditAction.googleSignInAttempt,
      details: 'Google sign-in attempt.',
    );
    // In a real app, you would initiate the Google sign-in flow here
    // For now, we'll return a dummy AuthResponse or throw an unimplemented exception
    throw UnimplementedError('Google Sign-In is not yet implemented.');
  }

  Future<AuthResponse> signInWithApple() async {
    // Placeholder for Apple Sign-In
    _auditService.log(
      AuditAction.appleSignInAttempt,
      details: 'Apple sign-in attempt.',
    );
    // In a real app, you would initiate the Apple sign-in flow here
    // For now, we'll return a dummy AuthResponse or throw an unimplemented exception
    throw UnimplementedError('Apple Sign-In is not yet implemented.');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}