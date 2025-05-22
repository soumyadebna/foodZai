import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// A customizable speed dial FAB that displays multiple options in a staggered animation.
///
/// This widget creates a floating action button that expands to show multiple options
/// when tapped, similar to the design shown in the reference image.
///
/// Improved for reliability and performance.
class SpeedDialFab extends StatefulWidget {
  /// Callback when the camera option is selected
  final VoidCallback onCameraSelected;

  /// Callback when the gallery option is selected
  final VoidCallback onGallerySelected;

  /// Callback when the voice option is selected
  final VoidCallback onVoiceSelected;

  /// Background color for the FAB
  final Color backgroundColor;

  /// Text color for the FAB
  final Color textColor;

  const SpeedDialFab({
    Key? key,
    required this.onCameraSelected,
    required this.onGallerySelected,
    required this.onVoiceSelected,
    this.backgroundColor = AppColors.primaryColor, // Use app's primary color
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;

  // Track if the widget is mounted to prevent setState after dispose
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Add listener to animation controller for better state management
    _animationController.addStatusListener(_handleAnimationStatusChange);
  }

  @override
  void dispose() {
    // Remove listener before disposing
    _animationController.removeStatusListener(_handleAnimationStatusChange);
    _animationController.dispose();
    _isMounted = false;
    super.dispose();
  }

  // Handle animation status changes
  void _handleAnimationStatusChange(AnimationStatus status) {
    if (!_isMounted) return;

    if (status == AnimationStatus.dismissed) {
      // Animation has completed closing
      if (!_isOpen && mounted) {
        setState(() {
          // Ensure state is consistent
        });
      }
    }
  }

  void _toggle() {
    // Add haptic feedback with error handling
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error with haptic feedback: $e');
      // Continue even if haptic feedback fails
    }

    if (!mounted) return;

    debugPrint('SpeedDialFab: Toggling state. Current state: $_isOpen');

    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        debugPrint('SpeedDialFab: Opening menu');
        _animationController.forward();
      } else {
        debugPrint('SpeedDialFab: Closing menu');
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Get screen size for better positioning
    final screenSize = MediaQuery.of(context).size;
    // Use SafeArea to respect system UI
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    // Calculate proper bottom position with SafeArea
    final bottomPosition = 16.0 + safeAreaBottom;

    return Material(
      // Use Material widget to ensure proper touch handling
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Overlay to capture taps when menu is open (to close it)
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggle,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

          // Camera option
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            bottom: _isOpen ? bottomPosition + 60 * 1 : bottomPosition,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isOpen
                  ? _buildFabOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        _toggle();
                        // Delay callback slightly to allow animation to start
                        Future.delayed(const Duration(milliseconds: 100), () {
                          widget.onCameraSelected();
                        });
                      },
                      delay: 50,
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Gallery option
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            bottom: _isOpen ? bottomPosition + 60 * 2 : bottomPosition,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isOpen
                  ? _buildFabOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        _toggle();
                        // Delay callback slightly to allow animation to start
                        Future.delayed(const Duration(milliseconds: 100), () {
                          widget.onGallerySelected();
                        });
                      },
                      delay: 100,
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Voice input option
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            bottom: _isOpen ? bottomPosition + 60 * 3 : bottomPosition,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isOpen
                  ? _buildFabOption(
                      icon: Icons.mic,
                      label: 'Voice input',
                      onTap: () {
                        _toggle();
                        // Delay callback slightly to allow animation to start
                        Future.delayed(const Duration(milliseconds: 100), () {
                          widget.onVoiceSelected();
                        });
                      },
                      delay: 150,
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Main FAB - using standard FloatingActionButton to ensure compatibility
          Positioned(
            bottom: bottomPosition,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'main_fab',
              onPressed: _toggle,
              backgroundColor: widget.backgroundColor,
              elevation: 4,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0, // 45 degrees when expanded
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isOpen ? Icons.close : Icons.add,
                  color: widget.textColor,
                  size: 28, // Make icon more visible
                ),
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? backgroundColor,
    bool isHorizontal = false,
    int delay = 0,
  }) {
    // Use Material widget for better touch response
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label on the left side
          if (label.isNotEmpty && !isHorizontal)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: widget.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // The FAB button itself
          SizedBox(
            width: 40, // Fixed size for better touch target
            height: 40, // Fixed size for better touch target
            child: FloatingActionButton.small(
              heroTag: 'fab_option_${label.isEmpty ? "close" : label}_${DateTime.now().millisecondsSinceEpoch}',
              onPressed: onTap,
              backgroundColor: backgroundColor ?? widget.backgroundColor,
              elevation: 4,
              child: Icon(icon, color: widget.textColor),
              // Add Material 3 shape
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Label on the right side
          if (label.isNotEmpty && isHorizontal)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Material(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: widget.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fade(
      duration: const Duration(milliseconds: 200),
      delay: Duration(milliseconds: delay),
      curve: Curves.easeOut,
    ).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.0, 1.0),
      duration: const Duration(milliseconds: 200),
      delay: Duration(milliseconds: delay),
      curve: Curves.easeOut,
    );
  }
}
