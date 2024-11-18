import 'package:flutter/material.dart';

class StandardButton extends StatelessWidget {
  final VoidCallback onPress;
  final Color? backgroundColor;
  final double height;
  final double width;
  final double borderRadius;
  final String text;
  final double fontSize;
  final Color fontColor;
  final FontWeight fontWeight;

  const StandardButton({
    super.key,
    required this.onPress,
    this.backgroundColor,
    this.height = 50.0,
    this.width = double.infinity,
    this.borderRadius = 12.0,
    this.text = '',
    this.fontSize = 22.0,
    this.fontColor = Colors.white,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: onPress,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme
              .of(context)
              .colorScheme
              .primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: fontColor,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
