import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  LocalAuthentication? _authInstance;
  
  LocalAuthentication get _auth {
    _authInstance ??= LocalAuthentication();
    return _authInstance!;
  }

  static const String _enabledKey = 'biometric_enabled';

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access LabSense',
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
    } catch (e) {
      debugPrint('Error setting biometric enabled: $e');
    }
  }
}
