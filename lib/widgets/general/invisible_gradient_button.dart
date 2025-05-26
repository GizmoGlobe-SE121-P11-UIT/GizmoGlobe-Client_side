import 'package:flutter/material.dart';

class InvisibleGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const InvisibleGradientButton({
    super.key,
    required this.onPressed,
    this.prefixIcon,
    this.suffixIcon,
    this.text = '',
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefixIcon != null) Icon(prefixIcon, color: primaryColor),
          if (prefixIcon != null) const SizedBox(width: 8.0),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: primaryColor,
              fontWeight: fontWeight,
            ),
          ),
          if (suffixIcon != null) const SizedBox(width: 8.0),
          if (suffixIcon != null) Icon(suffixIcon, color: primaryColor),
        ],
      ),
    );
  }
}
