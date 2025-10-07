import 'package:flutter/material.dart';

class WebHeader extends StatelessWidget {
  const WebHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 768 && screenWidth <= 1200;
        final isMobile = screenWidth <= 768;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? 16
                : isTablet
                    ? 40
                    : 80,
            vertical: isMobile ? 16 : 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: isMobile
              ? _buildMobileHeader(context)
              : _buildDesktopHeader(isTablet, context),
        );
      },
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Column(
      children: [
        // Top row with logo and menu button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: Image.asset(
                'lib/GizmoGlobeLogo.png',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            // Action buttons
            Row(
              children: [
                _buildIconButton(context, Icons.chat_bubble_outline,
                    isMobile: true, onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                }),
                const SizedBox(width: 8),
                _buildIconButton(context, Icons.shopping_cart_outlined,
                    isMobile: true, onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                }),
                const SizedBox(width: 8),
                _buildIconButton(context, Icons.person_outline, isMobile: true,
                    onPressed: () {
                  Navigator.pushNamed(context, '/user');
                }),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(bool isTablet, BuildContext context) {
    return Row(
      children: [
        // Logo
        GestureDetector(
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
          child: Image.asset(
            'lib/GizmoGlobeLogo.png',
            height: isTablet ? 36 : 40,
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        // Action Buttons
        _buildIconButton(context, Icons.chat_bubble_outline, onPressed: () {
          Navigator.pushNamed(context, '/chat');
        }),
        const SizedBox(width: 16),
        _buildIconButton(context, Icons.shopping_cart_outlined, onPressed: () {
          Navigator.pushNamed(context, '/cart');
        }),
        const SizedBox(width: 16),
        _buildIconButton(context, Icons.person_outline, onPressed: () {
          Navigator.pushNamed(context, '/user');
        }),
      ],
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon,
      {bool isMobile = false, VoidCallback? onPressed}) {
    final size = isMobile ? 32.0 : 40.0;
    final iconSize = isMobile ? 16.0 : 20.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Icon(icon,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            size: iconSize),
      ),
    );
  }
}
