import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';

class CheckboxButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onSelected;
  final EdgeInsets padding;
  final TextStyle textStyle;

  const CheckboxButton({
    super.key,
    required this.text,
    required this.isSelected,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    this.textStyle = AppTextStyle.buttonTextBold,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: isSelected ? 
            LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[400]!,
          ),
        ),
        child: Text(
          text,
          style: textStyle.copyWith(
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}