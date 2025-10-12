import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_up_screen/sign_up_webview.dart';

class WebHeader extends StatefulWidget {
  const WebHeader({Key? key}) : super(key: key);

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  final WebGuestService _webGuestService = WebGuestService();
  bool _isUserMenuOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _userIconKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isUserMenuOpen) {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
        }
      },
      child: LayoutBuilder(
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
      ),
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
                _buildUserIconButton(context, isMobile: true),
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
        _buildUserIconButton(context),
      ],
    );
  }

  Widget _buildUserIconButton(BuildContext context, {bool isMobile = false}) {
    final size = isMobile ? 32.0 : 40.0;
    final iconSize = isMobile ? 16.0 : 20.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isUserMenuOpen = !_isUserMenuOpen;
            });
            if (_isUserMenuOpen) {
              _showOverlay(context, isMobile);
            } else {
              _removeOverlay();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            key: _userIconKey,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Icon(Icons.person_outline,
                color: _isUserMenuOpen
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: iconSize),
          ),
        ),
      ],
    );
  }

  Widget _buildUserSubmenu(BuildContext context, bool isMobile) {
    return FutureBuilder<bool>(
      future: _webGuestService.isCurrentUserGuest(),
      builder: (context, snapshot) {
        final isGuest = snapshot.data ?? true;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 200,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Container(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: isGuest
                ? _buildGuestMenuItems(context)
                : _buildAuthenticatedMenuItems(context),
          ),
        );
      },
    );
  }

  List<Widget> _buildGuestMenuItems(BuildContext context) {
    return [
      _buildMenuItem(
        context,
        icon: Icons.login,
        title: S.of(context).signIn,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          Navigator.pushNamed(context, '/sign-in');
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.person_add,
        title: S.of(context).register,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          showSignUpModal(context);
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.settings,
        title: S.of(context).settings,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          // TODO: Navigate to settings page
        },
      ),
    ];
  }

  List<Widget> _buildAuthenticatedMenuItems(BuildContext context) {
    return [
      _buildMenuItem(
        context,
        icon: Icons.person,
        title: S.of(context).accountInfo,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          Navigator.pushNamed(context, '/user');
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.settings,
        title: S.of(context).settings,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          // TODO: Navigate to settings page
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.logout,
        title: S.of(context).signOut,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          // TODO: Handle sign out
        },
      ),
    ];
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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

  void _showOverlay(BuildContext context, bool isMobile) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlayMenu(context, isMobile),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayMenu(BuildContext context, bool isMobile) {
    final RenderBox? renderBox =
        _userIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return Positioned(
      left: position.dx - 200 + size.width, // Align right edge with icon
      top: position.dy + size.height + 12,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 300,
            maxWidth: 200,
          ),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when clicking inside menu
            child: _buildUserSubmenu(context, isMobile),
          ),
        ),
      ),
    );
  }
}
