import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../enums/processing/process_state_enum.dart';
import 'sign_in_state.dart';
import '../../../enums/processing/notify_message_enum.dart';

class SignInCubit extends Cubit<SignInState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SignInCubit() : super(const SignInState());

  void emailChanged(String email) {
    emit(state.copyWith(email: email));
  }

  void passwordChanged(String password) {
    emit(state.copyWith(password: password));
  }

  Future<void> signInWithEmailPassword() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: state.email, password: state.password);
      if (userCredential.user != null) {
        emit(state.copyWith(processState: ProcessState.success, message: NotifyMessage.msg1));
      }
    } catch (error) {
      emit(state.copyWith(processState: ProcessState.failure, message: NotifyMessage.msg2));
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
        emit(state.copyWith(processState: ProcessState.success, message: NotifyMessage.msg1));
      }
    } catch (error) {
      emit(state.copyWith(processState: ProcessState.failure, message: NotifyMessage.msg2));
    }
  }
}