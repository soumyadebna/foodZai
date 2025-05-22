import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/enhanced_animations.dart';
import '../utils/m3_animations.dart';
import '../utils/m3_widgets.dart';

/// Button types for Material 3 buttons
enum ButtonType {
  filled,
  tonal,
  outlined,
  text,
  elevated,
}

/// Enhanced widgets for the FoodAI app following Material 3 Expressive principles
class EnhancedWidgets {
  // Enhanced card with Material 3 Expressive design
  static Widget card({
    required Widget child,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? elevation,
    BorderRadius? borderRadius,
    BorderSide? borderSide,
    bool animate = true,
    Duration? animationDuration,
    Duration? animationDelay,
    bool interactive = false,
    VoidCallback? onTap,
  }) {
    // Use Material 3 Card with proper elevation and shape
    final Widget baseCard = Card(
      elevation: elevation ?? 2,
      color: backgroundColor,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        side: borderSide ?? BorderSide.none,
      ),
      clipBehavior: (interactive || onTap != null) ? Clip.hardEdge : Clip.none,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (!animate) {
      if (onTap != null) {
        return InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(24),
          child: baseCard,
        );
      }
      return baseCard;
    }

    Widget animatedCard = baseCard.animate()
      .fadeIn(
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
        curve: EnhancedAnimations.standardCurve,
      )
      .slideY(
        begin: 0.05,
        end: 0,
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
        curve: EnhancedAnimations.emphasizedCurve,
      );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: animatedCard,
      );
    }

    if (interactive) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isHovered = false;

          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedScale(
              scale: isHovered ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.identity()..translate(0, isHovered ? -2.0 : 0),
                child: animatedCard,
              ),
            ),
          );
        },
      );
    }

    return animatedCard;
  }

  // Enhanced progress indicator with Material 3 Expressive design
  static Widget progressIndicator({
    required double value,
    required Color color,
    double height = 8,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    bool animate = true,
    Duration? animationDuration,
    Duration? animationDelay,
  }) {
    final Widget baseIndicator = Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
          ),
        ),
      ),
    );

    if (!animate) return baseIndicator;

    return baseIndicator.animate()
      .fadeIn(
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
      )
      .scaleX(
        begin: 0.0,
        end: 1.0,
        alignment: Alignment.centerLeft,
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
        curve: EnhancedAnimations.emphasizedCurve,
      );
  }

  // Enhanced circular progress indicator with Material 3 Expressive design
  static Widget circularProgressIndicator({
    required double value,
    required Color color,
    double size = 100,
    double strokeWidth = 10,
    Color? backgroundColor,
    bool animate = true,
    Duration? animationDuration,
    Duration? animationDelay,
    Widget? child,
  }) {
    final Widget baseIndicator = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Use Material 3 style circular progress indicator
          animate && animationDuration != null
              ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
                  duration: animationDuration,
                  curve: EnhancedAnimations.emphasizedCurve,
                  builder: (context, animatedValue, _) {
                    return CircularProgressIndicator(
                      value: animatedValue,
                      strokeWidth: strokeWidth,
                      backgroundColor: backgroundColor ?? Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    );
                  },
                )
              : CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: strokeWidth,
                  backgroundColor: backgroundColor ?? Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
          if (child != null) child,
        ],
      ),
    );

    if (!animate) return baseIndicator;

    return baseIndicator.animate()
      .fadeIn(
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
      )
      .scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1.0, 1.0),
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
        curve: EnhancedAnimations.emphasizedCurve,
      );
  }

  // Enhanced button with Material 3 Expressive design
  static Widget button({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool animate = true,
    Duration? animationDuration,
    Duration? animationDelay,
    IconData? icon,
    ButtonType type = ButtonType.filled,
  }) {
    Widget baseButton;

    switch (type) {
      case ButtonType.filled:
        baseButton = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
            elevation: 1,
          ),
          child: _buildButtonContent(text, icon),
        );
        break;

      case ButtonType.tonal:
        baseButton = FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
          ),
          child: _buildButtonContent(text, icon),
        );
        break;

      case ButtonType.outlined:
        baseButton = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
          ),
          child: _buildButtonContent(text, icon),
        );
        break;

      case ButtonType.text:
        baseButton = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
            ),
          ),
          child: _buildButtonContent(text, icon),
        );
        break;

      case ButtonType.elevated:
        baseButton = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
            elevation: 2,
          ),
          child: _buildButtonContent(text, icon),
        );
        break;
    }

    if (!animate) return baseButton;

    return baseButton.animate()
      .fadeIn(
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
      )
      .scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
        curve: EnhancedAnimations.emphasizedCurve,
      );
  }

  // Helper method to build button content
  static Widget _buildButtonContent(String text, IconData? icon) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      );
    } else {
      return Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      );
    }
  }

  // Enhanced list item with Material 3 Expressive design
  static Widget listItem({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool animate = true,
    Duration? animationDuration,
    Duration? animationDelay,
    int index = 0,
  }) {
    final Widget baseListItem = Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );

    if (!animate) return baseListItem;

    return baseListItem.animate()
      .fadeIn(
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: (animationDelay ?? EnhancedAnimations.noDelay) + Duration(milliseconds: index * 50),
      )
      .slideY(
        begin: 0.05,
        end: 0,
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: (animationDelay ?? EnhancedAnimations.noDelay) + Duration(milliseconds: index * 50),
        curve: EnhancedAnimations.emphasizedCurve,
      );
  }

  // Enhanced section header with Material 3 Expressive design
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool animate = true,
    Duration? animationDuration,
    Duration? animationDelay,
  }) {
    final Widget baseHeader = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: margin ?? EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    if (!animate) return baseHeader;

    return baseHeader.animate()
      .fadeIn(
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
      )
      .slideY(
        begin: 0.05,
        end: 0,
        duration: animationDuration ?? EnhancedAnimations.medium,
        delay: animationDelay ?? EnhancedAnimations.noDelay,
        curve: EnhancedAnimations.emphasizedCurve,
      );
  }
}
