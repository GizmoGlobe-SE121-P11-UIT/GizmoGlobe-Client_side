import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../enums/processing/process_state_enum.dart';
import 'forget_password_cubit.dart';
import '../../../widgets/general/app_logo.dart';
import '../../../widgets/general/field_with_icon.dart';
import 'forget_password_state.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  static Widget newInstance() {
    return BlocProvider(
      create: (context) => ForgetPasswordCubit(),
      child: const ForgetPasswordScreen(),
    );
  }

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  ForgetPasswordCubit get cubit => context.read<ForgetPasswordCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ).createShader(bounds);
            },
            child: const Icon(
              Icons.chevron_left,
              size: 32,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const AppLogo(
                  alignment: Alignment.centerRight,
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GradientText(
                      text: S.of(context).forgetPassword, fontSize: 32),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    S.of(context).forgetPasswordDescription,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    S.of(context).emailAddress,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FieldWithIcon(
                  controller: _emailController,
                  hintText: S.of(context).enterYourEmail,
                  fillColor: Theme.of(context).colorScheme.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  obscureText: false,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  hintTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  onChanged: (value) {
                    cubit.emailChanged(value);
                  },
                ),
                const SizedBox(height: 40.0),
                BlocListener<ForgetPasswordCubit, ForgetPasswordState>(
                  listener: (context, state) {
                    if (state.processState == ProcessState.success) {
                      showDialog(
                        context: context,
                        builder: (context) => InformationDialog(
                          title: state.dialogName.toString(),
                          content: state.message.toString(),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/sign-in');
                          },
                        ),
                      );
                    } else if (state.processState == ProcessState.failure) {
                      showDialog(
                        context: context,
                        builder: (context) => InformationDialog(
                          title: state.dialogName.toString(),
                          content: state.message.toString(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        cubit
                            .sendVerificationLink(_emailController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        S.of(context).sendVerificationLink,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
