import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/app_logo.dart';
import '../../../widgets/general/field_with_icon.dart';
import '../../../widgets/general/gradient_text.dart';
import 'sign_up_cubit.dart';
import 'sign_up_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static Widget newInstance() {
    return BlocProvider(
      create: (context) => SignUpCubit(),
      child: const SignUpScreen(),
    );
  }

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  SignUpCubit get cubit => context.read<SignUpCubit>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sign-in',
            (route) => false,
          );
        }
      },
      child: Scaffold(
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
                          text: S.of(context).register,
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
                          controller: _nameController,
                          hintText: S.of(context).enterFullName,
                          fillColor: theme.colorScheme.surface,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          textColor: theme.colorScheme.onSurface,
                          hintTextColor: theme.colorScheme.onSurfaceVariant,
                          onChanged: (value) {
                            cubit.updateUsername(value);
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
                          controller: _emailController,
                          hintText: S.of(context).enterYourEmail,
                          fillColor: theme.colorScheme.surface,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          textColor: theme.colorScheme.onSurface,
                          hintTextColor: theme.colorScheme.onSurfaceVariant,
                          onChanged: (value) {
                            cubit.updateEmail(value);
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
                          controller: _phoneController,
                          hintText: S.of(context).enterPhoneNumber,
                          fillColor: theme.colorScheme.surface,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          textColor: theme.colorScheme.onSurface,
                          hintTextColor: theme.colorScheme.onSurfaceVariant,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            cubit.updatePhoneNumber(value);
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
                          hintText: S.of(context).enterPassword,
                          fillColor: theme.colorScheme.surface,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          obscureText: true,
                          textColor: theme.colorScheme.onSurface,
                          hintTextColor: theme.colorScheme.onSurfaceVariant,
                          onChanged: (value) {
                            cubit.updatePassword(value);
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
                          controller: _confirmPasswordController,
                          hintText: S.of(context).enterConfirmPassword,
                          fillColor: theme.colorScheme.surface,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          obscureText: true,
                          textColor: theme.colorScheme.onSurface,
                          hintTextColor: theme.colorScheme.onSurfaceVariant,
                          onChanged: (value) {
                            cubit.updateConfirmPassword(value);
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      BlocConsumer<SignUpCubit, SignUpState>(
                        listenWhen: (previous, current) =>
                            previous.processState != current.processState,
                        listener: (context, state) {
                          // Handle loading state
                          if (state.processState == ProcessState.loading) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );
                            return;
                          }

                          // Close loading dialog if it's showing
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }

                          // Handle failure state
                          if (state.processState == ProcessState.failure) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) =>
                                  InformationDialog(
                                title: state.dialogName.toString(),
                                content: state.message.toString(),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                            return;
                          }

                          // Handle success state
                          if (state.processState == ProcessState.success) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) =>
                                  InformationDialog(
                                title: state.dialogName.toString(),
                                content: state.message.toString(),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/sign-in',
                                    (route) => false,
                                  );
                                },
                              ),
                            );
                          }
                        },
                        buildWhen: (previous, current) =>
                            previous.processState != current.processState,
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed:
                                state.processState == ProcessState.loading
                                    ? null
                                    : () async {
                                        await cubit.signUp();
                                      },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                child: Text(
                                  S.of(context).register,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).alreadyHaveAccount,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/sign-in',
                              (route) => false,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            S.of(context).login,
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
      ),
    );
  }
}
