import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

enum AppState {
  splash,
  onboarding,
  home,
}

class FoodAIApp extends StatefulWidget {
  const FoodAIApp({Key? key}) : super(key: key);

  @override
  State<FoodAIApp> createState() => _FoodAIAppState();
}

class _FoodAIAppState extends State<FoodAIApp> {
  AppState _appState = AppState.splash;

  // Define our custom color scheme based on Material 3 Expressive
  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF9800), // Mango color
    brightness: Brightness.light,
    primary: const Color(0xFFFF9800),
    secondary: const Color(0xFF4CAF50),
    tertiary: const Color(0xFF8BC34A),
    surface: Colors.white,
    background: Colors.white,
    error: const Color(0xFFB00020),
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF9800), // Mango color
    brightness: Brightness.dark,
    primary: const Color(0xFFFFB74D),
    secondary: const Color(0xFF81C784),
    tertiary: const Color(0xFFAED581),
    surface: const Color(0xFF121212),
    background: const Color(0xFF121212),
    error: const Color(0xFFCF6679),
  );

  void _navigateToOnboarding() {
    setState(() {
      _appState = AppState.onboarding;
    });
  }

  void _navigateToHome() {
    setState(() {
      _appState = AppState.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'FoodAI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightDynamic ?? _defaultLightColorScheme,
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? _defaultDarkColorScheme,
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          home: _buildCurrentScreen(),
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (_appState) {
      case AppState.splash:
        return SplashScreen(
          onInitializationComplete: _navigateToOnboarding,
        );
      case AppState.onboarding:
        return OnboardingScreen(
          onComplete: _navigateToHome,
        );
      case AppState.home:
        return const HomeScreen();
    }
  }
}
