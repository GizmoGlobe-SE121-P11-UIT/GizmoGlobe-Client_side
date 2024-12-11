import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/general/gradient_text.dart';
import 'email_verify_cubit.dart';
import 'email_verify_state.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;
  final String name;

  const EmailVerificationScreen({super.key, required this.user, required this.name});

  static Widget newInstance(User user, String name) {
    return EmailVerificationScreen(user: user, name: name);
  }

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EmailVerificationCubit>().checkEmailVerification(widget.user, widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmailVerificationCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: GradientText(text: 'Email Verification'),
          ),
          leading: GradientIconButton(
            icon: Icons.chevron_left,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: BlocBuilder<EmailVerificationCubit, EmailVerificationState>(
              builder: (context, state) {
                if (state is EmailVerificationSuccess) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacementNamed(context, '/sign-in');
                  });
                  return const SizedBox.shrink();
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Please verify your email to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}