import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

/// Snackbar type for styling
enum _SnackbarType { success, error, warning, info }

class SnackbarService {
  /// Shows a snackbar at the bottom of the screen
  static void _showSnackbar(
    BuildContext context, {
    required String title,
    required String message,
    required _SnackbarType type,
  }) {
    final overlay = Overlay.of(context);
    _insertSnackbar(
      overlay,
      title: title,
      message: message,
      type: type,
    );
  }

  /// Insert snackbar using overlay (works above dialogs)
  static void _insertSnackbar(
    OverlayState overlay, {
    required String title,
    required String message,
    required _SnackbarType type,
  }) {
    Widget snackbar;

    switch (type) {
      case _SnackbarType.success:
        snackbar = CustomSnackBar.success(
          message: '$title: $message',
          maxLines: 3,
        );
        break;
      case _SnackbarType.error:
        snackbar = CustomSnackBar.error(
          message: '$title: $message',
          maxLines: 3,
        );
        break;
      case _SnackbarType.warning:
        snackbar = _buildCustomSnackbar(
          title: title,
          message: message,
          backgroundColor: Colors.orange.shade600,
          icon: Icons.warning_amber_rounded,
        );
        break;
      case _SnackbarType.info:
        snackbar = CustomSnackBar.info(
          message: '$title: $message',
          maxLines: 3,
        );
        break;
    }

    showTopSnackBar(
      overlay,
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: snackbar,
        ),
      ),
      snackBarPosition: SnackBarPosition.bottom,
      animationDuration: const Duration(milliseconds: 300),
      displayDuration: const Duration(seconds: 3),
    );
  }

  /// Build a custom styled snackbar for types not provided by the package
  static Widget _buildCustomSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context,
      title: title,
      message: message,
      type: _SnackbarType.success,
    );
  }

  /// Shows an error snackbar
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context,
      title: title,
      message: message,
      type: _SnackbarType.error,
    );
  }

  /// Shows a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context,
      title: title,
      message: message,
      type: _SnackbarType.warning,
    );
  }

  /// Shows a help/info snackbar
  static void showHelp(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context,
      title: title,
      message: message,
      type: _SnackbarType.info,
    );
  }

  /// Shows a success snackbar for cart operations
  static void showCartSuccess(BuildContext context, String productName) {
    final locale = Localizations.localeOf(context);
    final String message;
    if (locale.languageCode == 'vi') {
      // Vietnamese: "Thêm vào giỏ hàng Product Name"
      message = '${S.of(context).addToCart} $productName';
    } else {
      // English: "Product Name Add to Cart"
      message = '$productName ${S.of(context).addToCart}';
    }
    showSuccess(
      context,
      title: S.of(context).success,
      message: message,
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
        message = S.of(context).googleSignInCancelled;
        break;
      default:
        message = S.of(context).loginRequired;
    }

    _insertSnackbar(
      overlay,
      title: actionType == 'google_cancelled' ? 'Google Sign-In' : title,
      message: message,
      type: _SnackbarType.info,
    );
  }

  /// Shows an error snackbar above dialogs using overlay
  static void showErrorAboveOverlay(
    OverlayState overlay, {
    required String title,
    required String message,
  }) {
    _insertSnackbar(
      overlay,
      title: title,
      message: message,
      type: _SnackbarType.error,
    );
  }

  /// Shows a success snackbar above dialogs using overlay
  static void showSuccessAboveOverlay(
    OverlayState overlay, {
    required String title,
    required String message,
  }) {
    _insertSnackbar(
      overlay,
      title: title,
      message: message,
      type: _SnackbarType.success,
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
