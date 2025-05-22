import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/navigation_service.dart';
import 'services/theme_mode_provider.dart';
import 'services/theme_service.dart';
import 'providers/nutrition_provider.dart';
import 'utils/routes.dart';
import 'utils/material3_theme.dart';
import 'utils/reset_app_data.dart';
import 'utils/m3_animations.dart';
import 'utils/m3_widgets.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/food_analysis_screen.dart';

// Global flag to skip loading user data - set to false to load user data
bool skipLoadingUserData = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Reset app data to fix any corrupted data issues while preserving user settings
  await resetAppData();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Only set onboarding_completed to false if it doesn't exist
  if (!prefs.containsKey('onboarding_completed')) {
    await prefs.setBool('onboarding_completed', false);
  }

  // Create and initialize the ThemeModeProvider
  final themeModeProvider = ThemeModeProvider();

  // Ensure the theme is loaded before the app starts
  final themeMode = await ThemeService.getThemeMode();
  await themeModeProvider.setThemeMode(themeMode);

  debugPrint('Initial theme mode: $themeMode');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeModeProvider>.value(value: themeModeProvider),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeModeProvider>(context);

    return MaterialApp(
      title: 'FoodAI',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: Material3Theme.lightTheme(),
      darkTheme: Material3Theme.darkTheme(),
      themeMode: themeProvider.themeMode,
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => SplashScreen(
          onInitializationComplete: () {
            setState(() {
              _showSplash = false;
            });
            // Navigation is handled in the splash screen
          },
        ),
        Routes.onboarding: (context) => const OnboardingScreen(),
        Routes.home: (context) => const HomeScreen(),
        Routes.camera: (context) => const CameraScreen(),
        Routes.foodAnalysis: (context) => const FoodAnalysisScreen(),
      },
      // Handle all routes with custom transitions
      onGenerateRoute: (settings) {
        Widget page;
        if (settings.name == Routes.home) {
          page = const HomeScreen();
        } else if (settings.name == Routes.onboarding) {
          page = const OnboardingScreen();
        } else if (settings.name == Routes.splash) {
          page = SplashScreen(
            onInitializationComplete: () {
              setState(() {
                _showSplash = false;
              });
              // Navigation is handled in the splash screen
            },
          );
        } else if (settings.name == Routes.camera) {
          // Extract meal type parameter if provided
          final args = settings.arguments;
          String? mealType;
          if (args is Map<String, dynamic> && args.containsKey('mealType')) {
            mealType = args['mealType'] as String;
          }
          page = CameraScreen(mealType: mealType);
        } else if (settings.name == Routes.foodAnalysis) {
          // Extract meal type parameter if provided
          final args = settings.arguments;
          String? mealType;
          if (args is Map<String, dynamic> && args.containsKey('mealType')) {
            mealType = args['mealType'] as String;
          }
          page = FoodAnalysisScreen(mealType: mealType);
        } else {
          return null;
        }

        // Use our Material 3 animation system for page transitions
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return M3Animations.pageTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          // Material 3 standard duration for page transitions
          transitionDuration: M3Animations.extraLong,
          reverseTransitionDuration: M3Animations.extraLong,
        );
      },
    );
  }
}
