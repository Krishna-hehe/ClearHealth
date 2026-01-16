import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../core/navigation.dart';
import '../../core/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _agreeToTerms = false;
  bool _acknowledgeHipaa = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = ref.read(isSignUpModeProvider);
  }

  Future<void> _handleAuth() async {
    if (_isSignUp && (!_agreeToTerms || !_acknowledgeHipaa)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and HIPAA guidelines.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
        throw 'Please enter a valid email address.';
      }
      if (_passwordController.text.length < 6) {
        throw 'Password must be at least 6 characters.';
      }
      if (_isSignUp && _passwordController.text != _confirmPasswordController.text) {
        throw 'Passwords do not match.';
      }

      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        await authService.signUp(_emailController.text, _passwordController.text);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please check your email.')),
          );
          // Optional: Navigate to dashboard if auto-signin works, or stay here.
          // For now, let's assume they need to verify email, so we stay? 
          // Or maybe Supabase is set to auto-confirm. 
          // Let's try navigating to dashboard to feel "logged in".
          ref.read(navigationProvider.notifier).state = NavItem.dashboard;
        }
      } else {
        await authService.signIn(_emailController.text, _passwordController.text);
        if (mounted) {
           ref.read(navigationProvider.notifier).state = NavItem.dashboard;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      if (provider == 'Google') {
        await authService.signInWithGoogle();
      } else if (provider == 'Apple') {
        await authService.signInWithApple();
      }
      // Note: Redirect happens automatically for OAuth
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Social Login Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LabSense',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
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
                    _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                    style: const TextStyle(color: AppColors.secondary, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Sign in' : 'Sign up for free',
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
              const SizedBox(height: 48),
              Container(
                constraints: const BoxConstraints(maxWidth: 480),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      hint: _isSignUp ? 'Create a strong password' : 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    if (_isSignUp) ...[
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
                    if (!_isSignUp)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) => setState(() => _rememberMe = v!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Remember me', style: TextStyle(color: AppColors.secondary, fontSize: 14)),
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
                      )
                    else ...[
                      _buildCheckItem(
                        value: _agreeToTerms,
                        onChanged: (v) => setState(() => _agreeToTerms = v!),
                        label: 'I agree to the Terms of Service and Privacy Policy',
                      ),
                      const SizedBox(height: 12),
                      _buildCheckItem(
                        value: _acknowledgeHipaa,
                        onChanged: (v) => setState(() => _acknowledgeHipaa = v!),
                        label: 'I acknowledge that LabSense handles my health information in accordance with HIPAA guidelines',
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSignUp ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_isSignUp ? 'Create account' : 'Sign in', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                    if (!_isSignUp) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Or continue with', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: _buildSocialButton('Google', FontAwesomeIcons.google, () => _handleSocialAuth('Google'))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSocialButton('Apple', FontAwesomeIcons.apple, () => _handleSocialAuth('Apple'))),
                        ],
                      ),

                    ],
                  ],
                ),
              ),
              const SizedBox(height: 48),
              if (_isSignUp)
                Column(
                  children: [
                    const Text('Instant AI-powered explanations', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('HIPAA-compliant security', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                )

              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('By signing in, you agree to our ', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text('Terms of Service', style: TextStyle(color: Colors.grey[500], fontSize: 12, decoration: TextDecoration.underline)),
                    Text(' and ', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text('Privacy Policy', style: TextStyle(color: Colors.grey[500], fontSize: 12, decoration: TextDecoration.underline)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
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
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
            ),
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
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: _isLoading ? null : onPressed,
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

}
