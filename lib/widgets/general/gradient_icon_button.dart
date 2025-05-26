import 'package:flutter/material.dart';

class GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final BorderRadius borderRadius;
  final Color fillColor;
  final double iconSize;

  const GradientIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
    this.fillColor = Colors.transparent,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: borderRadius,
        ),
        child: GestureDetector(
          onTap: onPressed,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
