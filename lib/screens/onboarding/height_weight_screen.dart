import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../utils/m3_animations.dart'; // For M3 animation constants

class HeightWeightScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel updatedUser) onNext;
  final VoidCallback onBack;

  const HeightWeightScreen({
    Key? key,
    required this.user,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends State<HeightWeightScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _weightUnit = 'kg';
  String _heightUnit = 'cm';

  @override
  void initState() {
    super.initState();
    if (widget.user.weight != null && widget.user.weight!['value'] != null) {
      _weightController.text = widget.user.weight!['value'].toString();
      _weightUnit = widget.user.weight!['unit'] as String? ?? 'kg';
    }

    if (widget.user.height != null && widget.user.height!['value'] != null) {
      _heightController.text = widget.user.height!['value'].toString();
      _heightUnit = widget.user.height!['unit'] as String? ?? 'cm';
    }
     _weightController.addListener(_validateForm);
    _heightController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _weightController.removeListener(_validateForm);
    _heightController.removeListener(_validateForm);
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool _isFormValid = false;

  void _validateForm() {
    setState(() {
      _isFormValid = _weightController.text.isNotEmpty && _heightController.text.isNotEmpty;
    });
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
              _buildWeightSection(context).animate().fadeIn(delay: M3Animations.shortDelay * 3, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
              const SizedBox(height: 32),
              _buildHeightSection(context).animate().fadeIn(delay: M3Animations.shortDelay * 4, duration: M3Animations.medium).slideY(begin: 0.2, duration: M3Animations.medium, curve: Curves.easeOut),
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
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2, // This is the second content screen
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()), // Total 5 steps assumed
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      'Your height and weight',
      style: textTheme.headlineSmall?.copyWith(color: colorScheme.onBackground),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      'This helps us calculate your calorie and nutrient needs.',
      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildWeightSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight',
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
          children: [
            Expanded(
              flex: 3, // Give more space to text field
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')), // Allow one decimal place
                ],
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: '0.0',
                  hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // M3 typical padding
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2, // Adjust flex for unit selector
              child: _buildUnitChipSelector(
                currentValue: _weightUnit,
                options: const ['kg', 'lbs'],
                onSelected: (value) {
                  if (_weightController.text.isNotEmpty) {
                      double weightVal = double.tryParse(_weightController.text) ?? 0.0;
                      if (value == 'kg' && _weightUnit == 'lbs') { // lbs to kg
                        weightVal *= 0.453592;
                        _weightController.text = weightVal.toStringAsFixed(1);
                      } else if (value == 'lbs' && _weightUnit == 'kg') { // kg to lbs
                        weightVal *= 2.20462;
                        _weightController.text = weightVal.toStringAsFixed(1);
                      }
                    }
                  setState(() {
                    _weightUnit = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeightSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Height',
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: '0.0',
                  hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildUnitChipSelector(
                currentValue: _heightUnit,
                options: const ['cm', 'ft/in'],
                onSelected: (value) {
                   if (_heightController.text.isNotEmpty) {
                      double heightVal = double.tryParse(_heightController.text) ?? 0.0;
                      if (value == 'cm' && _heightUnit == 'ft/in') { // ft/in (as inches) to cm
                        heightVal *= 2.54;
                        _heightController.text = heightVal.toStringAsFixed(1);
                      } else if (value == 'ft/in' && _heightUnit == 'cm') { // cm to inches
                        heightVal /= 2.54;
                        _heightController.text = heightVal.toStringAsFixed(1);
                      }
                    }
                  setState(() {
                    _heightUnit = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitChipSelector({
    required String currentValue,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: options.map((option) {
        final isSelected = currentValue == option;
        return Expanded( // Ensure chips take available space
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add some spacing between chips
            child: FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
              selectedColor: colorScheme.primaryContainer,
              labelStyle: textTheme.labelLarge?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
              checkmarkColor: isSelected ? colorScheme.onPrimaryContainer : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // M3 radius
                side: BorderSide(
                  color: isSelected ? colorScheme.primaryContainer : colorScheme.outline.withOpacity(0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Adjusted padding
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _isFormValid
            ? () {
                HapticFeedback.mediumImpact();
                final weight = {
                  'value': double.tryParse(_weightController.text) ?? 0.0,
                  'unit': _weightUnit,
                };
                final height = {
                  'value': double.tryParse(_heightController.text) ?? 0.0,
                  'unit': _heightUnit,
                };
                final updatedUser = widget.user.copyWith(
                  weight: weight,
                  height: height,
                );
                widget.onNext(updatedUser);
              }
            : null, // Button is disabled if form is not valid
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text('Next', style: textTheme.labelLarge),
      ),
    );
  }
}
