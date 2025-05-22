import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class HomeLauncher {
  static void launchHomeScreen(BuildContext context) {
    // Remove all routes and navigate to home screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
        settings: const RouteSettings(name: '/home'),
      ),
      (route) => false,
    );
  }
}
