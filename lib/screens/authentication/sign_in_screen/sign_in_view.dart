import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/gradient_text.dart';
import '../../../widgets/general/gradient_button.dart';
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

class _SignInScreen extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  SignInCubit get cubit => context.read<SignInCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const SizedBox(height: 80),
                  const AppLogo(
                    alignment: Alignment.centerRight,
                  ),
                  const SizedBox(height: 32),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: GradientText(
                      text: 'Sign in',
                      fontSize: 32),
                  ),
                  const SizedBox(height: 30),

                  FieldWithIcon(
                    controller: _emailController,
                    hintText: 'Your email',
                    fillColor: Theme.of(context).colorScheme.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    textColor: Theme.of(context).colorScheme.primary,
                    hintTextColor: Theme.of(context).colorScheme.onPrimary,
                    onChange: (value) {
                      cubit.emailChanged(value);
                    },
                  ),
                  const SizedBox(height: 16.0),

                  FieldWithIcon(
                    controller: _passwordController,
                    hintText: 'Password',
                    fillColor: Theme.of(context).colorScheme.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    obscureText: true,
                    textColor: Theme.of(context).colorScheme.primary,
                    hintTextColor: Theme.of(context).colorScheme.onPrimary,
                    onChange: (value) {
                      cubit.passwordChanged(value);
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forget-password');
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  BlocConsumer<SignInCubit, SignInState>(
                    listener: (context, state) {
                      if (state.processState == ProcessState.failure) {
                        showDialog(
                          context: context,
                          builder: (context) => InformationDialog(
                            title: state.dialogName.toString(),
                            content: state.message.toString(),
                          ),
                        );
                      }

                      if (state.processState == ProcessState.success) {
                        showDialog(
                            context: context,
                            builder: (context) => InformationDialog(
                              title: state.dialogName.toString(),
                              content: state.message.toString(),
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/main');
                              },
                            ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state.processState == ProcessState.loading) {
                        return const CircularProgressIndicator();
                      }
                      return Column(
                        children: [
                          GradientButton(
                            onPress: () {
                              cubit.signInWithEmailPassword();
                            },
                            text: 'Sign in',
                            gradient: LinearGradient(
                              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Theme.of(context).colorScheme.primary)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'or',
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              Expanded(child: Divider(color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GradientButton(
                            onPress: () {
                              cubit.signInWithGoogle();
                            },
                            text: 'Continue with Google',
                            gradient: LinearGradient(
                              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/sign-up');
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}