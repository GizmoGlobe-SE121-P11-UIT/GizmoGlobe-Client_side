import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';

class CheckboxButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onSelected;

  const CheckboxButton({
    super.key,
    required this.text,
    required this.isSelected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? Colors.white : theme.colorScheme.primaryContainer,
          border: isSelected ? null : Border.all(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          text,
          style: AppTextStyle.buttonTextBold.copyWith(
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}