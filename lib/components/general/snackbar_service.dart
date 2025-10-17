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
  static void _insertOverlaySnackbar(
    OverlayState overlay, {
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: Material(
          elevation: 1000,
          color: Colors.transparent,
          child: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: contentType,
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
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
      default:
        message = S.of(context).loginRequired;
    }

    _insertOverlaySnackbar(
      overlay,
      title: title,
      message: message,
      contentType: ContentType.help,
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
