import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../utils/m3_animations.dart'; // For M3 animation constants

class ActivityScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel updatedUser) onNext;
  final VoidCallback onBack;

  const ActivityScreen({
    Key? key,
    required this.user,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedActivity = 'moderate'; // Default or from widget.user

  @override
  void initState() {
    super.initState();
    if (widget.user.activityLevel != null && widget.user.activityLevel!.isNotEmpty) {
      _selectedActivity = widget.user.activityLevel!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(context).animate().fadeIn(duration: M3Animations.medium),
              const SizedBox(height: 32),
              _buildTitle(context).animate().fadeIn(delay: M3Animations.shortDelay, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
              const SizedBox(height: 8),
              _buildSubtitle(context).animate().fadeIn(delay: M3Animations.shortDelay * 2, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
              const SizedBox(height: 32), // Adjusted spacing
              Expanded( // Allow activity options to scroll if needed
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: _buildActivityOptions(context)
                      .animate(interval: M3Animations.shortDelay, delay: M3Animations.shortDelay * 3)
                      .fadeIn(duration: M3Animations.medium)
                      .slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
                ),
              ),
              const SizedBox(height: 24), // Spacing before button
              _buildNextButton(context).animate().fadeIn(delay: M3Animations.shortDelay * 4, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3, // This is the third content screen
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()), // Total 5 steps assumed
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      'How active are you?',
      style: textTheme.headlineSmall?.copyWith(color: colorScheme.onBackground),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      'This helps us calculate your daily calorie needs.',
      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }

  List<Widget> _buildActivityOptions(BuildContext context) {
    // Using a helper list for clarity
    final List<Map<String, dynamic>> activities = [
      {'title': 'Sedentary', 'value': 'sedentary', 'description': 'Little or no exercise, desk job', 'icon': Icons.weekend_outlined},
      {'title': 'Lightly Active', 'value': 'light', 'description': 'Light exercise 1-3 days/week', 'icon': Icons.directions_walk},
      {'title': 'Moderately Active', 'value': 'moderate', 'description': 'Moderate exercise 3-5 days/week', 'icon': Icons.directions_run},
      {'title': 'Very Active', 'value': 'active', 'description': 'Hard exercise 6-7 days/week', 'icon': Icons.fitness_center},
      {'title': 'Extremely Active', 'value': 'very_active', 'description': 'Hard daily exercise and physical job', 'icon': Icons.sports_gymnastics_rounded}, // M3 icon
    ];

    List<Widget> options = [];
    for (var activity in activities) {
      options.add(
        _buildActivityCard(
          context,
          activity['title'],
          activity['value'],
          activity['description'],
          activity['icon'],
        ),
      );
      if (activity != activities.last) { // Add spacing between cards
        options.add(const SizedBox(height: 16));
      }
    }
    return options;
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedActivity == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivity = value;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16), // M3 typical radius
          border: Border.all(
            color: isSelected ? colorScheme.primaryContainer : colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1, // Emphasize selection
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.secondaryContainer,
                shape: BoxShape.circle, // M3 uses circles for icons in list items often
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSecondaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2), // Small spacing
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: (isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant).withOpacity(0.8),
                    ),
                    maxLines: 2, // Allow description to wrap
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), // Spacing before checkmark
            if (isSelected)
              Icon(
                Icons.check_circle_rounded, // M3 checkmark
                color: colorScheme.primary, // Use primary color for selected checkmark
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      height: 56, // M3 standard button height
      child: FilledButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          final updatedUser = widget.user.copyWith(
            activityLevel: _selectedActivity,
          );
          widget.onNext(updatedUser);
        },
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // M3 radius
        ),
        child: Text('Next', style: textTheme.labelLarge), // Button text is "Next", not "Finish"
      ),
    );
  }
}
