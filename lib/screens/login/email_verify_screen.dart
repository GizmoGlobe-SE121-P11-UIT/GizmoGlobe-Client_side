import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/bordered_icon_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;
  final String name;

  const EmailVerificationScreen({super.key, required this.user, required this.name});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    User? user = widget.user;

    while (!user!.emailVerified) {
      await Future.delayed(const Duration(seconds: 5));
      await user.reload();
      user = _auth.currentUser!;
    }

    // Save the user's name, email, and UID to Firestore after verification
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'username': widget.name,
      'email': user.email,
    });

    // Navigate to the main screen after successful sign-up and email verification
    Navigator.pushReplacementNamed(context, '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: const Text(
              'Email Verification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        leading: BorderedIconButton(
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
          child: Column(
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
          ),
        ),
      ),
    );
  }
}
