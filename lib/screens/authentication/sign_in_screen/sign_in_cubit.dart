import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/processing/dialog_name_enum.dart';
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
      message: NotifyMessage.empty, // Reset message
    ));
  }

  void passwordChanged(String password) {
    emit(state.copyWith(
      password: password,
      processState: ProcessState.idle, // Reset state
      message: NotifyMessage.empty, // Reset message
    ));
  }

  Future<void> signInWithEmailPassword() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
              email: state.email, password: state.password);

      // Kiểm tra xác thực email
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Gửi lại email xác thực nếu cần
        await userCredential.user!.sendEmailVerification();

        emit(state.copyWith(
          processState: ProcessState.failure,
          dialogName: DialogName.failure,
          message: NotifyMessage.msg10,
        ));

        // Đăng xuất user vì chưa xác thực
        await _auth.signOut();
        return;
      }

      if (userCredential.user != null && userCredential.user!.emailVerified) {
        emit(state.copyWith(
          processState: ProcessState.success,
          dialogName: DialogName.success,
          message: NotifyMessage.msg1,
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        message: NotifyMessage.msg2,
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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _setupUserData(userCredential.user!);
        emit(state.copyWith(
          processState: ProcessState.success,
          dialogName: DialogName.success,
          message: NotifyMessage.msg1,
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        message: NotifyMessage.msg2,
      ));
    }
  }

  Future<void> signInAsGuest() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      // Sign out any existing user first
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        // Ensure user data is set up before proceeding
        await _setupUserData(userCredential.user!, isGuest: true);

        // Verify that the data was properly set up
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        final customerDoc = await _firestore
            .collection('customers')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists || !customerDoc.exists) {
          if(kDebugMode) {
            print('Failed to set up guest account data');
          }
          throw Exception('Failed to set up guest account data');
        }

        emit(state.copyWith(
          processState: ProcessState.success,
          dialogName: DialogName.success,
          message: NotifyMessage.msg1,
          isGuestLogin: true,
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        message: NotifyMessage.msg2,
      ));
      // Clean up if setup failed
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
    }
  }

  Future<void> _setupUserData(User user, {bool isGuest = false}) async {
    try {
      // Generate decoy data for guest account
      final String guestId = user.uid.substring(0, 6);
      final String guestName = 'Guest_$guestId';
      final String guestEmail = 'guest.$guestId@gizmoglobe.com';
      final String guestPhone = '+0000$guestId';

      // Prepare user data
      final Map<String, dynamic> userData = {
        'username': isGuest ? guestName : (user.displayName ?? ''),
        'email': isGuest ? guestEmail : (user.email ?? ''),
        'userid': user.uid,
        'role': 'customer',
        'isGuest': isGuest,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Prepare customer data
      final Map<String, dynamic> customerData = {
        'customerID': user.uid,
        'customerName': isGuest ? guestName : (user.displayName ?? ''),
        'email': isGuest ? guestEmail : (user.email ?? ''),
        'phoneNumber': isGuest ? guestPhone : (user.phoneNumber ?? ''),
        'isGuest': isGuest,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use batch write to ensure both operations succeed or fail together
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(user.uid), userData);
      batch.set(_firestore.collection('customers').doc(user.uid), customerData);
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up user data: $e');
      }
      throw Exception('Failed to set up user data: $e');
    }
  }

  void toIdle() {
    emit(state.copyWith(
      processState: ProcessState.idle,
      message: NotifyMessage.empty,
    ));
  }
}