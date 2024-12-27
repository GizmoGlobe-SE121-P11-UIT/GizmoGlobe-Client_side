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

  void updatePhoneNumber(String phoneNumber) {
    emit(state.copyWith(phoneNumber: phoneNumber));
  }

  Future<void> signUp() async {
    if (state.password != state.confirmPassword) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: NotifyMessage.msg5,
        dialogName: DialogName.failure
      ));
      return;
    }

    try {
      emit(state.copyWith(processState: ProcessState.loading));

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: state.email,
        password: state.password
      );
      
      await userCredential.user!.sendEmailVerification();

      // Lưu thông tin vào users collection
      final CollectionReference usersCollection = _firestore.collection('users');
      await usersCollection.doc(userCredential.user!.uid).set({
        'username': state.username,
        'email': state.email,
        'userid': userCredential.user!.uid,
        'role': 'customer',
      });

      // Lưu thông tin vào customers collection
      final CollectionReference customersCollection = _firestore.collection('customers');
      await customersCollection.doc(userCredential.user!.uid).set({
        'customerID': userCredential.user!.uid,
        'customerName': state.username,
        'email': state.email,
        'phoneNumber': state.phoneNumber,
      });

      emit(state.copyWith(
        processState: ProcessState.success,
        dialogName: DialogName.success,
        message: NotifyMessage.msg6
      ));
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'An error occurred during registration.';
      }
      
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        message: NotifyMessage.msg7,
      ));
    } catch (error) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        message: NotifyMessage.msg7,
      ));
    }
  }
}