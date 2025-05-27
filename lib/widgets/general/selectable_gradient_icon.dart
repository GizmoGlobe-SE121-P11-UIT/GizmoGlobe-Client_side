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
    return Icon(
      icon,
      size: size,
      color: isSelected
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}
