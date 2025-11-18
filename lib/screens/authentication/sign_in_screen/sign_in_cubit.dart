import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../data/database/database.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import 'sign_in_state.dart';
import '../../../enums/processing/notify_message_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/local_guest_service_platform.dart';

class SignInCubit extends Cubit<SignInState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGuestService _localGuestService = LocalGuestService();

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

      // Clear any existing guest data when signing in with account
      await _localGuestService.clearGuestUser();

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
        try {
          await Database().refreshUserScopedData();
        } catch (e) {
          if (kDebugMode) {
            print('Error refreshing user data after email sign-in: $e');
          }
        }
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
      if (isClosed) return;
      emit(state.copyWith(processState: ProcessState.loading));

      UserCredential userCredential;

      if (kIsWeb) {
        // For web: try popup first for localhost; fallback to redirect if blocked
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        try {
          userCredential = await _auth.signInWithPopup(googleProvider);
        } on FirebaseAuthException catch (e) {
          // If popup is blocked or closed, fallback to redirect
          final popupBlocked = e.code == 'popup-blocked' ||
              e.code == 'auth/popup-blocked' ||
              e.code == 'popup-closed-by-user' ||
              e.code == 'auth/popup-closed-by-user' ||
              e.code == 'cancelled-popup-request';

          if (popupBlocked) {
            // Clear guest data before redirect (user will be redirected away)
            await _localGuestService.clearGuestUser();

            if (kDebugMode) {
              print(
                  'Popup unavailable (${e.code}). Falling back to redirect...');
              print('Current URL before redirect: ${Uri.base}');
            }

            await _auth.signInWithRedirect(googleProvider);
            return; // Will navigate away
          }
          // Handle specific Firebase Auth errors
          if (kDebugMode) {
            print(
                'Google Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
            print('Full error details: ${e.toString()}');
          }

          // Check for various popup-related error codes
          if (e.code == 'popup-closed-by-user' ||
              e.code == 'auth/popup-closed-by-user' ||
              e.code == 'cancelled-popup-request') {
            // Popup was closed - treat as user cancellation
            if (!isClosed) {
              emit(state.copyWith(processState: ProcessState.idle));
            }
            return;
          } else if (e.code == 'popup-blocked' ||
              e.code == 'auth/popup-blocked') {
            // Popup was blocked by browser - show error
            if (kDebugMode) {
              print(
                  'Popup blocked by browser. Please allow popups for this site.');
            }
            if (!isClosed) {
              emit(state.copyWith(
                processState: ProcessState.failure,
                dialogName: DialogName.failure,
                message: NotifyMessage.msg2,
              ));
            }
            return;
          }

          // Other Firebase Auth errors
          if (!isClosed) {
            emit(state.copyWith(
              processState: ProcessState.failure,
              dialogName: DialogName.failure,
              message: NotifyMessage.msg2,
            ));
          }
          return;
        } catch (error) {
          // Handle other types of errors
          if (kDebugMode) {
            print('Google Sign-In error: $error');
            print('Error type: ${error.runtimeType}');
          }

          if (!isClosed) {
            emit(state.copyWith(
              processState: ProcessState.failure,
              dialogName: DialogName.failure,
              message: NotifyMessage.msg2,
            ));
          }
          return;
        }
      } else {
        // For mobile, use Google Sign-In plugin
        // Read Web client ID from environment to avoid exposing it in code
        final String? serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: (serverClientId != null && serverClientId.isNotEmpty)
              ? serverClientId
              : null,
          scopes: const ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (!isClosed) {
            emit(state.copyWith(processState: ProcessState.idle));
          }
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        // Clear guest data after successful authentication
        await _localGuestService.clearGuestUser();

        await _setupUserData(userCredential.user!);
        try {
          await Database().refreshUserScopedData();
        } catch (e) {
          if (kDebugMode) {
            print('Error refreshing user data after Google sign-in: $e');
          }
        }
        if (!isClosed) {
          emit(state.copyWith(
            processState: ProcessState.success,
            dialogName: DialogName.success,
            message: NotifyMessage.msg1,
          ));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
            'FirebaseAuthException during Google Sign-In: code=${e.code}, message=${e.message}');
      }
      if (!isClosed) {
        emit(state.copyWith(
          processState: ProcessState.failure,
          dialogName: DialogName.failure,
          message: NotifyMessage.msg2,
        ));
      }
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In error: $error');
      }
      if (!isClosed) {
        emit(state.copyWith(
          processState: ProcessState.failure,
          dialogName: DialogName.failure,
          message: NotifyMessage.msg2,
        ));
      }
    }
  }

  Future<void> signInAsGuest() async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));

      // Sign out any existing Firebase user first
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Create or get guest user from local storage
      final guestUserData = await _localGuestService.createOrGetGuestUser();

      if (guestUserData != null) {
        if (kDebugMode) {
          print(
              'Guest user signed in successfully: ${guestUserData['userid']}');
        }

        emit(state.copyWith(
          processState: ProcessState.success,
          dialogName: DialogName.success,
          message: NotifyMessage.msg1,
          isGuestLogin: true,
        ));
      } else {
        throw Exception('Failed to create guest user data');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error signing in as guest: $error');
      }
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        message: NotifyMessage.msg2,
      ));
    }
  }

  Future<void> _setupUserData(User user, {bool isGuest = false}) async {
    try {
      // Check if user document already exists
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final customerDocRef = _firestore.collection('customers').doc(user.uid);

      final userDoc = await userDocRef.get();
      final userExists = userDoc.exists;

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
      };

      // Prepare customer data
      final Map<String, dynamic> customerData = {
        'customerID': user.uid,
        'customerName': isGuest ? guestName : (user.displayName ?? ''),
        'email': isGuest ? guestEmail : (user.email ?? ''),
        'phoneNumber': isGuest ? guestPhone : (user.phoneNumber ?? ''),
        'isGuest': isGuest,
      };

      // Only set createdAt for new users
      if (!userExists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        customerData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Use batch write to ensure both operations succeed or fail together
      // Use merge to preserve existing data if user already exists
      final batch = _firestore.batch();
      batch.set(userDocRef, userData, SetOptions(merge: true));
      batch.set(customerDocRef, customerData, SetOptions(merge: true));
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
