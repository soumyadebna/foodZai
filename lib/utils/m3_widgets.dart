import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'm3_animations.dart';
import 'constants.dart';

/// Material 3 widget utilities for consistent UI components across the app
class M3Widgets {
  /// Creates a Material 3 styled card with proper elevation and shape
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? color,
    double elevation = 1,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    final card = Card(
      elevation: elevation,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
      ),
      clipBehavior: onTap != null ? Clip.hardEdge : Clip.none,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: card,
      );
    }
    
    return card;
  }
  
  /// Creates a Material 3 styled section header
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? AppColors.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'View more',
            ),
        ],
      ),
    );
  }
  
  /// Creates a Material 3 styled progress indicator
  static Widget circularProgressIndicator({
    required double value,
    required Color color,
    double size = 48,
    double strokeWidth = 4,
    Color? backgroundColor,
    bool animate = true,
    Duration animationDuration = M3Animations.long,
    Widget? child,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (animate)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: animationDuration,
              curve: M3Animations.emphasizedCurve,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                );
              },
            )
          else
            CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          if (child != null) child,
        ],
      ),
    );
  }
  
  /// Creates a Material 3 styled linear progress indicator
  static Widget linearProgressIndicator({
    required double value,
    required Color color,
    double height = 8,
    Color? backgroundColor,
    bool animate = true,
    Duration animationDuration = M3Animations.long,
    BorderRadius? borderRadius,
  }) {
    final indicator = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: animationDuration,
              curve: M3Animations.emphasizedCurve,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: height,
                  backgroundColor: backgroundColor ?? color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
                );
              },
            )
          : LinearProgressIndicator(
              value: value,
              minHeight: height,
              backgroundColor: backgroundColor ?? color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
            ),
    );
    
    return indicator;
  }
  
  /// Creates a Material 3 styled chip
  static Widget chip({
    required String label,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final chipColor = color ?? AppColors.primaryColor;
    
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : chipColor,
        ),
      ),
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : chipColor,
            )
          : null,
      selected: selected,
      onSelected: onTap != null ? (_) => onTap() : null,
      backgroundColor: chipColor.withOpacity(0.1),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? Colors.transparent : chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
  
  /// Creates a Material 3 styled badge
  static Widget badge({
    required String label,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    final badgeColor = color ?? AppColors.primaryColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }
}
