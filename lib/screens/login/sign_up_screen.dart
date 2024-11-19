import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/app_logo.dart';
import '../../widgets/bordered_icon_button.dart';
import '../../widgets/field_with_icon.dart';
import '../../widgets/standard_button.dart';
import 'email_verify_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signUp(BuildContext context) async {
    try {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      // Check if the 'users' collection exists
      final CollectionReference usersCollection = _firestore.collection('users');
      final DocumentSnapshot doc = await usersCollection.doc('dummyDoc').get();

      if (!doc.exists) {
        // Create the 'users' collection by adding a dummy document and then deleting it
        await usersCollection.doc('dummyDoc').set({'exists': true});
        await usersCollection.doc('dummyDoc').delete();
      }

      // Add user data to Firestore
      await usersCollection.doc(userCredential.user!.uid).set({
        'username': name,
        'email': email,
        'userid': userCredential.user!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A verification email has been sent to your email address. Please verify your email to continue.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
                user: userCredential.user!,
                name: name,
              ),
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        print('Sign up failed: $error');
      }
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BorderedIconButton(
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
              StandardButton(
                onPress: () => _signUp(context),
                text: 'Create account',
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}