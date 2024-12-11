import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../widgets/general/standard_button.dart';
import 'sign_in_cubit.dart';
import 'sign_in_state.dart';
import '../../../widgets/general/app_logo.dart';
import '../../../widgets/general/field_with_icon.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static Widget newInstance() {
    return const SignInScreen();
  }

  @override
  State<SignInScreen> createState() => _SignInScreen();
}

class _SignInScreen extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignInCubit(),
      child: Scaffold(
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
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
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.read<SignInCubit>().sendPasswordResetEmail(_emailController.text.trim());
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
                        if (state is SignInFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Login failed: ${state.error}')),
                          );
                        } else if (state is PasswordResetEmailSent) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset email sent.')),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is SignInLoading) {
                          return const CircularProgressIndicator();
                        }
                        return Column(
                          children: [
                            StandardButton(
                              onPress: () {
                                context.read<SignInCubit>().signInWithEmailPassword(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                  context,
                                );
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
                            StandardButton(
                              onPress: () {
                                context.read<SignInCubit>().signInWithGoogle(context);
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
                        Navigator.pushReplacementNamed(context, '/sign-up');
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
      ),
    );
  }
}