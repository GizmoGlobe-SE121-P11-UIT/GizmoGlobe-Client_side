import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'sign_in_cubit.dart';
import 'sign_in_state.dart';
import '../sign_up_screen/sign_up_webview.dart';
import '../forget_password_screen/forget_password_webview.dart';
import 'package:gizmoglobe_client/services/modal_overlay_service.dart';

/// Helper function to show the sign-in modal
Future<void> showSignInModal(BuildContext context) {
  ModalOverlayService.setOpen(true);
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return SignInWebModal.newInstance();
    },
  ).whenComplete(() => ModalOverlayService.setOpen(false));
}

/// Helper function to show the sign-in modal with existing cubit
Future<void> showSignInModalWithCubit(BuildContext context, SignInCubit cubit) {
  ModalOverlayService.setOpen(true);
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return SignInWebModal.withCubit(cubit);
    },
  ).whenComplete(() => ModalOverlayService.setOpen(false));
}

/// Helper function to show the sign-in modal for web (without guest option)
Future<void> showSignInModalForWeb(BuildContext context, SignInCubit cubit) {
  ModalOverlayService.setOpen(true);
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return SignInWebModal.withCubit(cubit, showGuestOption: false);
    },
  ).whenComplete(() => ModalOverlayService.setOpen(false));
}

class SignInWebModal extends StatefulWidget {
  final bool showGuestOption;

  const SignInWebModal({super.key, this.showGuestOption = false});

  static Widget newInstance({bool showGuestOption = false}) {
    return BlocProvider(
      create: (context) => SignInCubit(),
      child: SignInWebModal(showGuestOption: showGuestOption),
    );
  }

  static Widget withCubit(SignInCubit cubit, {bool showGuestOption = false}) {
    return BlocProvider.value(
      value: cubit,
      child: SignInWebModal(showGuestOption: showGuestOption),
    );
  }

  @override
  State<SignInWebModal> createState() => _SignInWebModalState();
}

class _SignInWebModalState extends State<SignInWebModal> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  SignInCubit get cubit => context.read<SignInCubit>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth <= 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth - 32 : 500,
          maxHeight: screenHeight * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const AppLogo(alignment: Alignment.centerLeft),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GradientText(
                          text: S.of(context).login,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        context,
                        controller: _emailController,
                        hintText: S.of(context).enterYourEmail,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => cubit.emailChanged(value),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        context,
                        controller: _passwordController,
                        hintText: S.of(context).enterPassword,
                        obscureText: true,
                        onChanged: (value) => cubit.passwordChanged(value),
                      ),
                      const SizedBox(height: 12),
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            S.of(context).forgotPassword,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BlocConsumer<SignInCubit, SignInState>(
                        listenWhen: (previous, current) =>
                            previous.processState != current.processState,
                        listener: (context, state) {
                          // Handle loading state
                          if (state.processState == ProcessState.loading) {
                            // Loading is handled by the button state
                            return;
                          }

                          // Handle failure state
                          if (state.processState == ProcessState.failure) {
                            SnackbarService.showError(
                              context,
                              title: state.dialogName.toString(),
                              message: state.message.toString(),
                            );
                            return;
                          }

                          // Handle success state
                          if (state.processState == ProcessState.success) {
                            SnackbarService.showSuccess(
                              context,
                              title: state.dialogName.toString(),
                              message: state.message.toString(),
                            );
                            // Close modal and navigate on next frame using root navigator
                            Navigator.of(context, rootNavigator: true).pop();
                            if (context.mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Navigator.of(context, rootNavigator: true)
                                    .pushNamedAndRemoveUntil(
                                        '/main', (r) => false);
                              });
                            }
                          }
                        },
                        buildWhen: (previous, current) =>
                            previous.processState != current.processState,
                        builder: (context, state) {
                          return _buildSignInButton(context, state);
                        },
                      ),
                      const SizedBox(height: 20),
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            S.of(context).dontHaveAccount,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Open sign-up modal
                              showSignUpModal(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.8),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              S.of(context).register,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: theme.dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: theme.dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Google Sign In Button
                      BlocConsumer<SignInCubit, SignInState>(
                        listenWhen: (previous, current) =>
                            previous.processState != current.processState,
                        listener: (context, state) {
                          if (state.processState == ProcessState.success) {
                            SnackbarService.showSuccess(
                              context,
                              title: state.dialogName.toString(),
                              message: state.message.toString(),
                            );
                            Navigator.of(context, rootNavigator: true).pop();
                            if (context.mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Navigator.of(context, rootNavigator: true)
                                    .pushNamedAndRemoveUntil(
                                        '/main', (r) => false);
                              });
                            }
                          } else if (state.processState ==
                              ProcessState.failure) {
                            SnackbarService.showError(
                              context,
                              title: state.dialogName.toString(),
                              message: state.message.toString(),
                            );
                          }
                        },
                        buildWhen: (previous, current) =>
                            previous.processState != current.processState,
                        builder: (context, state) {
                          return _buildGoogleSignInButton(context, state);
                        },
                      ),
                      // Guest Login - only show if showGuestOption is true
                      if (widget.showGuestOption) ...[
                        const SizedBox(height: 16),
                        BlocConsumer<SignInCubit, SignInState>(
                          listenWhen: (previous, current) =>
                              previous.processState != current.processState,
                          listener: (context, state) {
                            if (state.processState == ProcessState.success) {
                              SnackbarService.showSuccess(
                                context,
                                title: state.dialogName.toString(),
                                message: state.message.toString(),
                              );
                              Navigator.of(context, rootNavigator: true).pop();
                              if (context.mounted) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamedAndRemoveUntil(
                                          '/main', (r) => false);
                                });
                              }
                            } else if (state.processState ==
                                ProcessState.failure) {
                              SnackbarService.showError(
                                context,
                                title: state.dialogName.toString(),
                                message: state.message.toString(),
                              );
                            }
                          },
                          buildWhen: (previous, current) =>
                              previous.processState != current.processState,
                          builder: (context, state) {
                            return _buildGuestSignInButton(context, state);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FieldWithIcon(
        controller: controller,
        hintText: hintText,
        fillColor: theme.colorScheme.surface,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        textColor: theme.colorScheme.onSurface,
        hintTextColor: theme.colorScheme.onSurfaceVariant,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context, SignInState state) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: state.processState == ProcessState.loading
          ? null
          : () async {
              await cubit.signInWithEmailPassword();
            },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: state.processState == ProcessState.loading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
                  S.of(context).login,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, SignInState state) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: state.processState == ProcessState.loading
            ? null
            : () async {
                await cubit.signInWithGoogle();
              },
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.processState == ProcessState.loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Logo SVG
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: GoogleLogoPainter(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGuestSignInButton(BuildContext context, SignInState state) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: state.processState == ProcessState.loading
          ? null
          : () async {
              await cubit.signInAsGuest();
            },
      child: state.processState == ProcessState.loading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            )
          : Text(
              S.of(context).continueAsGuest,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
    );
  }

  void _handleForgotPassword() {
    Navigator.of(context).pop();
    showForgetPasswordModal(context);
  }
}

