import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_page_state.dart';
import 'auth_handler.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(loginPageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
              const Text(
                'Clear Health',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 32),
              _Header(isSignUp: pageState.isSignUp),
              const SizedBox(height: 48),
              GlassCard(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(40),
                  child: pageState.mfaChallengeFactorId != null
                      ? _MfaForm()
                      : _AuthForm(),
                ),
              ),
              const SizedBox(height: 48),
              _Footer(isSignUp: pageState.isSignUp),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final bool isSignUp;

  const _Header({required this.isSignUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          isSignUp ? 'Create your account' : 'Welcome back',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignUp
                  ? 'Already have an account? '
                  : "Don't have an account? ",
              style: const TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
            GestureDetector(
              onTap: () => ref.read(loginPageProvider.notifier).toggleSignUp(),
              child: Text(
                isSignUp ? 'Sign in' : 'Sign up for free',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthForm extends ConsumerWidget {
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(loginPageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pageState.isSignUp) ...[
          _buildInputField(
            label: 'First Name',
            controller: _firstNameController,
            hint: 'Your first name',
            icon: Icons.person_outline,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 24),
        ],
        _buildInputField(
          label: 'Email address',
          controller: _emailController,
          hint: 'you@example.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        _buildInputField(
          label: 'Password',
          controller: _passwordController,
          hint: pageState.isSignUp
              ? 'Create a strong password'
              : 'Enter your password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        if (pageState.isSignUp) ...[
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Confirm password',
            controller: _confirmPasswordController,
            hint: 'Confirm your password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
        ],
        const SizedBox(height: 20),
        if (!pageState.isSignUp) _RememberMeRow() else _TermsAndConditions(),
        const SizedBox(height: 32),
        _AuthButton(
          onPressed: () => ref
              .read(authHandlerProvider)
              .handleAuth(
                context,
                _emailController.text,
                _passwordController.text,
                _confirmPasswordController.text,
                firstName: _firstNameController.text,
              ),
        ),
        if (!pageState.isSignUp) ...[const SizedBox(height: 32), _SocialAuth()],
      ],
    );
  }
}

class _MfaForm extends ConsumerWidget {
  final _mfaController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(loginPageProvider);

    return Column(
      children: [
        const Text(
          'Two-Factor Authentication',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter the 6-digit code from your authenticator app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.secondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _mfaController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            if (val.length == 6) {
              ref
                  .read(authHandlerProvider)
                  .handleMfaVerify(context, _mfaController.text);
            }
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: pageState.isLoading
                ? null
                : () => ref
                      .read(authHandlerProvider)
                      .handleMfaVerify(context, _mfaController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: pageState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verify Code'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref
              .read(loginPageProvider.notifier)
              .setMfaChallengeFactorId(null),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}

class _RememberMeRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(loginPageProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: pageState.rememberMe,
                onChanged: (v) =>
                    ref.read(loginPageProvider.notifier).setRememberMe(v!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Remember me',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsAndConditions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(loginPageProvider);

    return Column(
      children: [
        _buildCheckItem(
          value: pageState.agreeToTerms,
          onChanged: (v) =>
              ref.read(loginPageProvider.notifier).setAgreeToTerms(v!),
          label: 'I agree to the Terms of Service and Privacy Policy',
        ),
        const SizedBox(height: 12),
        _buildCheckItem(
          value: pageState.acknowledgeHipaa,
          onChanged: (v) =>
              ref.read(loginPageProvider.notifier).setAcknowledgeHipaa(v!),
          label:
              'I acknowledge that Clear Health handles my health information in accordance with HIPAA guidelines',
        ),
      ],
    );
  }
}

class _AuthButton extends ConsumerWidget {
  final VoidCallback onPressed;

  const _AuthButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(loginPageProvider);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: pageState.isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: pageState.isSignUp
              ? const Color(0xFF9CA3AF)
              : const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: pageState.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pageState.isSignUp ? 'Create account' : 'Sign in',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}

class _SocialAuth extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'Google',
                FontAwesomeIcons.google,
                () => ref
                    .read(authHandlerProvider)
                    .handleSocialAuth(context, 'Google'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(
                'Apple',
                FontAwesomeIcons.apple,
                () => ref
                    .read(authHandlerProvider)
                    .handleSocialAuth(context, 'Apple'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isSignUp;

  const _Footer({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return isSignUp
        ? Column(
            children: [
              const Text(
                'Instant AI-powered explanations',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'HIPAA-compliant security',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'By signing in, you agree to our ',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
              Text(
                ' and ',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          );
  }
}

Widget _buildInputField({
  required String label,
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool obscureText = false,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
          ),
          errorMaxLines: 3,
        ),
      ),
    ],
  );
}

Widget _buildCheckItem({
  required bool value,
  required ValueChanged<bool?> onChanged,
  required String label,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 24,
        height: 24,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

Widget _buildSocialButton(String label, IconData icon, VoidCallback onPressed) {
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF111827)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
