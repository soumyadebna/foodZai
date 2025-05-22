import 'dart:math';

/// Utility class for generating engaging notification content
class NotificationContent {
  // Water reminder messages with hydration facts and motivational content
  static final List<Map<String, String>> waterReminders = [
    {
      'title': '💧 Hydration Alert!',
      'body': 'Time for a water break! Staying hydrated improves energy levels and brain function.',
    },
    {
      'title': '💦 Water Time!',
      'body': 'Drinking water now can help you avoid headaches and fatigue later. Take a sip!',
    },
    {
      'title': '🌊 Hydration Reminder',
      'body': 'Your body is 60% water - keep it that way! Time to refill your water levels.',
    },
    {
      'title': '💧 Water Break',
      'body': 'Proper hydration can improve your mood and cognitive performance. Drink up!',
    },
    {
      'title': '🚰 Hydration Station',
      'body': 'Water helps transport nutrients to your cells. Keep the delivery system running!',
    },
    {
      'title': '💦 Thirsty?',
      'body': 'Even mild dehydration can affect your physical performance. Stay hydrated!',
    },
    {
      'title': '🌊 Water O\'Clock',
      'body': 'Drinking water helps maintain the balance of body fluids. Time for a refill!',
    },
    {
      'title': '💧 Hydration Check',
      'body': 'Water helps your kidneys filter waste. Show them some love with a glass of water!',
    },
    {
      'title': '💦 Water Reminder',
      'body': 'Drinking water can help control calories and maintain healthy skin. Bottoms up!',
    },
    {
      'title': '🌊 Hydration Time',
      'body': 'Water regulates your body temperature. Keep your cooling system in check!',
    },
  ];

  // Breakfast reminder messages with nutrition facts and morning motivation
  static final List<Map<String, String>> breakfastReminders = [
    {
      'title': '🍳 Breakfast Time!',
      'body': 'Start your day with a nutritious breakfast to fuel your morning activities!',
    },
    {
      'title': '🥞 Morning Fuel',
      'body': 'A protein-rich breakfast helps maintain steady energy levels throughout the day.',
    },
    {
      'title': '🍌 Rise & Shine',
      'body': 'Breakfast eaters tend to have better concentration and productivity. Time to eat!',
    },
    {
      'title': '🥪 Breakfast Alert',
      'body': 'A balanced breakfast helps regulate blood sugar and reduces mid-morning cravings.',
    },
    {
      'title': '🥣 Morning Nutrition',
      'body': 'Eating breakfast kickstarts your metabolism. Ready to power up your day?',
    },
  ];

  // Lunch reminder messages with midday nutrition facts and energy tips
  static final List<Map<String, String>> lunchReminders = [
    {
      'title': '🥗 Lunch Break!',
      'body': 'Time to refuel with a nutritious lunch. Your afternoon productivity depends on it!',
    },
    {
      'title': '🍲 Midday Meal',
      'body': 'A balanced lunch helps maintain energy levels and prevents afternoon slumps.',
    },
    {
      'title': '🥙 Lunch Time',
      'body': 'Taking a proper lunch break improves focus and reduces stress. Enjoy your meal!',
    },
    {
      'title': '🍱 Nutrition Time',
      'body': 'A nutrient-rich lunch supports brain function and keeps you energized all day.',
    },
    {
      'title': '🥘 Lunch Alert',
      'body': 'Skipping lunch can lead to overeating later. Time for a balanced meal!',
    },
  ];

  // Dinner reminder messages with evening nutrition facts and wellness tips
  static final List<Map<String, String>> dinnerReminders = [
    {
      'title': '🍽️ Dinner Time!',
      'body': 'End your day with a balanced dinner. Remember to track it in FoodAI!',
    },
    {
      'title': '🥘 Evening Meal',
      'body': 'A nutritious dinner supports recovery and prepares your body for restful sleep.',
    },
    {
      'title': '🍛 Dinner Alert',
      'body': 'Eating dinner 2-3 hours before bedtime can improve sleep quality. Time to eat!',
    },
    {
      'title': '🍲 Dinner Reminder',
      'body': 'A protein-rich dinner helps repair muscles after a day of activity.',
    },
    {
      'title': '🥗 Evening Nutrition',
      'body': 'Balance your plate with vegetables, protein, and whole grains for optimal health.',
    },
  ];

  // Get a random water reminder
  static Map<String, String> getRandomWaterReminder() {
    final random = Random();
    return waterReminders[random.nextInt(waterReminders.length)];
  }

  // Get a random breakfast reminder
  static Map<String, String> getRandomBreakfastReminder() {
    final random = Random();
    return breakfastReminders[random.nextInt(breakfastReminders.length)];
  }

  // Get a random lunch reminder
  static Map<String, String> getRandomLunchReminder() {
    final random = Random();
    return lunchReminders[random.nextInt(lunchReminders.length)];
  }

  // Get a random dinner reminder
  static Map<String, String> getRandomDinnerReminder() {
    final random = Random();
    return dinnerReminders[random.nextInt(dinnerReminders.length)];
  }
}
