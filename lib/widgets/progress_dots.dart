import 'package:flutter/material.dart';

class ProgressDots extends StatelessWidget {
  final int totalDots;
  final int currentDot;
  final Color activeDotColor;
  final Color inactiveDotColor;
  final double dotSize;
  final double spacing;

  const ProgressDots({
    Key? key,
    required this.totalDots,
    required this.currentDot,
    this.activeDotColor = Colors.green,
    this.inactiveDotColor = Colors.grey,
    this.dotSize = 8.0,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalDots,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: index < currentDot ? activeDotColor : inactiveDotColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
