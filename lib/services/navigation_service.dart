import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  static Future<dynamic> navigateToReplacement(String routeName) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName);
  }

  static Future<dynamic> navigateToAndRemoveUntil(String routeName) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
    );
  }

  static void goBack() {
    return navigatorKey.currentState!.pop();
  }

  static Future<dynamic> navigateToRoute(Route route) {
    return navigatorKey.currentState!.push(route);
  }

  static Future<dynamic> navigateToRouteReplacement(Route route) {
    return navigatorKey.currentState!.pushReplacement(route);
  }

  static Future<dynamic> navigateToRouteAndRemoveUntil(Route route) {
    return navigatorKey.currentState!.pushAndRemoveUntil(
      route,
      (Route<dynamic> route) => false,
    );
  }
}
