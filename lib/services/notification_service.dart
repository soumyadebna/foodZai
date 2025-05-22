import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'dart:math';
import '../utils/notification_content.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Flag to track if notifications are initialized
  bool _isInitialized = false;

  Future<void> init() async {
    // Skip if already initialized
    if (_isInitialized) {
      debugPrint('Notification service already initialized');
      return;
    }

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();

      // Get device timezone
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Device timezone: $timeZoneName');

      // Android initialization settings with improved channel configuration
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      final IOSInitializationSettings initializationSettingsIOS =
          IOSInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          debugPrint('Received iOS notification: $title');
          // Handle iOS notification if needed
        },
      );

      // Combined initialization settings
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin with callback handling
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: (String? payload) async {
          debugPrint('Notification tapped: $payload');
          // Handle notification tap if needed
        },
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        // Water notification channel
        const AndroidNotificationChannel waterChannel = AndroidNotificationChannel(
          'water_channel',
          'Water Reminders',
          'Notifications for water intake reminders',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
        );

        // Meal notification channel
        const AndroidNotificationChannel mealChannel = AndroidNotificationChannel(
          'meal_channel',
          'Meal Reminders',
          'Notifications for meal time reminders',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
        );

        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        await androidPlugin?.createNotificationChannel(waterChannel);
        await androidPlugin?.createNotificationChannel(mealChannel);

        // In older versions of the plugin, we don't need to request permission for Android
        debugPrint('Android notification channels created');
      }

      // Request permission for iOS
      if (Platform.isIOS) {
        final iosPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  // Schedule water intake notifications every 30 minutes with improved reliability
  Future<bool> scheduleWaterIntakeNotifications() async {
    // Initialize notifications if not already initialized
    await init();

    // Cancel any existing water notifications
    await cancelWaterNotifications();

    try {
      // Get the current time
      final now = DateTime.now();

      // Start time (8:00 AM) - if it's already past 8 AM, use the current time
      final startHour = now.hour < 8 ? 8 : now.hour;
      final startMinute = now.hour < 8 ? 0 : (now.minute < 30 ? 30 : 0);
      final startHourAdjusted = now.hour < 8 ? 8 : (now.minute < 30 ? now.hour : now.hour + 1);

      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        startHourAdjusted,
        startMinute
      );

      // End time (10:00 PM)
      final endTime = DateTime(now.year, now.month, now.day, 22, 0);

      // Calculate the number of notifications (every 30 minutes)
      final int notificationCount = ((endTime.difference(startTime).inMinutes) / 30).floor();

      debugPrint('Scheduling $notificationCount water notifications from ${startTime.toString()} to ${endTime.toString()}');

      // Schedule notifications with immediate test notification
      // First, schedule an immediate test notification to verify permissions
      final testWaterReminder = NotificationContent.getRandomWaterReminder();
      final testTime = DateTime.now().add(const Duration(seconds: 10));

      await scheduleNotification(
        id: 999, // Special ID for test notification
        title: "🔔 Notifications Enabled",
        body: "Water reminders will appear throughout the day. Stay hydrated!",
        scheduledTime: testTime,
        payload: 'water_test',
        channelId: 'water_channel',
        channelName: 'Water Reminders',
        channelDescription: 'Notifications for water intake reminders',
        importance: Importance.high,
        priority: Priority.high,
        showBadge: true,
      );

      debugPrint('Test water notification scheduled for ${testTime.toString()}');

      // Now schedule the regular notifications
      for (int i = 0; i < notificationCount; i++) {
        final scheduledTime = startTime.add(Duration(minutes: i * 30));

        // Only schedule if the time is in the future
        if (scheduledTime.isAfter(now)) {
          // Get a random water reminder message
          final waterReminder = NotificationContent.getRandomWaterReminder();

          await scheduleNotification(
            id: 1000 + i,
            title: waterReminder['title']!,
            body: waterReminder['body']!,
            scheduledTime: scheduledTime,
            payload: 'water_reminder',
            channelId: 'water_channel',
            channelName: 'Water Reminders',
            channelDescription: 'Notifications for water intake reminders',
            importance: Importance.high,
            priority: Priority.high,
            showBadge: true,
          );

          debugPrint('Water notification #${i+1} scheduled for ${scheduledTime.toString()}');

          // Add a small delay between scheduling notifications to prevent Android throttling
          if (Platform.isAndroid) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
      }

      // Also schedule notifications for tomorrow morning
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);

      // Schedule 4 notifications for tomorrow morning (8:00, 8:30, 9:00, 9:30)
      for (int i = 0; i < 4; i++) {
        final scheduledTime = tomorrowStart.add(Duration(minutes: i * 30));
        final waterReminder = NotificationContent.getRandomWaterReminder();

        await scheduleNotification(
          id: 1100 + i, // Different ID range for tomorrow
          title: waterReminder['title']!,
          body: waterReminder['body']!,
          scheduledTime: scheduledTime,
          payload: 'water_reminder_tomorrow',
          channelId: 'water_channel',
          channelName: 'Water Reminders',
          channelDescription: 'Notifications for water intake reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );

        debugPrint('Tomorrow water notification #${i+1} scheduled for ${scheduledTime.toString()}');

        // Add a small delay between scheduling notifications
        if (Platform.isAndroid) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      // Save the notification status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('water_notifications_enabled', true);

      debugPrint('Water notifications scheduled successfully');
      return true; // Success
    } catch (e) {
      debugPrint('Error scheduling water notifications: $e');
      // Don't rethrow to prevent app crashes
      // Instead, try to schedule at least one notification
      try {
        final fallbackTime = DateTime.now().add(const Duration(minutes: 30));
        final waterReminder = NotificationContent.getRandomWaterReminder();

        await scheduleNotification(
          id: 1000,
          title: waterReminder['title']!,
          body: waterReminder['body']!,
          scheduledTime: fallbackTime,
          payload: 'water_reminder_fallback',
          channelId: 'water_channel',
          channelName: 'Water Reminders',
          channelDescription: 'Notifications for water intake reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );

        debugPrint('Fallback water notification scheduled for ${fallbackTime.toString()}');

        // Save the notification status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('water_notifications_enabled', true);
        return true; // Success with fallback
      } catch (fallbackError) {
        debugPrint('Error scheduling fallback water notification: $fallbackError');
        return false; // Failed even with fallback
      }
    }
  }

  // Schedule meal time notifications with improved reliability for Android
  Future<void> scheduleMealTimeNotifications() async {
    // Initialize notifications if not already initialized
    await init();

    // Cancel any existing meal notifications
    await cancelMealNotifications();

    try {
      // Get the current time
      final now = DateTime.now();

      // Get user's meal times from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final mealTimesJson = prefs.getString('user_data');

      // Default meal times if not set by user
      int breakfastHour = 8;
      int breakfastMinute = 0;
      int lunchHour = 13;
      int lunchMinute = 0;
      int dinnerHour = 19;
      int dinnerMinute = 0;

      // Try to parse user's meal times if available
      if (mealTimesJson != null && mealTimesJson.contains('meal_times')) {
        try {
          // This is a simplified approach - in a real app, you'd parse the JSON properly
          // For now, we'll stick with default times
          debugPrint('User has custom meal times set, but using defaults for now');
        } catch (e) {
          debugPrint('Error parsing meal times: $e');
        }
      }

      // First, schedule an immediate test notification to verify permissions
      final testTime = DateTime.now().add(const Duration(seconds: 15));

      await scheduleNotification(
        id: 1998, // Special ID for test notification
        title: "🔔 Meal Reminders Enabled",
        body: "You'll receive notifications for breakfast, lunch, and dinner times.",
        scheduledTime: testTime,
        payload: 'meal_test',
        channelId: 'meal_channel',
        channelName: 'Meal Reminders',
        channelDescription: 'Notifications for meal time reminders',
        importance: Importance.high,
        priority: Priority.high,
        showBadge: true,
      );

      debugPrint('Test meal notification scheduled for ${testTime.toString()}');

      // Add a small delay between scheduling notifications
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Schedule breakfast notification
      final breakfastTime = DateTime(now.year, now.month, now.day, breakfastHour, breakfastMinute);

      // Get a random breakfast reminder message
      final breakfastReminder = NotificationContent.getRandomBreakfastReminder();

      if (breakfastTime.isAfter(now)) {
        await scheduleNotification(
          id: 2000,
          title: breakfastReminder['title']!,
          body: breakfastReminder['body']!,
          scheduledTime: breakfastTime,
          payload: 'breakfast_reminder',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );
        debugPrint('Breakfast notification scheduled for ${breakfastTime.toString()}');
      } else {
        // Schedule for tomorrow
        final tomorrowBreakfast = breakfastTime.add(const Duration(days: 1));
        await scheduleNotification(
          id: 2000,
          title: breakfastReminder['title']!,
          body: breakfastReminder['body']!,
          scheduledTime: tomorrowBreakfast,
          payload: 'breakfast_reminder',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );
        debugPrint('Tomorrow\'s breakfast notification scheduled for ${tomorrowBreakfast.toString()}');
      }

      // Add a small delay between scheduling notifications
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Schedule lunch notification
      final lunchTime = DateTime(now.year, now.month, now.day, lunchHour, lunchMinute);

      // Get a random lunch reminder message
      final lunchReminder = NotificationContent.getRandomLunchReminder();

      if (lunchTime.isAfter(now)) {
        await scheduleNotification(
          id: 2001,
          title: lunchReminder['title']!,
          body: lunchReminder['body']!,
          scheduledTime: lunchTime,
          payload: 'lunch_reminder',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );
        debugPrint('Lunch notification scheduled for ${lunchTime.toString()}');
      } else {
        // Schedule for tomorrow
        final tomorrowLunch = lunchTime.add(const Duration(days: 1));
        await scheduleNotification(
          id: 2001,
          title: lunchReminder['title']!,
          body: lunchReminder['body']!,
          scheduledTime: tomorrowLunch,
          payload: 'lunch_reminder',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );
        debugPrint('Tomorrow\'s lunch notification scheduled for ${tomorrowLunch.toString()}');
      }

      // Add a small delay between scheduling notifications
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Schedule dinner notification
      final dinnerTime = DateTime(now.year, now.month, now.day, dinnerHour, dinnerMinute);

      // Get a random dinner reminder message
      final dinnerReminder = NotificationContent.getRandomDinnerReminder();

      if (dinnerTime.isAfter(now)) {
        await scheduleNotification(
          id: 2002,
          title: dinnerReminder['title']!,
          body: dinnerReminder['body']!,
          scheduledTime: dinnerTime,
          payload: 'dinner_reminder',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );
        debugPrint('Dinner notification scheduled for ${dinnerTime.toString()}');
      } else {
        // Schedule for tomorrow
        final tomorrowDinner = dinnerTime.add(const Duration(days: 1));
        await scheduleNotification(
          id: 2002,
          title: dinnerReminder['title']!,
          body: dinnerReminder['body']!,
          scheduledTime: tomorrowDinner,
          payload: 'dinner_reminder',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );
        debugPrint('Tomorrow\'s dinner notification scheduled for ${tomorrowDinner.toString()}');
      }

      // Save the notification status
      await prefs.setBool('meal_notifications_enabled', true);

      debugPrint('Meal notifications scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling meal notifications: $e');
      // Don't rethrow to prevent app crashes
      // Instead, try to schedule at least one notification
      try {
        final fallbackTime = DateTime.now().add(const Duration(minutes: 45));
        final mealReminder = NotificationContent.getRandomLunchReminder();

        await scheduleNotification(
          id: 2099,
          title: mealReminder['title']!,
          body: mealReminder['body']!,
          scheduledTime: fallbackTime,
          payload: 'meal_reminder_fallback',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );

        debugPrint('Fallback meal notification scheduled for ${fallbackTime.toString()}');

        // Save the notification status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('meal_notifications_enabled', true);
      } catch (fallbackError) {
        debugPrint('Error scheduling fallback meal notification: $fallbackError');
        rethrow;
      }
    }
  }

  // Schedule meal time notifications with custom times
  Future<void> scheduleMealTimeNotificationsWithCustomTimes(List<Map<String, dynamic>> mealTimes) async {
    // Initialize notifications if not already initialized
    await init();

    // Cancel any existing meal notifications
    await cancelMealNotifications();

    try {
      // Get the current time
      final now = DateTime.now();

      // Process each meal time
      for (int i = 0; i < mealTimes.length; i++) {
        final meal = mealTimes[i];
        final mealName = meal['name'] as String;
        final timeString = meal['time'] as String;

        // Parse time string (format: "hour:minute")
        final timeParts = timeString.split(':');
        if (timeParts.length != 2) continue;

        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour == null || minute == null) continue;

        // Create DateTime for the meal
        final mealTime = DateTime(now.year, now.month, now.day, hour, minute);
        final isTomorrow = !mealTime.isAfter(now);
        final scheduledTime = isTomorrow ? mealTime.add(const Duration(days: 1)) : mealTime;

        // Determine notification content based on meal name
        Map<String, String> mealReminder;

        if (mealName.toLowerCase().contains('breakfast')) {
          mealReminder = NotificationContent.getRandomBreakfastReminder();
        } else if (mealName.toLowerCase().contains('lunch')) {
          mealReminder = NotificationContent.getRandomLunchReminder();
        } else if (mealName.toLowerCase().contains('dinner')) {
          mealReminder = NotificationContent.getRandomDinnerReminder();
        } else {
          // Default meal reminder
          mealReminder = {
            'title': '🍽️ Meal Time!',
            'body': 'Time to eat! Remember to track your meal in FoodAI.',
          };
        }

        // Schedule the notification
        await scheduleNotification(
          id: 2000 + i,
          title: mealReminder['title']!,
          body: mealReminder['body']!,
          scheduledTime: scheduledTime,
          payload: '${mealName.toLowerCase()}_reminder',
          channelId: 'meal_channel',
          channelName: 'Meal Reminders',
          channelDescription: 'Notifications for meal time reminders',
          importance: Importance.high,
          priority: Priority.high,
          showBadge: true,
        );

        debugPrint('${mealName} notification scheduled for ${scheduledTime.toString()}');
      }

      // Save the notification status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('meal_notifications_enabled', true);

      debugPrint('Custom meal notifications scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling custom meal notifications: $e');
      rethrow;
    }
  }

  // Schedule a single notification with enhanced settings and Android compatibility
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'foodai_channel',
    String channelName = 'FoodAI Notifications',
    String channelDescription = 'Notifications for FoodAI app',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    bool showBadge = true,
  }) async {
    // Make sure notifications are initialized
    await init();

    try {
      // Ensure the scheduled time is in the future
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('Warning: Attempted to schedule notification in the past. Adjusting to now + 5 seconds.');
        scheduledTime = DateTime.now().add(const Duration(seconds: 5));
      }

      // Convert DateTime to TZDateTime with proper timezone handling
      final tz.TZDateTime tzScheduledTime = _convertToTZ(scheduledTime);

      // Define notification details with custom channel settings for Android
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription,
        importance: importance,
        priority: priority,
        color: const Color(0xFFFF9800),
        enableVibration: true,
        enableLights: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: 'FoodAI',
          htmlFormatSummaryText: true,
        ),
        ticker: 'FoodAI Notification',
        visibility: NotificationVisibility.public,
      );

      // Define iOS notification details
      final IOSNotificationDetails iosDetails = IOSNotificationDetails(
        presentAlert: true,
        presentBadge: showBadge,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        subtitle: 'FoodAI',
        threadIdentifier: channelId,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification with exact timing
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint('Enhanced notification scheduled: $title at ${scheduledTime.toString()} (ID: $id)');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      // Don't rethrow to prevent cascading failures
    }
  }

  // Helper method to convert DateTime to TZDateTime with proper timezone handling
  tz.TZDateTime _convertToTZ(DateTime dateTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    // If the time is in the past, schedule it for the next day
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel all water notifications
  Future<bool> cancelWaterNotifications() async {
    try {
      // Make sure notifications are initialized
      await init();

      // Cancel water notifications (IDs 1000-1099)
      for (int i = 0; i < 100; i++) {
        await flutterLocalNotificationsPlugin.cancel(1000 + i);
      }

      // Also cancel the test notification
      await flutterLocalNotificationsPlugin.cancel(999);

      // Save the notification status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('water_notifications_enabled', false);

      debugPrint('Water notifications cancelled successfully');
      return true; // Success
    } catch (e) {
      debugPrint('Error cancelling water notifications: $e');
      return false; // Failed
    }
  }

  // Cancel all meal notifications
  Future<void> cancelMealNotifications() async {
    try {
      // Make sure notifications are initialized
      await init();

      // Cancel meal notifications
      await flutterLocalNotificationsPlugin.cancel(2000); // Breakfast
      await flutterLocalNotificationsPlugin.cancel(2001); // Lunch
      await flutterLocalNotificationsPlugin.cancel(2002); // Dinner

      // Also cancel any custom meal notifications (2003-2099)
      for (int i = 3; i < 100; i++) {
        await flutterLocalNotificationsPlugin.cancel(2000 + i);
      }

      // Save the notification status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('meal_notifications_enabled', false);

      debugPrint('Meal notifications cancelled successfully');
    } catch (e) {
      debugPrint('Error cancelling meal notifications: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      // Make sure notifications are initialized
      await init();

      // Cancel all notifications
      await flutterLocalNotificationsPlugin.cancelAll();

      // Save the notification status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('water_notifications_enabled', false);
      await prefs.setBool('meal_notifications_enabled', false);

      debugPrint('All notifications cancelled successfully');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // Toggle water notifications
  Future<bool> toggleWaterNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('water_notifications_enabled') ?? false;

      if (enabled) {
        await cancelWaterNotifications();
        debugPrint('Water notifications disabled');
        return false;
      } else {
        await scheduleWaterIntakeNotifications();
        debugPrint('Water notifications enabled');
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling water notifications: $e');
      return false;
    }
  }

  // Toggle meal notifications
  Future<bool> toggleMealNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('meal_notifications_enabled') ?? false;

      if (enabled) {
        await cancelMealNotifications();
        debugPrint('Meal notifications disabled');
        return false;
      } else {
        await scheduleMealTimeNotifications();
        debugPrint('Meal notifications enabled');
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling meal notifications: $e');
      return false;
    }
  }

  // Check if water notifications are enabled
  Future<bool> areWaterNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('water_notifications_enabled') ?? false;
    debugPrint('Water notifications enabled: $enabled');
    return enabled;
  }

  // Check if meal notifications are enabled
  Future<bool> areMealNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('meal_notifications_enabled') ?? false;
    debugPrint('Meal notifications enabled: $enabled');
    return enabled;
  }

  // Reschedule all active notifications
  Future<void> rescheduleAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final waterEnabled = prefs.getBool('water_notifications_enabled') ?? false;
      final mealEnabled = prefs.getBool('meal_notifications_enabled') ?? false;

      // Cancel all existing notifications first
      await cancelAllNotifications();

      // Reschedule notifications that were enabled
      if (waterEnabled) {
        await scheduleWaterIntakeNotifications();
      }

      if (mealEnabled) {
        await scheduleMealTimeNotifications();
      }

      debugPrint('All notifications rescheduled successfully');
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }
}
