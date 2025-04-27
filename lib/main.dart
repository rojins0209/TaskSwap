import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/screens/challenges/competitive_challenges_screen.dart';
import 'package:taskswap/screens/friends/friends_screen.dart';
import 'package:taskswap/screens/home_screen.dart';
import 'package:taskswap/screens/auth/login_screen.dart';
import 'package:taskswap/screens/auth/signup_screen.dart';
import 'package:taskswap/screens/profile/aura_share_screen.dart';
import 'package:taskswap/screens/profile/edit_profile_screen.dart';
import 'package:taskswap/screens/settings/data_recovery_screen.dart';
import 'package:taskswap/screens/tasks/enhanced_add_task_screen.dart';
import 'package:taskswap/services/analytics_service.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/providers/theme_provider.dart';
import 'package:taskswap/utils/edge_case_handler.dart';
import 'package:taskswap/utils/security_provider.dart';
import 'package:taskswap/widgets/app_logo.dart';
import 'package:taskswap/widgets/network_aware_app.dart';

// Global navigator key for accessing the navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize security provider to handle SSL/TLS updates
    await SecurityProvider.initialize();

    // Suppress security provider warnings in logs
    SecurityProvider.suppressWarnings();

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize Firestore settings with aggressive caching
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Initialize Analytics
    await AnalyticsService.instance.init();

    // Initialize services
    final userService = UserService();
    final taskService = TaskService();

    // Set up connectivity monitoring
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // When connectivity is restored, process any pending operations
        debugPrint('Connectivity restored, processing pending operations');
        taskService.processPendingOperations();
      }
    });

    // Prefetch data if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('Prefetching data for user: ${currentUser.uid}');

      // Prefetch user data
      userService.prefetchUserData(currentUser.uid);

      // Prefetch leaderboard data (10 users, all time)
      userService.prefetchLeaderboardData(10);

      // Prefetch friends data
      userService.getFriendsList(currentUser.uid).then((friends) {
        for (final friend in friends) {
          userService.prefetchUserData(friend.id);
        }
      });

      // Process any pending operations from previous sessions
      taskService.processPendingOperations();

      // Handle edge cases
      EdgeCaseHandler.instance.runAllEdgeCaseHandlers(currentUser.uid).then((_) {
        debugPrint('Edge case handlers completed');
      }).catchError((error) {
        debugPrint('Error running edge case handlers: $error');
      });
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Show error UI instead of crashing
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                const AppLogo(
                  size: 80,
                  showText: true,
                ),
                const SizedBox(height: 32),
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Oops! Something went wrong.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    try {
      final themeMode = await _themeProvider.getThemeMode();
      final useDynamicColors = await _themeProvider.getUseDynamicColors();
      if (mounted) {
        setState(() {
          _themeMode = themeMode;
          _useDynamicColors = useDynamicColors;
        });
      }
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
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

          // Wrap with Directionality widget to fix the "No Directionality widget found" error
          return Directionality(
            // Set text direction to left-to-right
            textDirection: TextDirection.ltr,
            child: NetworkAwareApp(
              onConnectivityChanged: (isConnected) {
                debugPrint('Connectivity changed: $isConnected');

                // Process pending operations when connectivity is restored
                if (isConnected) {
                  final taskService = TaskService();
                  taskService.processPendingOperations();
                }
              },
              child: MaterialApp(
                navigatorKey: navigatorKey, // Add global navigator key
                title: 'TaskSwap',
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: _themeMode,
                home: const AuthenticationWrapper(),
                debugShowCheckedModeBanner: false,
                navigatorObservers: [
                  AnalyticsService.instance.getObserver(),
                ],
                onGenerateRoute: (settings) {
                  debugPrint('Generating route for: ${settings.name}');
                  switch (settings.name) {
                    case '/data_recovery':
                      return MaterialPageRoute(
                        builder: (context) => const DataRecoveryScreen(),
                        settings: settings,
                      );
                    case '/competitive-challenges':
                      return MaterialPageRoute(
                        builder: (context) => const CompetitiveChallengesScreen(),
                        settings: settings,
                      );
                    case '/add-task':
                      return MaterialPageRoute(
                        builder: (context) => const EnhancedAddTaskScreen(),
                        settings: settings,
                      );
                    case '/friends':
                      return MaterialPageRoute(
                        builder: (context) => const FriendsScreen(),
                        settings: settings,
                      );
                    case '/aura-share':
                      final args = settings.arguments as UserModel?;
                      return MaterialPageRoute(
                        builder: (context) => AuraShareScreen(userProfile: args),
                        settings: settings,
                      );
                    case '/edit-profile':
                      final args = settings.arguments as UserModel;
                      return MaterialPageRoute(
                        builder: (context) => EditProfileScreen(userProfile: args),
                        settings: settings,
                      );
                    default:
                      return null;
                  }
                },
                onUnknownRoute: (settings) {
                  debugPrint('Unknown route: ${settings.name}');
                  return MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: Center(
                        child: Text('Route not found: ${settings.name}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  const AppLogo(
                    size: 100,
                    showText: true,
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  const AppLogo(
                    size: 80,
                    showText: true,
                  ),
                  const SizedBox(height: 32),
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const AuthenticationWrapper(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        return LoginScreen(
          showSignUpScreen: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SignUpScreen(
                  showLoginScreen: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
