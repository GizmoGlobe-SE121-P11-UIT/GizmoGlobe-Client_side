import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_up_screen/sign_up_webview.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_webview.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_cubit.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/components/general/user_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/services/platform_actions.dart'
    as platform_actions;
import 'package:gizmoglobe_client/screens/user/survey_screen/survey_screen_webview.dart';
import 'package:gizmoglobe_client/components/general/web_sidebar.dart';

class WebHeader extends StatefulWidget {
  const WebHeader({super.key});

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  final WebGuestService _webGuestService = WebGuestService();
  bool _isUserMenuOpen = false;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _sidebarOverlay;
  final GlobalKey _userIconKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();

  void _closeUserMenuIfOpen() {
    if (_isUserMenuOpen) {
      setState(() => _isUserMenuOpen = false);
      _removeOverlay();
    }
  }

  bool get _isSidebarOpen => _sidebarOverlay != null;

  void _toggleSidebar() {
    if (_isSidebarOpen) {
      _hideSidebarOverlay();
    } else {
      _showSidebarOverlay();
    }
    setState(() {});
  }

  Widget _buildSidebarToggleButton(BuildContext context, bool isTablet) {
    final size = isTablet ? 36.0 : 40.0;
    final iconSize = isTablet ? 18.0 : 20.0;

    return GestureDetector(
      onTap: _toggleSidebar,
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
        child: Icon(
          _isSidebarOpen ? Icons.menu_open : Icons.menu,
          color: _isSidebarOpen
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          size: iconSize,
        ),
      ),
    );
  }

  void _showSidebarOverlay() {
    final overlayState = Overlay.of(context, rootOverlay: true);
    if (_sidebarOverlay != null) return;

    _sidebarOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: WebSidebar(
                      isOpen: true,
                      onToggle: _toggleSidebar,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_sidebarOverlay!);
  }

  void _hideSidebarOverlay() {
    _sidebarOverlay?.remove();
    _sidebarOverlay = null;
  }

  Future<void> _handleCartNavigation(BuildContext context) async {
    _closeUserMenuIfOpen();

    // Check if user is guest before navigating to cart
    final isGuest = await _webGuestService.isCurrentUserGuest();
    if (isGuest) {
      // Show snackbar and sign-in modal for guest users
      final overlayState = Navigator.of(context).overlay!;
      SnackbarService.showGuestRestrictionAboveOverlay(
        overlayState,
        context: context,
        actionType: 'cart',
      );
      final signInCubit = SignInCubit();
      await showSignInModalWithCubit(context, signInCubit);
    } else {
      // User is authenticated, navigate to cart
      Navigator.pushNamed(context, '/cart');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (kIsWeb) {
      try {
        // Clear local guest data first (this clears favorites, cart, etc.)
        await _webGuestService.clearGuestUser();

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (kDebugMode) {
          print('Error during logout cleanup: $e');
        }
        // Continue with reload even if cleanup fails
      }

      // Wait a brief moment to ensure signOut completes and localStorage is cleared
      // Then reload immediately to prevent StreamBuilder from creating a guest user
      await Future.delayed(const Duration(milliseconds: 50));

      // Force immediate page reload - this will stop all further execution
      platform_actions.reloadPage();

      // This should never be reached as reload navigates away
      return;
    } else {
      // For mobile, clear data and navigate to home
      try {
        await _webGuestService.clearGuestUser();
        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarService.showError(
            context,
            title: S.of(context).error,
            message: '${S.of(context).signOut}: $e',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _hideSidebarOverlay();
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
            key: _headerKey,
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
        // Top row with sidebar toggle, logo and menu button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sidebar toggle and Logo
            Row(
              children: [
                _buildSidebarToggleButton(context, false),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _closeUserMenuIfOpen();
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
              ],
            ),
            // Action buttons (chat icon removed)
            Row(
              children: [
                _buildCartIconButton(context, isMobile: true),
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
        // Sidebar toggle button
        _buildSidebarToggleButton(context, isTablet),
        const SizedBox(width: 12),
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
        // Action Buttons (chat icon removed)
        _buildCartIconButton(context),
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
            _onUserIconTap(context, isMobile);
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
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                size: iconSize),
          ),
        ),
      ],
    );
  }

  Future<void> _onUserIconTap(BuildContext context, bool isMobile) async {
    // If closing
    if (_isUserMenuOpen) {
      setState(() => _isUserMenuOpen = false);
      _removeOverlay();
      return;
    }

    // For web, ensure we have a guest user in local storage if no Firebase Auth user exists
    // Note: Guest users are NOT created in Firebase Auth, only stored locally
    if (kIsWeb) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        final hasGuest = await _webGuestService.hasGuestUser();
        if (!hasGuest) {
          final guest = await _webGuestService.createOrGetGuestUser();
          if (guest == null) {
            // No guest available: show sign-in immediately
            final cubit = SignInCubit();
            await showSignInModalWithCubit(context, cubit);
            return;
          }
          // Guest created in local storage, proceed to open menu (no reload needed)
        }
      }
    }

    // Open menu overlay
    setState(() => _isUserMenuOpen = true);
    _showOverlay(context, isMobile);
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

        return SizedBox(
          width: 280,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              // Keep in sync with overlay container maxHeight
              maxHeight: 300,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: isGuest
                    ? _buildGuestMenuItems(context)
                    : _buildAuthenticatedMenuItems(context),
              ),
            ),
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
          // Show sign-in modal for web (without guest option)
          final cubit = SignInCubit();
          showSignInModalWithCubit(context, cubit);
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
          UserSettingsModal.show(context);
        },
      ),
    ];
  }

  List<Widget> _buildAuthenticatedMenuItems(BuildContext context) {
    return [
      _buildUserInfoSection(context),
      _buildMenuItem(
        context,
        icon: Icons.tune,
        title: S.of(context).surveyJoin,
        onTap: () async {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          if (kIsWeb) {
            // Capture overlay before awaiting to avoid deactivated context
            final OverlayState? rootOverlay =
                Overlay.of(context, rootOverlay: true);
            final result = await showSurveyModal(context);
            if (result == 'survey_success') {
              if (rootOverlay != null) {
                SnackbarService.showSuccessAboveOverlay(
                  rootOverlay,
                  title: S.of(context).success,
                  message: S.of(context).surveySubmitted,
                );
              } else {
                // Fallback to ScaffoldMessenger
                SnackbarService.showSuccess(
                  context,
                  title: S.of(context).success,
                  message: S.of(context).surveySubmitted,
                );
              }
            }
          } else {
            Navigator.pushNamed(context, '/user'); // fallback mobile route
          }
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.receipt_long,
        title: S.of(context).myOrders,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          if (kIsWeb) {
            // Ensure hash-based navigation updates the URL and triggers routing
            platform_actions.replaceHashUrl('/orders');
          }
          Navigator.pushNamed(context, '/orders');
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.card_giftcard,
        title: S.of(context).myVouchers,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          Navigator.pushNamed(context, '/vouchers');
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.settings,
        title: S.of(context).settings,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          UserSettingsModal.show(context);
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.logout,
        title: S.of(context).signOut,
        onTap: () {
          setState(() => _isUserMenuOpen = false);
          _removeOverlay();
          _handleLogout(context);
        },
      ),
    ];
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() => _isUserMenuOpen = false);
        _removeOverlay();
        Navigator.pushNamed(context, '/user');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        ),
        child: Row(
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _getCurrentUserInfo(),
              builder: (context, snapshot) {
                final avatarUrl = snapshot.data?['avatarUrl'] as String?;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? Image.network(avatarUrl, fit: BoxFit.cover)
                      : Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _getCurrentUserInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 180,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }

                      final userInfo = snapshot.data;
                      final displayName = userInfo?['displayName'] ??
                          userInfo?['username'] ??
                          userInfo?['email']?.split('@')[0] ??
                          'User';
                      final email = userInfo?['email'] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getCurrentUserInfo() async {
    try {
      // Check if user is authenticated via Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get user info from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          return {
            'displayName': userData['displayName'] ?? userData['username'],
            'username': userData['username'],
            'email': currentUser.email,
            'avatarUrl': userData['avatarUrl'] ?? currentUser.photoURL,
          };
        }

        // Fallback to Firebase Auth user info
        return {
          'displayName': currentUser.displayName,
          'username': currentUser.displayName,
          'email': currentUser.email,
          'avatarUrl': currentUser.photoURL,
        };
      }

      // Check if user is a guest user
      final isGuest = await _webGuestService.isCurrentUserGuest();
      if (isGuest) {
        final guestData = await _webGuestService.getStoredGuestUserData();
        if (guestData != null) {
          return {
            'displayName': guestData['displayName'] ?? guestData['username'],
            'username': guestData['username'],
            'email': guestData['email'],
            'avatarUrl': guestData['avatarUrl'],
          };
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
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

  Widget _buildCartIconButton(BuildContext context, {bool isMobile = false}) {
    final size = isMobile ? 32.0 : 40.0;
    final iconSize = isMobile ? 16.0 : 20.0;

    final cartStream = _getCartStream();

    if (cartStream != null) {
      // Authenticated user - use stream for real-time updates
      return StreamBuilder<QuerySnapshot>(
        stream: cartStream,
        builder: (context, snapshot) {
          int cartCount = 0;

          if (snapshot.hasData && snapshot.data != null) {
            // Calculate total quantity of items in cart
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              cartCount += (data['quantity'] as num?)?.toInt() ?? 0;
            }
          }

          return _buildCartIconWithBadge(
            context,
            cartCount: cartCount,
            size: size,
            iconSize: iconSize,
          );
        },
      );
    } else {
      // Guest user - use FutureBuilder to get initial count
      return FutureBuilder<int>(
        future: _getGuestCartCount(),
        builder: (context, snapshot) {
          final cartCount = snapshot.data ?? 0;
          return _buildCartIconWithBadge(
            context,
            cartCount: cartCount,
            size: size,
            iconSize: iconSize,
          );
        },
      );
    }
  }

  Widget _buildCartIconWithBadge(
    BuildContext context, {
    required int cartCount,
    required double size,
    required double iconSize,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            _handleCartNavigation(context);
          },
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
            child: Icon(Icons.shopping_cart_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
                size: iconSize),
          ),
        ),
        if (cartCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  cartCount > 99 ? '99+' : '$cartCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Stream<QuerySnapshot>? _getCartStream() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Return stream for authenticated users
        return FirebaseFirestore.instance
            .collection('customers')
            .doc(currentUser.uid)
            .collection('carts')
            .snapshots();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cart stream: $e');
      }
    }
    // Return null stream for guests or errors
    return null;
  }

  Future<int> _getGuestCartCount() async {
    try {
      final isGuest = await _webGuestService.isCurrentUserGuest();
      if (isGuest) {
        final cartItems = await _webGuestService.getGuestCart();
        // Calculate total quantity
        int totalCount = 0;
        for (var item in cartItems) {
          totalCount += (item['quantity'] as num?)?.toInt() ?? 0;
        }
        return totalCount;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting guest cart count: $e');
      }
    }
    return 0;
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

    return Stack(
      children: [
        // Tap catcher below the header to allow header buttons to work on first tap
        Positioned(
          top: (_headerKey.currentContext?.findRenderObject() as RenderBox?)
                  ?.size
                  .height ??
              0,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() => _isUserMenuOpen = false);
              _removeOverlay();
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        // The actual submenu, positioned near the user icon
        Positioned(
          left: position.dx - 280 + size.width, // Align right edge with icon
          top: position.dy + size.height + 12,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
                maxWidth: 280,
              ),
              child: GestureDetector(
                onTap: () {}, // Prevent closing when clicking inside menu
                child: _buildUserSubmenu(context, isMobile),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
