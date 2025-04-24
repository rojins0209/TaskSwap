import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskswap/screens/auth/auth_screen.dart';
import 'package:taskswap/screens/home_screen.dart';
import 'package:taskswap/screens/onboarding/onboarding_screen.dart';
import 'package:taskswap/screens/settings/data_recovery_screen.dart';
import 'package:taskswap/screens/splash_screen.dart';
import 'package:taskswap/services/analytics_service.dart';
// Temporarily disabled
// import 'package:taskswap/services/notification_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/providers/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap Firebase initialization in a try-catch block
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase Core initialized successfully');

    // Disable analytics initialization due to platform issues
    debugPrint('Analytics service initialization skipped');

    // Temporarily disable notifications to avoid build issues
    // final notificationService = NotificationService();
    // await notificationService.initNotifications();
    debugPrint('Notifications temporarily disabled');
  } catch (e) {
    // Handle Firebase initialization error
    debugPrint('Error initializing Firebase: $e');
  }

  // Run the app regardless of Firebase initialization status
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColors = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
    _themeProvider.addListener(_themeListener);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_themeListener);
    super.dispose();
  }

  void _themeListener() {
    setState(() {
      _themeMode = _themeProvider.themeMode;
      _useDynamicColors = _themeProvider.useDynamicColors;
    });
  }

  Future<void> _loadThemePreferences() async {
    final themeMode = await _themeProvider.getThemeMode();
    final useDynamicColors = await _themeProvider.getUseDynamicColors();
    setState(() {
      _themeMode = themeMode;
      _useDynamicColors = useDynamicColors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _themeProvider,
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // Set the dynamic color scheme if available and enabled
          if (lightDynamic != null && _useDynamicColors) {
            AppTheme.setDynamicColorScheme(lightDynamic);
          } else {
            // Reset to default if dynamic colors are disabled
            AppTheme.setDynamicColorScheme(null);
          }

          return MaterialApp(
            title: 'TaskSwap',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: _themeMode,
            home: const AuthenticationWrapper(),
            debugShowCheckedModeBanner: false,
            // Add analytics observer for screen tracking
            navigatorObservers: [
              AnalyticsService.instance.getObserver(),
            ],
            routes: {
              '/data_recovery': (context) => const DataRecoveryScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _onboardingComplete = false;
  bool _checkingPrefs = true;
  bool _isInitialAuthCheck = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Add a small delay to ensure the login screen is visible
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (mounted) {
      setState(() {
        _onboardingComplete = onboardingComplete;
        _checkingPrefs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while checking preferences
    if (_checkingPrefs) {
      return const SplashScreen();
    }

    // Show onboarding for first-time users
    if (!_onboardingComplete) {
      return const OnboardingScreen();
    }

    // Check authentication status
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen on initial auth check
        if (snapshot.connectionState == ConnectionState.waiting && _isInitialAuthCheck) {
          return const SplashScreen();
        }

        // Update initial auth check flag
        if (_isInitialAuthCheck) {
          Future.microtask(() {
            setState(() {
              _isInitialAuthCheck = false;
            });
          });
        }

        // If the snapshot has user data, then they're already signed in
        if (snapshot.hasData) {
          return HomeScreen();
        }
        // If the snapshot has no data, show the authentication screen
        return const AuthScreen();
      },
    );
  }
}
