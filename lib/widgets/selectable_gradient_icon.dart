import 'package:flutter/material.dart';

class SelectableGradientIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final double size;

  const SelectableGradientIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return isSelected
        ? ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds);
      },
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    )
        : Icon(
      icon,
      size: size,
      color: Theme.of(context).colorScheme.onPrimary,
    );
  }
}