import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'dart:async';

class SnackbarService {
  // Removed custom positioning - using default snackbar positioning
  
  /// Shows a snackbar using Overlay to ensure it appears above dialogs
  static void _showOverlaySnackbar(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    Timer? timer;

    void removeSnackbar() {
      overlayEntry.remove();
      timer?.cancel();
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 24,
        left: 16,
        right: 16,
        child: Material(
          elevation: 1000,
          color: Colors.transparent,
          child: Stack(
            children: [
              // Use AwesomeSnackbarContent
              AwesomeSnackbarContent(
                title: title,
                message: message,
                contentType: contentType,
              ),
              // Overlay a transparent container to intercept close button taps
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    // Do nothing - this prevents the close button from working
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds
    timer = Timer(const Duration(seconds: 3), removeSnackbar);
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
    final String message = actionType == 'cart'
        ? S.of(context).loginRequiredForCart
        : S.of(context).loginRequiredForFavorites;

    showHelp(
      context,
      title: title,
      message: message,
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
