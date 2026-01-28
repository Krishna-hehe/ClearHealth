import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
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
import 'core/services/log_service.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:flutter/foundation.dart';
import 'features/splash/splash_page.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    // Start the app immediately with a loading state
    runApp(const ProviderScope(child: AppEntryPoint()));
  }, (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    AppLogger.error('🔴 Uncaught error in main zone: $error', stackTrace: stack);
  });
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isInitialized = false;
  String _status = 'Initializing...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // 1. Load Env
      if (mounted) setState(() => _status = 'Loading configuration...');
      try {
        await dotenv.load(fileName: ".env");
        AppLogger.info('✅ Environment loaded');
      } catch (e) {
        AppLogger.error('❌ Failed to load .env: $e', containsPII: false);
        // Continue anyway as secrets might be optional or handled elsewhere in some builds
      }

      // 2. Initialize Sentry
      final sentryDsn = dotenv.env['SENTRY_DSN'];
      if (sentryDsn != null && sentryDsn.isNotEmpty) {
        await SentryFlutter.init((options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 1.0;
          options.profilesSampleRate = 1.0;
        });
      }

      // 3. Initialize Supabase
      if (mounted) setState(() => _status = 'Connecting to services...');
      try {
        AppLogger.info('🔌 Initializing Supabase...');
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        AppLogger.info('✅ Supabase initialized');
      } catch (e) {
        throw Exception('Failed to connect to backend: $e');
      }

      // 4. Initialize Local Services
      if (mounted) setState(() => _status = 'Starting local services...');
      
      // Run these in parallel to speed up
      await Future.wait([
        _initNotifications(),
        _initCache(),
      ]);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to initialize app', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService().init();
      debugPrint('✅ Notifications initialized');
    } catch (e) {
      debugPrint('⚠️ Notification init failed: $e');
      // Don't block app start for this
    }
  }

  Future<void> _initCache() async {
    try {
      await CacheService().init();
      debugPrint('✅ Cache initialized');
    } catch (e) {
      debugPrint('⚠️ Cache init failed: $e');
      // Don't block app start for this
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _initApp();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashPage(statusMessage: _status),
      );
    }

    return const LabSenseApp();
  }
}


class LabSenseApp extends ConsumerWidget {
  const LabSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🏗️ LabSenseApp: Building...');
    final currentUser = ref.watch(currentUserProvider);
    print('👤 LabSenseApp: Current User: ${currentUser?.email}');
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
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('Failed to set secure flags: $e');
    }
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
