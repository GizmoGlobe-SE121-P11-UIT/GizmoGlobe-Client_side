import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final double _panelWidth = 420;
  final double _panelHeight = 560;
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

        return Stack(
          children: [
            widget.child,
            // Panel
            if (_isOpen)
              Positioned(
                right: 24,
                bottom: 96,
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: _panelWidth,
                    height: _panelHeight,
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
            // FAB - only show when home is ready
            if (_isHomeReady)
              Positioned(
                right: 24,
                bottom: 24,
                child: IgnorePointer(
                  ignoring: disableFab,
                  child: AnimatedOpacity(
                    opacity: disableFab ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: FloatingActionButton(
                      onPressed: _toggle,
                      child: Icon(
                          _isOpen ? Icons.close : Icons.chat_bubble_outline),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
