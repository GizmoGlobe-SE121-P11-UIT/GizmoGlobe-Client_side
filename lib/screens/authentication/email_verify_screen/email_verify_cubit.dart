import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_verify_state.dart';

class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EmailVerificationCubit() : super(EmailVerificationInitial());

  Future<void> checkEmailVerification(User user, String name) async {
    emit(EmailVerificationLoading());

    while (!user.emailVerified) {
      await Future.delayed(const Duration(seconds: 5));
      await user.reload();
      user = _auth.currentUser!;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'username': name,
      'email': user.email,
    });

    emit(EmailVerificationSuccess());
  }
}