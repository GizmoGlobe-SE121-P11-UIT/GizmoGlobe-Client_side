import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class SnackbarService {
  // Removed custom positioning - using default snackbar positioning

  /// Shows a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.success,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Shows an error snackbar
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Shows a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.warning,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Shows a help/info snackbar
  static void showHelp(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.help,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
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
