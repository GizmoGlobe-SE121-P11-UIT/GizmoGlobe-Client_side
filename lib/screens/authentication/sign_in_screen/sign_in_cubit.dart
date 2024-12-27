import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import 'sign_in_state.dart';
import '../../../enums/processing/notify_message_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInCubit extends Cubit<SignInState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SignInCubit() : super(const SignInState());

  void emailChanged(String email) {
    emit(state.copyWith(
      email: email,
      processState: ProcessState.idle, // Reset state
      message: NotifyMessage.empty,   // Reset message
    ));
  }

  void passwordChanged(String password) {
    emit(state.copyWith(
      password: password,
      processState: ProcessState.idle, // Reset state
      message: NotifyMessage.empty,    // Reset message
    ));
  }

  Future<void> signInWithEmailPassword() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: state.email, password: state.password);
      if (userCredential.user != null) {
        if (!userCredential.user!.emailVerified) {
          emit(state.copyWith(
              processState: ProcessState.failure,
              message: NotifyMessage.msg1,
              dialogName: DialogName.failure
          ));
          await _auth.signOut();
        } else {
          emit(state.copyWith(
              processState: ProcessState.success,
              message: NotifyMessage.msg1,
              dialogName: DialogName.success
          ));
        }
      }
    } catch (error) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: NotifyMessage.msg2
      ));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(state.copyWith(processState: ProcessState.idle));
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        // Google đã xác thực email nên không cần kiểm tra emailVerified

        // Kiểm tra xem user đã tồn tại chưa
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Nếu user chưa tồn tại, tạo mới trong cả 2 bảng
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'username': userCredential.user!.displayName,
            'email': userCredential.user!.email,
            'userid': userCredential.user!.uid,
            'role': 'customer',
          });

          await _firestore.collection('customers').doc(userCredential.user!.uid).set({
            'customerID': userCredential.user!.uid,
            'customerName': userCredential.user!.displayName,
            'email': userCredential.user!.email,
            'phoneNumber': userCredential.user!.phoneNumber ?? '',
          });
        }

        emit(state.copyWith(
          processState: ProcessState.success,
          message: NotifyMessage.msg1
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: NotifyMessage.msg2
      ));
    }
  }
}