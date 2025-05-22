import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class NavigationHelper {
  static void navigateToHomeScreen(BuildContext context) {
    // Remove all routes and navigate to home screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }
}
