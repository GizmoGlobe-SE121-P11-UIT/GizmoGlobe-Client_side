import 'package:flutter/material.dart';

class GradientCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final double size;

  const GradientCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            width: 2,
            color: Colors.transparent,
          ),
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: Container(
          width: size - 8,
          height: size - 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: value ? Colors.transparent : Theme.of(context).colorScheme.surface,
          ),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.transparent,
            checkColor: Colors.white,
          ),
        ),
      ),
    );
  }
}