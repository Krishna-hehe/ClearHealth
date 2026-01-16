import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'widgets/main_layout.dart';
import 'core/biometric_service.dart';
import 'features/auth/login_page.dart';
import 'core/notification_service.dart';
import 'core/cache_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🚀 App Starting...');

    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ Environment loaded');
    } catch (e) {
      debugPrint('❌ Failed to load .env: $e');
    }

    try {
      debugPrint('🔌 Initializing Supabase...');
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      debugPrint('✅ Supabase initialized');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
    }

    try {
      await NotificationService().init();
      debugPrint('✅ Notifications initialized');
    } catch (e) {
      debugPrint('⚠️ Notification init failed: $e');
    }

    try {
      await CacheService().init();
      debugPrint('✅ Cache initialized');
    } catch (e) {
      debugPrint('⚠️ Cache init failed: $e');
    }

    runApp(
      const ProviderScope(
        child: LabSenseApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('🔴 Uncaught error in main zone: $error');
    debugPrint(stack.toString());
  });
}

class LabSenseApp extends ConsumerWidget {
  const LabSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
 
    return MaterialApp(
      title: 'LabSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: currentUser == null 
          ? const LoginPage() 
          : const MainLayout(child: SizedBox()),
    );
  }
}

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> {
  bool _isLocked = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    final enabled = await BiometricService().isEnabled();
    if (!enabled) {
      if (mounted) setState(() { _isLocked = false; _isLoading = false; });
      return;
    }

    if (mounted) setState(() { _isLoading = false; });
    _authenticate();
  }

  Future<void> _authenticate() async {
    final success = await BiometricService().authenticate();
    if (success) {
      if (mounted) setState(() { _isLocked = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLocked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.secondary),
              const SizedBox(height: 24),
              const Text('LabSense is Locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Unlock with Biometrics'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
