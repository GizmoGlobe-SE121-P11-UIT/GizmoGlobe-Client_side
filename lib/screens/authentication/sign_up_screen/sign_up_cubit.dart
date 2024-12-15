import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/enums/processing/notify_message_enum.dart';
import 'sign_up_state.dart';
import '../../../enums/processing/process_state_enum.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SignUpCubit() : super(const SignUpState());

  void updateUsername(String username) {
    emit(state.copyWith(username: username));
  }

  void updateEmail(String email) {
    emit(state.copyWith(email: email));
  }

  void updatePassword(String password) {
    emit(state.copyWith(password: password));
  }

  void updateConfirmPassword(String confirmPassword) {
    emit(state.copyWith(confirmPassword: confirmPassword));
  }

  Future<void> signUp() async {
    if (state.password != state.confirmPassword) {
      emit(const SignUpState(processState: ProcessState.failure, message: NotifyMessage.msg5));
      return;
    }

    try {
      emit(const SignUpState(processState: ProcessState.loading));

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: state.email, password: state.password);
      await userCredential.user!.sendEmailVerification();

      final CollectionReference usersCollection = _firestore.collection('users');
      final DocumentSnapshot doc = await usersCollection.doc('dummyDoc').get();

      if (!doc.exists) {
        await usersCollection.doc('dummyDoc').set({'exists': true});
        await usersCollection.doc('dummyDoc').delete();
      }

      await usersCollection.doc(userCredential.user!.uid).set({
        'username': state.username,
        'email': state.email,
        'userid': userCredential.user!.uid,
      });

      emit(const SignUpState(processState: ProcessState.success, dialogName: DialogName.success, message: NotifyMessage.msg6));
    } catch (error) {
      emit(const SignUpState(processState: ProcessState.failure, dialogName: DialogName.failure, message: NotifyMessage.msg7));
    }
  }
}