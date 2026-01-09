import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/screens/chat/chat_screen/chat_screen_webview.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_webview.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_cubit.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/services/modal_overlay_service.dart';

class FloatingChat extends StatefulWidget {
  const FloatingChat(
      {super.key, required this.child, required this.navigatorKey});

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<FloatingChat> createState() => _FloatingChatState();
}

class _FloatingChatState extends State<FloatingChat> {
  bool _isOpen = false;
  final WebGuestService _webGuestService = WebGuestService();
  bool _authModalOpen = false;
  ValueNotifier<bool>? _globalModalOpen;
  bool _isHomeReady = false;

  @override
  void initState() {
    super.initState();
    // Wait for home screen to be ready before showing FAB
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHomeReady();
    });
  }

  void _checkHomeReady() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      // Navigator not ready yet, check again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkHomeReady();
      });
      return;
    }

    final currentRoute = ModalRoute.of(navigator.context)?.settings.name;
    // Exclude authentication routes
    final isAuthRoute = currentRoute == '/sign-in' ||
        currentRoute == '/sign-up' ||
        currentRoute == '/forget-password';

    // Check if we're on a main route (home, main, or root after initialization)
    final isMainRoute = (currentRoute == '/' ||
            currentRoute == '/home' ||
            currentRoute == '/main' ||
            currentRoute == null) &&
        !isAuthRoute;

    if (isMainRoute && mounted) {
      // Wait for multiple frames to ensure home screen web is fully rendered
      // This ensures all widgets (BlocBuilder, FutureBuilder, etc.) have completed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Final check after 3 frames + small delay to ensure rendering is complete
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isHomeReady = true;
                });
              }
            });
          });
        });
      });
    } else if (isAuthRoute && _isHomeReady) {
      // Hide FAB if we navigate to auth routes
      if (mounted) {
        setState(() {
          _isHomeReady = false;
        });
      }
    }
  }

  void _toggle() async {
    if (_authModalOpen) return; // prevent re-entrancy while modal visible
    if (!_isOpen) {
      // Check if user is guest before opening chat
      final isGuest = await _webGuestService.isCurrentUserGuest();
      if (isGuest) {
        final overlayState = widget.navigatorKey.currentState!.overlay!;
        final overlayContext = overlayState.context;
        // Show snackbar above dialog; then open sign-in modal
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          SnackbarService.showGuestRestrictionAboveOverlay(
            overlayState,
            context: overlayContext,
            actionType: 'chat',
          );
          final cubit = SignInCubit();
          setState(() => _authModalOpen = true);
          await showSignInModalWithCubit(overlayContext, cubit);
          if (mounted) setState(() => _authModalOpen = false);
        });
        return;
      }
    }
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child; // Only show on web

    _globalModalOpen ??= ModalOverlayService.isModalOpen;
    return ValueListenableBuilder<bool>(
      valueListenable: _globalModalOpen!,
      builder: (context, globalOpen, child) {
        final disableFab = _authModalOpen || globalOpen;
        // Check current route to see if home is ready
        final navigator = widget.navigatorKey.currentState;
        final currentRoute = navigator != null
            ? ModalRoute.of(navigator.context)?.settings.name
            : null;
        final isAuthRoute = currentRoute == '/sign-in' ||
            currentRoute == '/sign-up' ||
            currentRoute == '/forget-password';
        final isMainRoute = (currentRoute == '/' ||
                currentRoute == '/home' ||
                currentRoute == '/main' ||
                currentRoute == null) &&
            !isAuthRoute;

        // Update home ready state if we're on main route
        if (isMainRoute && !_isHomeReady) {
          // Only check once per route change to avoid excessive checks
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkHomeReady();
          });
        } else if (isAuthRoute && _isHomeReady) {
          // Hide FAB if we navigate to auth routes
          if (mounted) {
            setState(() {
              _isHomeReady = false;
            });
          }
        }

        // Responsive panel sizing
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isVerySmall = screenWidth < 400;
        final isSmall = screenWidth < 600;
        
        // Calculate responsive dimensions
        final panelWidth = isVerySmall 
            ? screenWidth - 16  // Almost full width on very small screens
            : (isSmall 
                ? screenWidth * 0.95  // 95% width on small screens
                : 420.0);  // Fixed 420px on larger screens
        final panelHeight = isVerySmall
            ? screenHeight - 120  // Leave space for FAB and top margin
            : (isSmall
                ? screenHeight * 0.75
                : 560.0);
        final rightPosition = isVerySmall ? 8.0 : (isSmall ? 12.0 : 24.0);
        final bottomPosition = isVerySmall ? 80.0 : 96.0;
        
        return Stack(
          children: [
            widget.child,
            // Panel
            if (_isOpen)
              Positioned(
                right: rightPosition,
                bottom: bottomPosition,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isVerySmall ? 12 : 16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(isVerySmall ? 12 : 16),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: panelWidth,
                      height: panelHeight,
                      child: Overlay(
                        initialEntries: [
                          OverlayEntry(
                            builder: (context) =>
                                ChatScreenWebView.newInstance(embedded: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // FAB - only show when home is ready, user is authenticated, AND no modals are open
            if (_isHomeReady && !disableFab)
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, authSnapshot) {
                  // Only show FAB when auth state is active AND user is authenticated
                  // Hide in all other cases: waiting, no user, or guest
                  final isAuthenticated =
                      authSnapshot.connectionState == ConnectionState.active &&
                          authSnapshot.data != null;

                  if (!isAuthenticated) {
                    return const SizedBox.shrink();
                  }

                  // User is authenticated via Firebase - show FAB
                  return Positioned(
                    right: 24,
                    bottom: 24,
                    child: FloatingActionButton(
                      onPressed: _toggle,
                      child: Icon(
                          _isOpen ? Icons.close : Icons.chat_bubble_outline),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
