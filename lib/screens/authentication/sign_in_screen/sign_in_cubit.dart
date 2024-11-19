import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SignInCubit() : super(SignInInitial());

  Future<void> signInWithEmailPassword(String email, String password, BuildContext context) async {
    try {
      emit(SignInLoading());
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        emit(SignInSuccess());
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (error) {
      emit(SignInFailure(error.toString()));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      emit(PasswordResetEmailSent());
    } catch (error) {
      emit(SignInFailure(error.toString()));
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      emit(SignInLoading());
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(SignInInitial());
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        emit(SignInSuccess());
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (error) {
      emit(SignInFailure(error.toString()));
    }
  }
}