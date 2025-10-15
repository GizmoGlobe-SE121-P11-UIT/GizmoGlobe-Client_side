import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'sign_up_cubit.dart';
import 'sign_up_state.dart';

/// Helper function to show the sign-up modal
void showSignUpModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return SignUpWebModal.newInstance();
    },
  );
}

class SignUpWebModal extends StatefulWidget {
  const SignUpWebModal({super.key});

  static Widget newInstance() {
    return BlocProvider(
      create: (context) => SignUpCubit(),
      child: const SignUpWebModal(),
    );
  }

  @override
  State<SignUpWebModal> createState() => _SignUpWebModalState();
}

class _SignUpWebModalState extends State<SignUpWebModal> {
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                          text: S.of(context).register,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        context,
                        controller: _nameController,
                        hintText: S.of(context).enterFullName,
                        onChanged: (value) => cubit.updateUsername(value),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        context,
                        controller: _emailController,
                        hintText: S.of(context).enterYourEmail,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => cubit.updateEmail(value),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        context,
                        controller: _phoneController,
                        hintText: S.of(context).enterPhoneNumber,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) => cubit.updatePhoneNumber(value),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        context,
                        controller: _passwordController,
                        hintText: S.of(context).enterPassword,
                        obscureText: true,
                        onChanged: (value) => cubit.updatePassword(value),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        context,
                        controller: _confirmPasswordController,
                        hintText: S.of(context).enterConfirmPassword,
                        obscureText: true,
                        onChanged: (value) =>
                            cubit.updateConfirmPassword(value),
                      ),
                      const SizedBox(height: 24),
                      BlocConsumer<SignUpCubit, SignUpState>(
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
                            // Close modal after showing success snackbar
                            Navigator.of(context).pop();
                          }
                        },
                        buildWhen: (previous, current) =>
                            previous.processState != current.processState,
                        builder: (context, state) {
                          return _buildSignUpButton(context, state);
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
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
                              Navigator.of(context).pop();
                              // TODO: Open sign-in modal
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  theme.colorScheme.primary.withValues(alpha: 0.8),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildSignUpButton(BuildContext context, SignUpState state) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: state.processState == ProcessState.loading
          ? null
          : () async {
              await cubit.signUp();
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
                  S.of(context).register,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
