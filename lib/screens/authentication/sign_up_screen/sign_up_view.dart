import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/general/app_logo.dart';
import '../../../widgets/general/field_with_icon.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/general/standard_button.dart';
import '../email_verify_screen/email_verify_view.dart';
import 'sign_up_cubit.dart';
import 'sign_up_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static Widget newInstance() {
    return const SignUpScreen();
  }

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpCubit(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GradientIconButton(
            icon: Icons.chevron_left,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      'Create account',
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
                  controller: _nameController,
                  hintText: 'Full name',
                  fillColor: Theme.of(context).colorScheme.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  textColor: Theme.of(context).colorScheme.primary,
                  hintTextColor: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 16.0),
                FieldWithIcon(
                  controller: _emailController,
                  hintText: 'Email address',
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
                const SizedBox(height: 16.0),
                FieldWithIcon(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm password',
                  fillColor: Theme.of(context).colorScheme.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  obscureText: true,
                  textColor: Theme.of(context).colorScheme.primary,
                  hintTextColor: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 30),
                BlocConsumer<SignUpCubit, SignUpState>(
                  listener: (context, state) {
                    if (state is SignUpFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign up failed: ${state.error}')),
                      );
                    } else if (state is SignUpSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A verification email has been sent to your email address. Please verify your email to continue.')),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailVerificationScreen(
                            user: state.user,
                            name: _nameController.text.trim(),
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is SignUpLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return StandardButton(
                      onPress: () {
                        context.read<SignUpCubit>().signUp(
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                          _confirmPasswordController.text.trim(),
                          context,
                        );
                      },
                      text: 'Create account',
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}