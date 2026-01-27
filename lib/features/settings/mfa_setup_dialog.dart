import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/services/log_service.dart';

class MfaSetupDialog extends ConsumerStatefulWidget {
  const MfaSetupDialog({super.key});

  @override
  ConsumerState<MfaSetupDialog> createState() => _MfaSetupDialogState();
}

class _MfaSetupDialogState extends ConsumerState<MfaSetupDialog> {
  String? _qrUri;
  String? _factorId;
  final _codeController = TextEditingController();
  bool _isLoading = true;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _enroll();
  }

  Future<void> _enroll() async {
    try {
      final AuthMFAEnrollResponse response = await ref.read(supabaseServiceProvider).enrollMFA();
      setState(() {
        _qrUri = response.totp?.uri;
        _factorId = response.id;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('MFA Enrollment failed: $e');
      setState(() {
        _error = 'Failed to initialize MFA: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verify() async {
    if (_factorId == null || _codeController.text.length < 6) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      await ref.read(supabaseServiceProvider).verifyMFA(
        factorId: _factorId!,
        code: _codeController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppLogger.error('MFA Verification failed: $e');
      setState(() {
        _error = 'Invalid code. Please try again.';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup 2FA'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading 
          ? const Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Generating QR code...')])
          : _error != null
            ? Text(_error!, style: const TextStyle(color: AppColors.danger))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Scan this QR code in your Authenticator app (Google Authenticator, Authy, etc.)', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (_qrUri != null)
                    Center(
                      child: QrImageView(
                        data: _qrUri!,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text('Enter the 6-digit code from the app:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: '000000',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (val.length == 6) _verify();
                    },
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (!_isLoading && _error == null)
          ElevatedButton(
            onPressed: _isVerifying ? null : _verify,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: _isVerifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify & Activate'),
          ),
      ],
    );
  }
}
