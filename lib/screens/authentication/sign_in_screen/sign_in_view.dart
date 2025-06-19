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
                        boxShadow: [
                          BoxShadow(
                            color: theme.brightness == Brightness.light
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                        boxShadow: [
                          BoxShadow(
                            color: theme.brightness == Brightness.light
                                ? Colors.black.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                          Navigator.pushNamed(context, '/forget-password');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          S.of(context).forgotPassword,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
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
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/main',
                                  (route) => false,
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
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/main',
                                          (route) => false,
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
                          onPressed:
                              state.processState == ProcessState.loading
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                              foregroundColor:
                                  theme.colorScheme.primary.withValues(alpha: 0.8),
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
                      TextButton(
                        onPressed: () async {
                          try {
                            await cubit.signInAsGuest();
                            if (context.mounted) {
                              // Use Future.microtask to avoid emitting after close
                              Future.microtask(() {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/main',
                                  (route) => false,
                                );
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) =>
                                    InformationDialog(
                                  title: S.of(context).error,
                                  content:
                                      S.of(context).failedToSigninAsGuest,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          S.of(context).continueAsGuest,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
