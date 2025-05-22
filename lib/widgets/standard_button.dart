import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StandardButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final Duration? animationDelay;
  final IconData? icon;
  final double? iconSize;
  final double? iconSpacing;

  const StandardButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.height = 56.0,
    this.width,
    this.margin,
    this.animationDelay,
    this.icon,
    this.iconSize = 20.0,
    this.iconSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidget = Container(
      height: height,
      width: width ?? double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: (backgroundColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? backgroundColor ?? Theme.of(context).colorScheme.primary
              : Colors.grey[300],
          foregroundColor: isEnabled
              ? textColor ?? Colors.white
              : Colors.grey[500],
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: isEnabled
                        ? textColor ?? Colors.white
                        : Colors.grey[500],
                  ),
                  SizedBox(width: iconSpacing),
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );

    // Always return the button widget, animation delay is not used anymore
    return buttonWidget;
  }
}
