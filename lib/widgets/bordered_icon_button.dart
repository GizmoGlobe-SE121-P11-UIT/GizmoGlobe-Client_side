import 'package:flutter/material.dart';

class BorderedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Color fillColor;
  final double iconSize;

  const BorderedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
    this.padding = const EdgeInsets.all(8),
    this.fillColor = Colors.white,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
          padding: padding,
        ),
      ),
    );
  }
}