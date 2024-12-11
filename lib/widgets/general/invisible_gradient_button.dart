import 'package:flutter/material.dart';

class InvisibleGradientButton extends StatelessWidget {
  final VoidCallback onPress;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const InvisibleGradientButton({
    super.key,
    required this.onPress,
    this.prefixIcon,
    this.suffixIcon,
    this.text = '',
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPress,
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      child: ShaderMask(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null) Icon(prefixIcon, color: Colors.white),
            if (prefixIcon != null) const SizedBox(width: 8.0),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: fontWeight,
              ),
            ),
            if (suffixIcon != null) const SizedBox(width: 8.0),
            if (suffixIcon != null) Icon(suffixIcon, color: Colors.white),
          ],
        ),
      ),
    );
  }
}