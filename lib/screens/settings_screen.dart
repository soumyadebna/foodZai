import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../services/navigation_service.dart';
import '../services/theme_mode_provider.dart';
import '../services/notification_service.dart';
import '../utils/routes.dart';
import '../utils/constants.dart';
import '../utils/enhanced_animations.dart';
import '../widgets/enhanced_widgets.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _waterNotificationsEnabled = false;
  bool _mealNotificationsEnabled = false;
  String _versionNumber = '1.0.0';
  late AnimationController _animationController;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color? subtitleColor,
    Duration delay,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
      duration: EnhancedAnimations.short,
      delay: EnhancedAnimations.shortDelay + delay,
      curve: EnhancedAnimations.emphasizedCurve,
    ).slideX(
      begin: 0.1,
      end: 0,
      duration: EnhancedAnimations.short,
      delay: EnhancedAnimations.shortDelay + delay,
      curve: EnhancedAnimations.emphasizedCurve,
    );
  }

  Widget _buildSettingsButton(
    String title,
    String subtitle,
    IconData icon,
    Color textColor,
    Color? subtitleColor,
    Duration delay,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: subtitleColor,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: EnhancedAnimations.short,
      delay: EnhancedAnimations.mediumDelay + delay,
      curve: EnhancedAnimations.emphasizedCurve,
    ).slideX(
      begin: 0.1,
      end: 0,
      duration: EnhancedAnimations.short,
      delay: EnhancedAnimations.mediumDelay + delay,
      curve: EnhancedAnimations.emphasizedCurve,
    );
  }

  Widget _buildSettingsToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Color textColor,
    Color? subtitleColor,
    Duration delay,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Add haptic feedback
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: EnhancedAnimations.short,
      delay: EnhancedAnimations.mediumDelay + delay,
      curve: EnhancedAnimations.emphasizedCurve,
    ).slideX(
      begin: 0.1,
      end: 0,
      duration: EnhancedAnimations.short,
      delay: EnhancedAnimations.mediumDelay + delay,
      curve: EnhancedAnimations.emphasizedCurve,
    );
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize notification service
      await _notificationService.init();

      // Get the theme mode from the provider
      final themeProvider = Provider.of<ThemeModeProvider>(context, listen: false);
      final isDarkMode = themeProvider.isDarkMode;

      // Get user data
      final user = await _userService.getUserData();

      // Check notification settings
      final waterEnabled = await _notificationService.areWaterNotificationsEnabled();
      final mealEnabled = await _notificationService.areMealNotificationsEnabled();

      if (mounted) {
        setState(() {
          _isDarkMode = isDarkMode;
          _user = user;
          _waterNotificationsEnabled = waterEnabled;
          _mealNotificationsEnabled = mealEnabled;
          _isLoading = false;
        });
      }

      debugPrint('Settings loaded - Dark mode: $_isDarkMode, Water notifications: $_waterNotificationsEnabled, Meal notifications: $_mealNotificationsEnabled');
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate age from date of birth
  String _calculateAge() {
    if (_user?.dateOfBirth != null) {
      final now = DateTime.now();
      final age = now.year - _user!.dateOfBirth!.year;

      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < _user!.dateOfBirth!.month ||
          (now.month == _user!.dateOfBirth!.month && now.day < _user!.dateOfBirth!.day)) {
        return (age - 1).toString();
      }

      return age.toString();
    }
    return 'Not set';
  }

  // Format height display
  String _formatHeight(Map<String, dynamic> heightData) {
    final double value = heightData['value'] is int
        ? (heightData['value'] as int).toDouble()
        : heightData['value'] as double;
    final String unit = heightData['unit'] as String;

    if (unit == 'cm') {
      return '${value.toInt()} cm';
    } else if (unit == 'ft/in') {
      // Convert total inches to feet and inches
      final int totalInches = value.toInt();
      final int feet = totalInches ~/ 12;
      final int inches = totalInches % 12;
      return '$feet\'$inches"';
    }

    return '${value.toInt()} $unit';
  }

  Future<void> _toggleDarkMode(bool value) async {
    // Get the theme provider
    final themeProvider = Provider.of<ThemeModeProvider>(context, listen: false);

    // Set the theme mode using the provider
    await themeProvider.setDarkMode(value);

    setState(() {
      _isDarkMode = value;
    });

    debugPrint('Dark mode toggled to: $value');

    // Show a snackbar to confirm the change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Dark mode enabled' : 'Light mode enabled',
          style: GoogleFonts.poppins(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Apply theme changes immediately by restarting the app
    // Navigate to splash screen to "restart" the app with new theme
    NavigationService.navigateToAndRemoveUntil(Routes.splash);
  }

  Future<void> _resetOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    await _userService.setOnboardingCompleted(false);

    setState(() {
      _isLoading = false;
    });

    // Navigate to splash screen
    NavigationService.navigateToAndRemoveUntil(Routes.splash);
  }

  Future<void> _toggleWaterNotifications(bool value) async {
    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Toggle water notifications
      final success = await _notificationService.toggleWaterNotifications();

      setState(() {
        _waterNotificationsEnabled = success;
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Water reminders enabled' : 'Water reminders disabled',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? AppColors.primaryColor : Colors.grey,
        ),
      );

      debugPrint('Water notifications toggled to: $success');
    } catch (e) {
      debugPrint('Error toggling water notifications: $e');

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update notification settings',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleMealNotifications(bool value) async {
    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Toggle meal notifications
      final success = await _notificationService.toggleMealNotifications();

      setState(() {
        _mealNotificationsEnabled = success;
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Meal reminders enabled' : 'Meal reminders disabled',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? AppColors.primaryColor : Colors.grey,
        ),
      );

      debugPrint('Meal notifications toggled to: $success');
    } catch (e) {
      debugPrint('Error toggling meal notifications: $e');

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update notification settings',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetAllData() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset All Data',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will delete all your data and reset the app to its initial state. This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      // Cancel all notifications
      await _notificationService.cancelAllNotifications();

      // Reset all data
      await _userService.resetAllData();

      setState(() {
        _isLoading = false;
      });

      // Navigate to splash screen
      NavigationService.navigateToAndRemoveUntil(Routes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Theme.of(context).cardTheme.color : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ).animate().fadeIn(
          duration: EnhancedAnimations.short,
          curve: EnhancedAnimations.emphasizedCurve,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 16),

                // User Info Card
                EnhancedWidgets.card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  animate: true,
                  animationDuration: EnhancedAnimations.medium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          ).shimmer(
                            duration: const Duration(seconds: 3),
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ).animate().fadeIn(
                            duration: EnhancedAnimations.short,
                            delay: EnhancedAnimations.tinyDelay,
                            curve: EnhancedAnimations.emphasizedCurve,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Age',
                        '${_calculateAge()} years',
                        Icons.cake_outlined,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 100),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Height',
                        _user?.height != null ? _formatHeight(_user!.height!) : 'Not set',
                        Icons.height_outlined,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 200),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Current Weight',
                        _user?.weight != null ? '${_user!.weight!['value']} ${_user!.weight!['unit']}' : 'Not set',
                        Icons.monitor_weight_outlined,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 16),
                      EnhancedWidgets.button(
                        onPressed: () {
                          // Navigate to profile screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        text: 'Edit Profile',
                        icon: Icons.edit_outlined,
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        borderRadius: 12,
                        animate: true,
                        animationDuration: EnhancedAnimations.short,
                        animationDelay: EnhancedAnimations.mediumDelay,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Customization Card
                EnhancedWidgets.card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  animate: true,
                  animationDuration: EnhancedAnimations.medium,
                  animationDelay: EnhancedAnimations.shortDelay,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          ).shimmer(
                            duration: const Duration(seconds: 3),
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Customization',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ).animate().fadeIn(
                            duration: EnhancedAnimations.short,
                            delay: EnhancedAnimations.shortDelay + const Duration(milliseconds: 100),
                            curve: EnhancedAnimations.emphasizedCurve,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Adjust goals button
                      _buildSettingsButton(
                        'Adjust Goals',
                        'Calories, carbs, fats, and protein',
                        Icons.flag_outlined,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 200),
                        () {
                          // Add haptic feedback
                          HapticFeedback.mediumImpact();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Goal adjustment coming soon',
                                style: GoogleFonts.poppins(),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.primaryColor,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Dark mode toggle
                      _buildSettingsToggle(
                        'Dark Mode',
                        'Switch between light and dark theme',
                        Icons.dark_mode_outlined,
                        _isDarkMode,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 300),
                        (value) => _toggleDarkMode(value),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Preferences
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Preferences',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),

                ListTile(
                  leading: Icon(
                    Icons.dark_mode_outlined,
                    color: AppColors.primaryColor,
                  ),
                  title: Text(
                    'Dark Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Enable dark theme',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode,
                    activeColor: Theme.of(context).colorScheme.primary,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),

                // Notifications Card
                EnhancedWidgets.card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  animate: true,
                  animationDuration: EnhancedAnimations.medium,
                  animationDelay: EnhancedAnimations.mediumDelay,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          ).shimmer(
                            duration: const Duration(seconds: 3),
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ).animate().fadeIn(
                            duration: EnhancedAnimations.short,
                            delay: EnhancedAnimations.mediumDelay + const Duration(milliseconds: 100),
                            curve: EnhancedAnimations.emphasizedCurve,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Water reminders toggle
                      _buildSettingsToggle(
                        'Water Reminders',
                        'Remind me to drink water every 30 minutes',
                        Icons.water_drop_outlined,
                        _waterNotificationsEnabled,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 200),
                        (value) => _toggleWaterNotifications(value),
                      ),

                      const SizedBox(height: 12),

                      // Meal reminders toggle
                      _buildSettingsToggle(
                        'Meal Reminders',
                        'Remind me of my meal times',
                        Icons.restaurant_outlined,
                        _mealNotificationsEnabled,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 400),
                        (value) => _toggleMealNotifications(value),
                      ),

                      const SizedBox(height: 16),

                      // Notification settings info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Notifications help you stay on track with your nutrition and hydration goals.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                        duration: EnhancedAnimations.medium,
                        delay: EnhancedAnimations.mediumDelay + const Duration(milliseconds: 600),
                        curve: EnhancedAnimations.emphasizedCurve,
                      ).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: EnhancedAnimations.medium,
                        delay: EnhancedAnimations.mediumDelay + const Duration(milliseconds: 600),
                        curve: EnhancedAnimations.emphasizedCurve,
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Legal Card
                EnhancedWidgets.card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  animate: true,
                  animationDuration: EnhancedAnimations.medium,
                  animationDelay: EnhancedAnimations.longDelay,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.gavel,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          ).shimmer(
                            duration: const Duration(seconds: 3),
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Legal',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ).animate().fadeIn(
                            duration: EnhancedAnimations.short,
                            delay: EnhancedAnimations.longDelay + const Duration(milliseconds: 100),
                            curve: EnhancedAnimations.emphasizedCurve,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Terms and Conditions button
                      _buildSettingsButton(
                        'Terms and Conditions',
                        'Read our terms of service',
                        Icons.description_outlined,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 200),
                        () {
                          // Add haptic feedback
                          HapticFeedback.mediumImpact();

                          // Navigate to Terms and Conditions screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsConditionsScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Privacy Policy button
                      _buildSettingsButton(
                        'Privacy Policy',
                        'Read our privacy policy',
                        Icons.privacy_tip_outlined,
                        textColor,
                        subtitleColor,
                        const Duration(milliseconds: 400),
                        () {
                          // Add haptic feedback
                          HapticFeedback.mediumImpact();

                          // Navigate to Privacy Policy screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Delete Account button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Add haptic feedback
                            HapticFeedback.mediumImpact();
                            _resetAllData();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Account',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(
                        duration: EnhancedAnimations.medium,
                        delay: EnhancedAnimations.longDelay + const Duration(milliseconds: 600),
                        curve: EnhancedAnimations.emphasizedCurve,
                      ).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: EnhancedAnimations.medium,
                        delay: EnhancedAnimations.longDelay + const Duration(milliseconds: 600),
                        curve: EnhancedAnimations.emphasizedCurve,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Version number with animation
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'VERSION 1.1.0',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  duration: EnhancedAnimations.medium,
                  delay: EnhancedAnimations.extraLongDelay,
                  curve: EnhancedAnimations.emphasizedCurve,
                ).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                  duration: EnhancedAnimations.medium,
                  delay: EnhancedAnimations.extraLongDelay,
                  curve: EnhancedAnimations.emphasizedCurve,
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  void _showUnitsDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool usesImperialUnits = false; // Default to metric

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Units',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    title: Text(
                      'Metric (kg, cm)',
                      style: GoogleFonts.poppins(),
                    ),
                    value: false,
                    groupValue: usesImperialUnits,
                    onChanged: (value) {
                      setState(() {
                        usesImperialUnits = value!;
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      'Imperial (lb, in)',
                      style: GoogleFonts.poppins(),
                    ),
                    value: true,
                    groupValue: usesImperialUnits,
                    onChanged: (value) {
                      setState(() {
                        usesImperialUnits = value!;
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Save units preference
                    // TODO: Implement unit conversion
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Units setting coming soon',
                          style: GoogleFonts.poppins(),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
