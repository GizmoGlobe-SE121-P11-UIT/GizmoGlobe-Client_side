import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final Alignment alignment;

  const AppLogo({
    super.key,
    this.height = 96.0,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Image.asset(
        'lib/GizmoGlobeLogo.png', // Path to your logo asset
        height: height,
      ),
    );
  }
}