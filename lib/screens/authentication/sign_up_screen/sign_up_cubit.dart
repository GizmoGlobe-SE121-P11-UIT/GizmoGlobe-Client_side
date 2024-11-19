import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SignUpCubit() : super(SignUpInitial());

  Future<void> signUp(String name, String email, String password, String confirmPassword, BuildContext context) async {
    if (password != confirmPassword) {
      emit(SignUpFailure('Passwords do not match'));
      return;
    }

    try {
      emit(SignUpLoading());
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.sendEmailVerification();

      final CollectionReference usersCollection = _firestore.collection('users');
      final DocumentSnapshot doc = await usersCollection.doc('dummyDoc').get();

      if (!doc.exists) {
        await usersCollection.doc('dummyDoc').set({'exists': true});
        await usersCollection.doc('dummyDoc').delete();
      }

      await usersCollection.doc(userCredential.user!.uid).set({
        'username': name,
        'email': email,
        'userid': userCredential.user!.uid,
      });

      emit(SignUpSuccess(userCredential.user!));
    } catch (error) {
      emit(SignUpFailure(error.toString()));
    }
  }
}