/// Google Logo Painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.94, size.height * 0.51)
        ..cubicTo(size.width * 0.94, size.height * 0.44, size.width * 0.93,
            size.height * 0.38, size.width * 0.91, size.height * 0.32)
        ..lineTo(size.width * 0.5, size.height * 0.32)
        ..lineTo(size.width * 0.5, size.height * 0.50)
        ..lineTo(size.width * 0.75, size.height * 0.50)
        ..cubicTo(size.width * 0.74, size.height * 0.56, size.width * 0.71,
            size.height * 0.61, size.width * 0.66, size.height * 0.64)
        ..lineTo(size.width * 0.66, size.height * 0.76)
        ..lineTo(size.width * 0.81, size.height * 0.76)
        ..cubicTo(size.width * 0.90, size.height * 0.68, size.width * 0.94,
            size.height * 0.60, size.width * 0.94, size.height * 0.51)
        ..close(),
      paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.96)
        ..cubicTo(size.width * 0.62, size.height * 0.96, size.width * 0.73,
            size.height * 0.92, size.width * 0.80, size.height * 0.85)
        ..lineTo(size.width * 0.66, size.height * 0.76)
        ..cubicTo(size.width * 0.62, size.height * 0.79, size.width * 0.56,
            size.height * 0.80, size.width * 0.50, size.height * 0.80)
        ..cubicTo(size.width * 0.38, size.height * 0.80, size.width * 0.28,
            size.height * 0.72, size.width * 0.24, size.height * 0.61)
        ..lineTo(size.width * 0.09, size.height * 0.61)
        ..lineTo(size.width * 0.09, size.height * 0.73)
        ..cubicTo(size.width * 0.17, size.height * 0.86, size.width * 0.32,
            size.height * 0.96, size.width * 0.50, size.height * 0.96)
        ..close(),
      paint,
    );

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.24, size.height * 0.59)
        ..cubicTo(size.width * 0.23, size.height * 0.56, size.width * 0.23,
            size.height * 0.53, size.width * 0.23, size.height * 0.50)
        ..cubicTo(size.width * 0.23, size.height * 0.47, size.width * 0.23,
            size.height * 0.44, size.width * 0.24, size.height * 0.41)
        ..lineTo(size.width * 0.24, size.height * 0.29)
        ..lineTo(size.width * 0.09, size.height * 0.29)
        ..cubicTo(size.width * 0.06, size.height * 0.36, size.width * 0.04,
            size.height * 0.43, size.width * 0.04, size.height * 0.50)
        ..cubicTo(size.width * 0.04, size.height * 0.57, size.width * 0.06,
            size.height * 0.64, size.width * 0.09, size.height * 0.71)
        ..lineTo(size.width * 0.21, size.height * 0.62)
        ..lineTo(size.width * 0.24, size.height * 0.59)
        ..close(),
      paint,
    );

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.22)
        ..cubicTo(size.width * 0.57, size.height * 0.22, size.width * 0.63,
            size.height * 0.25, size.width * 0.68, size.height * 0.29)
        ..lineTo(size.width * 0.81, size.height * 0.16)
        ..cubicTo(size.width * 0.73, size.height * 0.09, size.width * 0.62,
            size.height * 0.04, size.width * 0.50, size.height * 0.04)
        ..cubicTo(size.width * 0.32, size.height * 0.04, size.width * 0.17,
            size.height * 0.14, size.width * 0.09, size.height * 0.29)
        ..lineTo(size.width * 0.24, size.height * 0.41)
        ..cubicTo(size.width * 0.28, size.height * 0.30, size.width * 0.38,
            size.height * 0.22, size.width * 0.50, size.height * 0.22)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
