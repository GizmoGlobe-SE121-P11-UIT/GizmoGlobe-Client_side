import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/gradient_text.dart';
import 'sign_in_cubit.dart';
import 'sign_in_state.dart';
import '../../../widgets/general/app_logo.dart';
import '../../../widgets/general/field_with_icon.dart';
import 'sign_in_webview.dart';
import '../forget_password_screen/forget_password_webview.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static Widget newInstance() {
    return BlocProvider(
      create: (context) => SignInCubit(),
      child: const SignInScreen(),
    );
  }

  @override
  State<SignInScreen> createState() => _SignInScreen();
}

class _SignInScreen extends State<SignInScreen> with WidgetsBindingObserver {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  SignInCubit get cubit => context.read<SignInCubit>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay initialization to ensure proper context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // No automatic modal opening - users will navigate to sign-in explicitly
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {
          // Force rebuild when app resumes
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    const AppLogo(
                      alignment: Alignment.centerRight,
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GradientText(
                        text: S.of(context).login,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FieldWithIcon(
                        controller: _emailController,
                        hintText: S.of(context).email,
                        fillColor: theme.colorScheme.surface,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        textColor: theme.colorScheme.onSurface,
                        hintTextColor: theme.colorScheme.onSurfaceVariant,
                        onChanged: (value) {
                          cubit.emailChanged(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FieldWithIcon(
                        controller: _passwordController,
                        hintText: S.of(context).password,
                        fillColor: theme.colorScheme.surface,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        obscureText: true,
                        textColor: theme.colorScheme.onSurface,
                        hintTextColor: theme.colorScheme.onSurfaceVariant,
                        onChanged: (value) {
                          cubit.passwordChanged(value);
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showForgetPasswordModal(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          S.of(context).forgotPassword,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    BlocConsumer<SignInCubit, SignInState>(
                      listener: (context, state) async {
                        if (state.processState == ProcessState.failure) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext dialogContext) =>
                                  InformationDialog(
                                dialogName: state.dialogName,
                                content: state.message.toString(),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            );
                          }
                          return;
                        }

                        // Handle success state
                        if (state.processState == ProcessState.success) {
                          if (state.isGuestLogin) {
                            // For guest login, navigate directly
                            if (context.mounted) {
                              // Use Future.microtask to avoid emitting after close
                              Future.microtask(() {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/main',
                                );
                              });
                            }
                          } else {
                            // For other login methods, show success dialog first
                            if (context.mounted) {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext dialogContext) =>
                                    InformationDialog(
                                  dialogName: state.dialogName,
                                  content: state.message.toString(),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    if (context.mounted) {
                                      // Use Future.microtask to avoid emitting after close
                                      Future.microtask(() {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/main',
                                        );
                                      });
                                    }
                                  },
                                ),
                              );
                            }
                          }
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state.processState == ProcessState.loading
                              ? null
                              : () async {
                                  cubit.signInWithEmailPassword();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state.processState == ProcessState.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  S.of(context).login,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
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
                              Navigator.pushNamed(context, '/sign-up');
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              S.of(context).or,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Google Sign In Button
                      BlocConsumer<SignInCubit, SignInState>(
                        listener: (context, state) async {
                          if (state.processState == ProcessState.failure) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext dialogContext) =>
                                    InformationDialog(
                                  dialogName: state.dialogName,
                                  content: state.message.toString(),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                              );
                            }
                            return;
                          }

                          // Handle success state
                          if (state.processState == ProcessState.success) {
                            if (context.mounted) {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext dialogContext) =>
                                    InformationDialog(
                                  dialogName: state.dialogName,
                                  content: state.message.toString(),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    if (context.mounted) {
                                      // Use Future.microtask to avoid emitting after close
                                      Future.microtask(() {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/main',
                                        );
                                      });
                                    }
                                  },
                                ),
                              );
                            }
                          }
                        },
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed:
                                  state.processState == ProcessState.loading
                                      ? null
                                      : () async {
                                          await cubit.signInWithGoogle();
                                        },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
                                side: BorderSide(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: state.processState == ProcessState.loading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Loading...',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                        },
                      ),
                      // Web Modal Option - only show on non-web platforms
                      if (!kIsWeb) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            showSignInModalWithCubit(context, cubit);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            'Open Web View',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
