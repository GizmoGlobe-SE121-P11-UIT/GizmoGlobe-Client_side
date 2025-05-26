import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final String text;
  final double fontSize;

  const GradientText({
    required this.text,
    this.fontSize = 24.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
