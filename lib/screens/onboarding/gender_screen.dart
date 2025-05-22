import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Keep for CupertinoDatePicker if needed, though custom is used
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../utils/m3_animations.dart'; // For M3 animation constants
import '../../utils/constants.dart'; // For AppColors (will be replaced by theme colors)

class GenderScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel updatedUser) onNext;
  final VoidCallback onBack;

  const GenderScreen({
    Key? key,
    required this.user,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String _selectedGender = 'male'; // Default or from widget.user
  DateTime _selectedDate = DateTime(1990, 1, 1); // Default or from widget.user

  @override
  void initState() {
    super.initState();
    if (widget.user.gender != null && widget.user.gender!.isNotEmpty) {
      _selectedGender = widget.user.gender!;
    }
    if (widget.user.dateOfBirth != null) {
      _selectedDate = widget.user.dateOfBirth!;
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
              const SizedBox(height: 40),
              _buildGenderSelection(context).animate().fadeIn(delay: M3Animations.shortDelay * 3, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
              const SizedBox(height: 40),
              _buildDateOfBirthSection(context).animate().fadeIn(delay: M3Animations.shortDelay * 4, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
              const Spacer(),
              _buildNextButton(context).animate().fadeIn(delay: M3Animations.shortDelay * 5, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 8, // M3 typical progress bar height
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant, // M3 color
        borderRadius: BorderRadius.circular(4), // M3 radius
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1, // Assuming this screen is the first step after welcome
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary, // M3 color
                borderRadius: BorderRadius.circular(4), // M3 radius
              ),
            ),
          ),
          const Expanded(flex: 4, child: SizedBox()), // Adjust flex based on number of onboarding steps
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      'Tell us about yourself',
      style: textTheme.headlineSmall?.copyWith(color: colorScheme.onBackground),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      'We need this information to calculate your nutrition needs accurately.',
      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildGenderSelection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                context,
                'Male',
                'male',
                Icons.male_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(
                context,
                'Female',
                'female',
                Icons.female_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(BuildContext context, String title, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16), // Increased padding
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16), // M3 typical radius
          border: Border.all(
            color: isSelected ? colorScheme.primaryContainer : colorScheme.outline,
            width: isSelected ? 2 : 1, // Emphasize selection
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12), // Adjusted spacing
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOfBirthSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final age = now.year - _selectedDate.year -
      (now.month > _selectedDate.month ||
      (now.month == _selectedDate.month && now.day >= _selectedDate.day) ? 0 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showCustomDatePicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface, // M3 surface
              borderRadius: BorderRadius.circular(16), // M3 radius
              border: Border.all(color: colorScheme.outline), // M3 outline
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Adjusted padding
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12), // M3 radius
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16), // Adjusted spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                      ),
                      Text(
                        '$age years old',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10), // Adjusted padding
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer, // M3 color
                    borderRadius: BorderRadius.circular(12), // M3 radius
                  ),
                  child: Icon(
                    Icons.edit_outlined, // M3 icon
                    color: colorScheme.onSecondaryContainer, // M3 color
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    int tempYear = _selectedDate.year;
    int tempMonth = _selectedDate.month;
    int tempDay = _selectedDate.day;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make it transparent for custom shape
      builder: (BuildContext modalContext) { // Use modalContext
        return StatefulBuilder( // Wrap with StatefulBuilder for modal state
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65, // Adjusted height
              decoration: BoxDecoration(
                color: colorScheme.surface, // M3 surface color
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28), // M3 radius
                  topRight: Radius.circular(28), // M3 radius
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(top: 16, bottom: 16), // M3 spacing
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4), // M3 color
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Text(
                      'Select Date of Birth',
                      style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('MMMM d, yyyy').format(DateTime(tempYear, tempMonth, tempDay)),
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align pickers to top
                      children: [
                        _buildDatePickerWheel(
                          context: modalContext, // Use modalContext
                          items: List.generate(12, (index) => DateFormat('MMM').format(DateTime(2000, index + 1))),
                          initialItem: tempMonth - 1,
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              tempMonth = index + 1;
                              final daysInMonth = DateTime(tempYear, tempMonth + 1, 0).day;
                              if (tempDay > daysInMonth) tempDay = daysInMonth;
                            });
                          },
                        ),
                        _buildDatePickerWheel(
                          context: modalContext, // Use modalContext
                          items: List.generate(DateTime(tempYear, tempMonth + 1, 0).day, (index) => '${index + 1}'),
                          initialItem: tempDay - 1,
                           onSelectedItemChanged: (index) => setModalState(() => tempDay = index + 1),
                        ),
                        _buildDatePickerWheel(
                          context: modalContext, // Use modalContext
                          items: List.generate(DateTime.now().year - 1920 + 1, (index) => '${1920 + index}'),
                          initialItem: tempYear - 1920,
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              tempYear = 1920 + index;
                              final daysInMonth = DateTime(tempYear, tempMonth + 1, 0).day;
                              if (tempDay > daysInMonth) tempDay = daysInMonth;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalContext), // Use modalContext
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: colorScheme.outline),
                            ),
                            child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() { // Update main screen state
                                _selectedDate = DateTime(tempYear, tempMonth, tempDay);
                              });
                              Navigator.pop(modalContext); // Use modalContext
                              HapticFeedback.mediumImpact();
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Confirm', style: textTheme.labelLarge),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePickerWheel({
    required BuildContext context,
    required List<String> items,
    required int initialItem,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: SizedBox(
        height: 200, // Fixed height for the wheel
        child: ListWheelScrollView.useDelegate(
          itemExtent: 40,
          perspective: 0.005,
          diameterRatio: 1.2, // Adjusted for better M3 feel
          physics: const FixedExtentScrollPhysics(),
          controller: FixedExtentScrollController(initialItem: initialItem),
          onSelectedItemChanged: onSelectedItemChanged,
          useMagnifier: true, // M3 style magnification
          magnification: 1.1, // M3 style magnification
          childDelegate: ListWheelChildLoopingListDelegate( // Or ListWheelChildListDelegate if no looping
            children: items.map<Widget>((item) {
              // Determine if this item is the "current" one for styling
              // This is a bit tricky as ListWheelScrollView doesn't directly expose selected item in builder
              // For simplicity, we'll style all items similarly and rely on magnification
              return Center(
                child: Text(
                  item,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                ),
              );
            }).toList(),
          ),
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
          final updatedUser = widget.user.copyWith(
            gender: _selectedGender,
            dateOfBirth: _selectedDate,
          );
          widget.onNext(updatedUser);
          HapticFeedback.mediumImpact();
        },
        style: FilledButton.styleFrom(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // M3 radius
        ),
        child: Text('Next', style: textTheme.labelLarge),
      ),
    );
  }
}
