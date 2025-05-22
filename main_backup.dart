import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/navigation_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'utils/routes.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/food_analysis_screen.dart';
import 'screens/camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDarkMode = await ThemeService.isDarkMode();
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  // Define our custom color scheme based on Material 3 Expressive
  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF9800), // Mango color
    brightness: Brightness.light,
    primary: const Color(0xFFFF9800), // Mango orange
    secondary: const Color(0xFFFF9800), // Changed to orange to match primary
    tertiary: const Color(0xFFFFB74D), // Lighter orange
    surface: Colors.white,
    background: Colors.white,
    error: const Color(0xFFB00020),
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF9800), // Mango color
    brightness: Brightness.dark,
    primary: const Color(0xFFFFB74D), // Light mango
    secondary: const Color(0xFFFFB74D), // Changed to orange to match primary
    tertiary: const Color(0xFFFFA726), // Another orange shade
    surface: const Color(0xFF121212),
    background: const Color(0xFF121212),
    error: const Color(0xFFCF6679),
  );

  @override
  Widget build(BuildContext context) {
    // Disable dynamic colors to ensure consistent orange theme across all platforms
    return MaterialApp(
      title: 'FoodAI',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        colorScheme: _defaultLightColorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: _defaultDarkColorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
        Routes.camera: (context) => CameraScreen(
          mealType: ModalRoute.of(context)?.settings.arguments as String?,
        ),
        Routes.foodAnalysis: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return FoodAnalysisScreen(
            imageFile: args?['imageFile'] as File?,
            mealType: args?['mealType'] as String?,
          );
        },
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
          final mealType = settings.arguments as String?;
          page = CameraScreen(mealType: mealType);
        } else if (settings.name == Routes.foodAnalysis) {
          final args = settings.arguments as Map<String, dynamic>?;
          page = FoodAnalysisScreen(
            imageFile: args?['imageFile'] as File?,
            mealType: args?['mealType'] as String?,
          );
        } else {
          return null;
        }

        // Use a custom page route for smoother transitions
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
