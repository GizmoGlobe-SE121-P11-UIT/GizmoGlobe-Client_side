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
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: borderRadius,
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: IconButton(
          icon: Icon(
            icon,
            color: Colors.white,
            size: iconSize,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}