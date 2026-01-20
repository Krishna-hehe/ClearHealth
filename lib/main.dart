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
import 'core/services/session_timeout_manager.dart';

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
          : SessionTimeoutManager(
              duration: const Duration(minutes: 5),
              onTimeout: () {
                // When timeout happens, we force the app into a locked state if biometrics are enabled,
                // or just log them out.
                // For better UX, let's prompt the SecurityWrapper to lock.
                // We'll use a GlobalKey or a Riverpod state to trigger this.
                // For now, let's just use a simple approach: invalidate auth or show lock screen.
                // Let's use the lock screen approach by ensuring SecurityWrapper is effectively reset.
                // However, SecurityWrapper is stateful.
                // We will use a provider to trigger lock.
                ref.read(appLockProvider.notifier).state = true;
              },
              child: const SecurityWrapper(
                child: MainLayout(child: SizedBox()),
              ),
            ),
    );
  }
}

// Add a simple provider for app lock state
final appLockProvider = StateProvider<bool>((ref) => false);

class SecurityWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

  @override
  ConsumerState<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends ConsumerState<SecurityWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSecurity();
    _secureScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _secureScreen() async {
    // Only works on mobile (Android/iOS)
    /* 
    // Commented out as package import needs to be conditional or handled for web
    // You would import flutter_windowmanager normally
    try {
        if (!kIsWeb) {
           await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        }
    } catch (_) {} 
    */
    // Since we can't easily valid conditional imports in this snippet without more setup, 
    // we will start with the logic structure.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
       // App went to background - blur or lock could happen here if strict
    }
  }

  Future<void> _checkSecurity() async {
    final enabled = await BiometricService().isEnabled();
    
    // If biometrics NOT enabled, we don't force lock, but we obey the manual lock provider
    if (!enabled) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    // Determine initial lock state
    // For now, assume locked on startup if biometrics enabled
    ref.read(appLockProvider.notifier).state = true;
    
    if (mounted) setState(() { _isLoading = false; });
    _authenticate(); 
  }

  Future<void> _authenticate() async {
    final success = await BiometricService().authenticate();
    if (success) {
      ref.read(appLockProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isLocked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.secondary),
              const SizedBox(height: 24),
              const Text('Session Locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('LabSense secured for your privacy', style: TextStyle(color: AppColors.secondary)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint),
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                label: const Text('Unlock'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Logout option in case they can't unlock
                   Supabase.instance.client.auth.signOut();
                   // Reset lock state so next login isn't weirdly locked immediately unless desired
                   ref.read(appLockProvider.notifier).state = false;
                },
                child: const Text('Log Out'),
              )
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
