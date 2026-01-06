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
    emit(state.copyWith(
      username: username,
      processState: ProcessState.idle,
      dialogName: DialogName.empty,
      message: NotifyMessage.empty,
    ));
  }

  void updateEmail(String email) {
    emit(state.copyWith(
      email: email,
      processState: ProcessState.idle,
      dialogName: DialogName.empty,
      message: NotifyMessage.empty,
    ));
  }

  void updatePassword(String password) {
    emit(state.copyWith(
      password: password,
      processState: ProcessState.idle,
      dialogName: DialogName.empty,
      message: NotifyMessage.empty,
    ));
  }

  void updateConfirmPassword(String confirmPassword) {
    emit(state.copyWith(
      confirmPassword: confirmPassword,
      processState: ProcessState.idle,
      dialogName: DialogName.empty,
      message: NotifyMessage.empty,
    ));
  }

  void updatePhoneNumber(String phoneNumber) {
    emit(state.copyWith(
      phoneNumber: phoneNumber,
      processState: ProcessState.idle,
      dialogName: DialogName.empty,
      message: NotifyMessage.empty,
    ));
  }

  Future<void> signUp() async {
    if (state.password != state.confirmPassword) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: NotifyMessage.msg5,
        dialogName: DialogName.failure,
      ));
      return;
    }

    try {
      emit(state.copyWith(processState: ProcessState.loading));

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: state.email,
        password: state.password,
      );

      await userCredential.user!.sendEmailVerification();

      // Prepare user data matching the structure used in Google sign-in
      final Map<String, dynamic> userData = {
        'username': state.username,
        'email': state.email,
        'userid': userCredential.user!.uid,
        'role': 'customer',
        'isGuest': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Prepare customer data matching the structure used in Google sign-in
      final Map<String, dynamic> customerData = {
        'customerID': userCredential.user!.uid,
        'customerName': state.username,
        'email': state.email,
        'phoneNumber': state.phoneNumber,
        'isGuest': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use batch write to ensure both operations succeed or fail together
      // This matches the approach used in Google sign-in
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(userCredential.user!.uid),
        userData,
      );
      batch.set(
        _firestore.collection('customers').doc(userCredential.user!.uid),
        customerData,
      );
      await batch.commit();

      emit(state.copyWith(
        processState: ProcessState.success,
        dialogName: DialogName.success,
        message: NotifyMessage.msg6,
      ));
    } on FirebaseAuthException catch (e) {
      NotifyMessage errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = NotifyMessage.weakPassword;
          break;
        case 'email-already-in-use':
          errorMessage = NotifyMessage.emailAlreadyInUse;
          break;
        case 'invalid-email':
          errorMessage = NotifyMessage.invalidEmail;
          break;
        default:
          errorMessage = NotifyMessage.msg7;
      }

      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        message: errorMessage,
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
