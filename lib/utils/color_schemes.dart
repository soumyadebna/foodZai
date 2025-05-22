import 'package:flutter/material.dart';

// Light color scheme based on Material 3 with mango accent
final lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFFFF9800), // Mango orange
  onPrimary: Colors.white,
  primaryContainer: const Color(0xFFFFE0B2), // Light orange
  onPrimaryContainer: const Color(0xFF7A4F01),
  secondary: const Color(0xFF4CAF50), // Green
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFD7F9D9),
  onSecondaryContainer: const Color(0xFF002204),
  tertiary: const Color(0xFF2196F3), // Blue
  onTertiary: Colors.white,
  tertiaryContainer: const Color(0xFFD1E9FF),
  onTertiaryContainer: const Color(0xFF001D36),
  error: const Color(0xFFE53935),
  onError: Colors.white,
  errorContainer: const Color(0xFFFFDAD6),
  onErrorContainer: const Color(0xFF410002),
  background: const Color(0xFFFAFAFA),
  onBackground: const Color(0xFF212121),
  surface: Colors.white,
  onSurface: const Color(0xFF212121),
  surfaceVariant: const Color(0xFFF5F5F5),
  onSurfaceVariant: const Color(0xFF757575),
  outline: const Color(0xFFBDBDBD),
  outlineVariant: const Color(0xFFE0E0E0),
  shadow: const Color(0x1A000000),
  scrim: const Color(0x33000000),
  inverseSurface: const Color(0xFF303030),
  onInverseSurface: Colors.white,
  inversePrimary: const Color(0xFFFFB74D),
  surfaceTint: const Color(0xFFFF9800),
  // Additional Material 3 surface containers
  surfaceContainer: const Color(0xFFF8F8F8),
  surfaceContainerLow: const Color(0xFFFAFAFA),
  surfaceContainerLowest: const Color(0xFFFFFFFF),
  surfaceContainerHigh: const Color(0xFFF0F0F0),
  surfaceContainerHighest: const Color(0xFFE6E6E6),
);

// Dark color scheme based on Material 3 with mango accent
final darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xFFFFB74D), // Lighter mango orange for dark theme
  onPrimary: const Color(0xFF3E2800),
  primaryContainer: const Color(0xFF5A3C00),
  onPrimaryContainer: const Color(0xFFFFDDB3),
  secondary: const Color(0xFF81C784), // Lighter green for dark theme
  onSecondary: const Color(0xFF003A07),
  secondaryContainer: const Color(0xFF005310),
  onSecondaryContainer: const Color(0xFFA8F5A3),
  tertiary: const Color(0xFF64B5F6), // Lighter blue for dark theme
  onTertiary: const Color(0xFF003258),
  tertiaryContainer: const Color(0xFF004A7C),
  onTertiaryContainer: const Color(0xFFD1E4FF),
  error: const Color(0xFFEF9A9A),
  onError: const Color(0xFF690005),
  errorContainer: const Color(0xFF930009),
  onErrorContainer: const Color(0xFFFFDAD6),
  background: const Color(0xFF121212),
  onBackground: Colors.white,
  surface: const Color(0xFF1E1E1E),
  onSurface: Colors.white,
  surfaceVariant: const Color(0xFF303030),
  onSurfaceVariant: const Color(0xFFBDBDBD),
  outline: const Color(0xFF757575),
  outlineVariant: const Color(0xFF424242),
  shadow: const Color(0x33000000),
  scrim: const Color(0x66000000),
  inverseSurface: Colors.white,
  onInverseSurface: const Color(0xFF212121),
  inversePrimary: const Color(0xFFFF9800),
  surfaceTint: const Color(0xFFFFB74D),
  // Additional Material 3 surface containers
  surfaceContainer: const Color(0xFF252525),
  surfaceContainerLow: const Color(0xFF1E1E1E),
  surfaceContainerLowest: const Color(0xFF121212),
  surfaceContainerHigh: const Color(0xFF2C2C2C),
  surfaceContainerHighest: const Color(0xFF333333),
);
