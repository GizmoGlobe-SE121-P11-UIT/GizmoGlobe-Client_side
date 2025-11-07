import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class SnackbarService {
  // Removed custom positioning - using default snackbar positioning

  /// Shows a snackbar using ScaffoldMessenger (default). Use
  /// [showGuestRestrictionAboveOverlay] if you must ensure above dialogs.
  static void _showOverlaySnackbar(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 3),
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show a snackbar-like overlay ABOVE dialogs using a provided root Overlay
  /// This ensures the snackbar appears on top of all UI elements including modals
  static void _insertOverlaySnackbar(
    OverlayState overlay, {
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    OverlayEntry? overlayEntry;

    // Use multiple post-frame callbacks to ensure we insert AFTER dialogs are fully rendered
    // This guarantees the snackbar overlay entry is added last and appears on top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait one more frame to ensure dialog is completely rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        overlayEntry = OverlayEntry(
          maintainState: false,
          opaque: false, // Allow clicks to pass through the snackbar area
          builder: (context) => Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: IgnorePointer(
              ignoring: false, // Allow interaction with the snackbar itself
              child: Material(
                elevation:
                    9999, // Maximum elevation to appear above all dialogs
                color: Colors.transparent,
                shadowColor:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                child: AwesomeSnackbarContent(
                  title: title,
                  message: message,
                  contentType: contentType,
                ),
              ),
            ),
          ),
        );

        // Insert at the end of overlay entries to ensure it's on top
        // This ensures the snackbar appears above all other overlays including dialogs
        overlay.insert(overlayEntry!);

        // Auto-remove after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          overlayEntry?.remove();
        });
      });
    });
  }

  /// Shows a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showOverlaySnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.success,
    );
  }

  /// Shows an error snackbar
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showOverlaySnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.failure,
    );
  }

  /// Shows a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showOverlaySnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.warning,
    );
  }

  /// Shows a help/info snackbar
  static void showHelp(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showOverlaySnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.help,
    );
  }

  /// Shows a success snackbar for cart operations
  static void showCartSuccess(BuildContext context, String productName) {
    showSuccess(
      context,
      title: S.of(context).success,
      message: '$productName ${S.of(context).addToCart}',
    );
  }

  /// Shows an error snackbar for cart operations
  static void showCartError(BuildContext context) {
    showError(
      context,
      title: S.of(context).error,
      message: S.of(context).failedToAddToCart,
    );
  }

  /// Shows a help snackbar for guest restrictions
  static void showGuestRestriction(
    BuildContext context, {
    required String actionType,
  }) {
    final String title = S.of(context).loginRequired;
    String message;

    switch (actionType) {
      case 'cart':
        message = S.of(context).loginRequiredForCart;
        break;
      case 'favorites':
        message = S.of(context).loginRequiredForFavorites;
        break;
      case 'chat':
        message = S.of(context).loginRequiredForChat;
        break;
      default:
        message = S.of(context).loginRequired;
    }

    showHelp(
      context,
      title: title,
      message: message,
    );
  }

  /// Same as [showGuestRestriction] but guarantees it appears above dialogs
  static void showGuestRestrictionAboveOverlay(
    OverlayState overlay, {
    required BuildContext context,
    required String actionType,
  }) {
    final String title = S.of(context).loginRequired;
    String message;

    switch (actionType) {
      case 'cart':
        message = S.of(context).loginRequiredForCart;
        break;
      case 'favorites':
        message = S.of(context).loginRequiredForFavorites;
        break;
      case 'chat':
        message = S.of(context).loginRequiredForChat;
        break;
      case 'google_cancelled':
        message = 'Google sign-in was cancelled. You can try again anytime.';
        break;
      default:
        message = S.of(context).loginRequired;
    }

    _insertOverlaySnackbar(
      overlay,
      title: actionType == 'google_cancelled' ? 'Google Sign-In' : title,
      message: message,
      contentType: ContentType.help,
    );
  }

  /// Shows an error snackbar above dialogs using overlay
  static void showErrorAboveOverlay(
    OverlayState overlay, {
    required String title,
    required String message,
  }) {
    _insertOverlaySnackbar(
      overlay,
      title: title,
      message: message,
      contentType: ContentType.failure,
    );
  }

  /// Shows a success snackbar above dialogs using overlay
  static void showSuccessAboveOverlay(
    OverlayState overlay, {
    required String title,
    required String message,
  }) {
    _insertOverlaySnackbar(
      overlay,
      title: title,
      message: message,
      contentType: ContentType.success,
    );
  }

  /// Shows a favorite success snackbar
  static void showFavoriteSuccess(BuildContext context, String action) {
    showSuccess(
      context,
      title: S.of(context).success,
      message: action == 'added'
          ? S.of(context).addedToFavorites
          : S.of(context).removedFromFavorites,
    );
  }

  /// Shows a favorite error snackbar
  static void showFavoriteError(BuildContext context) {
    showError(
      context,
      title: S.of(context).error,
      message: S.of(context).failedToUpdateFavorites,
    );
  }

  /// Test method to verify snackbar functionality
  static void showTestSnackbar(BuildContext context) {
    showSuccess(
      context,
      title: 'Test',
      message: 'Snackbar is working!',
    );
  }
}
