import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  // Onboarding
  static const int totalOnboardingScreens = 10;

  // Screen indices for dot indicators
  static const int onboardingWelcomeScreenIndex = 0;
  static const int genderSelectionScreenIndex = 1;
  static const int activityLevelScreenIndex = 2;
  static const int experienceScreenIndex = 3;
  static const int weightInputScreenIndex = 4;
  static const int heightInputScreenIndex = 5;
  static const int dobInputScreenIndex = 6;
  static const int goalWeightScreenIndex = 7;
  static const int mealTimingScreenIndex = 8;
  static const int nutritionRecommendationScreenIndex = 9;
}

class AppConstants {
  // API keys
  static const String geminiApiKey = 'AIzaSyBzL0LJ7EsQbGxr--cFGKbsEd1xgG9VSS0';

  // Google Vision API keys for different platforms
  // Using platform-specific API keys as required by Google Cloud
  static const String googleVisionApiKeyAndroid = 'AIzaSyArQxIS8jzk2A-bE9lg5w6MEJcOqBgXaPo'; // Android-specific key
  static const String googleVisionApiKeyIOS = 'AIzaSyAvHx5n33oT4o_7KSy_x8JM0CIUD-fqr1I'; // iOS-specific key
  static const String googleVisionApiKeyWeb = 'AIzaSyAvHx5n33oT4o_7KSy_x8JM0CIUD-fqr1I'; // Web-specific key

  // Alternative API key format (without 'Bearer' prefix) - sometimes needed for certain API endpoints
  // This will be set dynamically based on platform in the getter
  static String get googleVisionApiKeyNoBearer {
    if (Platform.isAndroid) {
      return googleVisionApiKeyAndroid;
    } else if (Platform.isIOS) {
      return googleVisionApiKeyIOS;
    } else {
      return googleVisionApiKeyWeb;
    }
  }

  // Backup API key in case the primary one fails
  static const String backupVisionApiKey = 'AIzaSyAvHx5n33oT4o_7KSy_x8JM0CIUD-fqr1I';

  // Use this property to get the appropriate API key based on platform
  static String get googleVisionApiKey {
    String key;

    if (kIsWeb) {
      key = googleVisionApiKeyWeb;
    } else if (Platform.isAndroid) {
      key = googleVisionApiKeyAndroid;
    } else if (Platform.isIOS) {
      key = googleVisionApiKeyIOS;
    } else {
      // Fallback for other platforms
      key = googleVisionApiKeyAndroid;
    }

    // Validate the key - don't return placeholder values
    if (key.contains('YOUR_') || key.isEmpty) {
      // Return the Android key as fallback
      return googleVisionApiKeyAndroid;
    }

    return key;
  }

  // Get the API key without Bearer prefix (for certain API endpoints)
  static String get googleVisionApiKeyRaw {
    return googleVisionApiKeyNoBearer;
  }

  // Edamam API credentials
  static const String edamamAppId = '5550bc01';
  static const String edamamAppKey = '02e8631662d05c0121ae07bad91f767f';

  // App settings
  static const String appName = 'FoodAI';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered food tracking app';

  // Meal types
  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  // Default values
  static const int defaultCalorieGoal = 2000;
  static const int defaultProteinGoal = 150;
  static const int defaultCarbsGoal = 250;
  static const int defaultFatGoal = 70;
  static const int defaultWaterGoal = 8;

  // Time constants
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 2);

  // Sizes
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;
  static const double defaultButtonHeight = 48.0;
  static const double defaultCardElevation = 2.0;

  // Image processing
  static const int targetImageWidth = 800;
  static const int targetImageHeight = 800;
  static const int maxImageSizeBytes = 1024 * 1024; // 1MB
  static const int imageQuality = 85;
}

class AppColors {
  // Primary colors - keeping the mango theme
  static const Color primaryColor = Color(0xFFFF9800); // Mango color
  static const Color primaryColorLight = Color(0xFFFFBB50);
  static const Color primaryColorDark = Color(0xFFE68A00);
  static const Color primaryContainer = Color(0xFFFFE0B2); // Light orange for containers
  static const Color onPrimaryContainer = Color(0xFF7A4F01); // Dark text on primary container

  // Secondary colors - Material 3 style naming
  static const Color secondary = Color(0xFF4CAF50); // Green
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFD7F9D9);
  static const Color onSecondaryContainer = Color(0xFF002204);

  // Tertiary colors - Material 3 style naming
  static const Color tertiary = Color(0xFF2196F3); // Blue
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = Color(0xFFD1E9FF);
  static const Color onTertiaryContainer = Color(0xFF001D36);

  // Text colors - Material 3 style naming
  static const Color onPrimary = Colors.white; // White text on primary color
  static const Color onSurface = Color(0xFF212121); // Main text color
  static const Color onSurfaceVariant = Color(0xFF757575); // Secondary text color
  static const Color onSurfaceDisabled = Color(0xFFBDBDBD); // Disabled text color

  // Background colors - Material 3 style naming
  static const Color background = Color(0xFFFAFAFA);
  static const Color onBackground = Color(0xFF212121);
  static const Color surface = Colors.white;
  static const Color surfaceContainer = Color(0xFFF8F8F8);
  static const Color surfaceContainerLow = Color(0xFFFAFAFA);
  static const Color surfaceContainerHigh = Color(0xFFF0F0F0);

  // State colors
  static const Color error = Color(0xFFE53935);
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);

  // Outline colors - Material 3 style
  static const Color outline = Color(0xFFBDBDBD);
  static const Color outlineVariant = Color(0xFFE0E0E0);

  // Elevation colors
  static const Color shadow = Color(0x1A000000); // 10% black shadow
  static const Color scrim = Color(0x33000000); // 20% black shadow for modal overlays

  // Animation colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Material 3 state layer opacities
  static const double stateLayerOpacityHovered = 0.08;
  static const double stateLayerOpacityFocused = 0.12;
  static const double stateLayerOpacityPressed = 0.12;
  static const double stateLayerOpacityDragged = 0.16;
}
