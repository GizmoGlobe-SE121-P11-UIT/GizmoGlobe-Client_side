import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: state.email, 
        password: state.password
      );
      
      // Kiểm tra xác thực email
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Gửi lại email xác thực nếu cần
        await userCredential.user!.sendEmailVerification();
        
        emit(state.copyWith(
          processState: ProcessState.failure,
          message: NotifyMessage.msg10, // Cần thêm message: "Please verify your email before logging in"
        ));
        
        // Đăng xuất user vì chưa xác thực
        await _auth.signOut();
        return;
      }

      if (userCredential.user != null && userCredential.user!.emailVerified) {
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
        // Thêm thông tin vào bảng users
        final CollectionReference usersCollection = _firestore.collection('users');
        await usersCollection.doc(userCredential.user!.uid).set({
          'username': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'userid': userCredential.user!.uid,
          'role': 'customer',
        });

        // Thêm thông tin vào bảng customers
        final CollectionReference customersCollection = _firestore.collection('customers');
        await customersCollection.doc(userCredential.user!.uid).set({
          'customerID': userCredential.user!.uid,
          'customerName': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'phoneNumber': userCredential.user!.phoneNumber ?? '', // Nếu có số điện thoại từ Google
        });

        emit(state.copyWith(processState: ProcessState.success, message: NotifyMessage.msg1));
      }
    } catch (error) {
      emit(state.copyWith(processState: ProcessState.failure, message: NotifyMessage.msg2));
    }
  }
}