import 'package:flutter/material.dart';

class GradientRadioButton<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final String text;

  const GradientRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: value == groupValue
              ? theme.colorScheme.primary
              : theme.colorScheme.primaryContainer,
          border: value == groupValue
              ? null
              : Border.all(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: value == groupValue
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
