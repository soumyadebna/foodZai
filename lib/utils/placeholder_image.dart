import 'package:flutter/material.dart';

class PlaceholderImage extends StatelessWidget {
  final String label;
  final Color color;
  final double width;
  final double height;
  final double borderRadius;

  const PlaceholderImage({
    Key? key,
    required this.label,
    this.color = Colors.amber,
    this.width = 160,
    this.height = 160,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
