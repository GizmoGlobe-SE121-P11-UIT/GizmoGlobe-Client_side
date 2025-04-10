import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/database/database.dart';
import '../../authentication/sign_in_screen/sign_in_view.dart';
import 'user_screen_state.dart';

class UserScreenCubit extends Cubit<UserScreenState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserScreenCubit() : super(const UserScreenState(username: '', email: ''));

  Future<bool> _isGuestUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && (userDoc.data()?['isGuest'] ?? false);
  }

  Future<void> getUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final isGuest = data['isGuest'] ?? false;

          emit(state.copyWith(
            username: data['username'] ?? '',
            email: user.email ?? '',
            avatarUrl: data['avatarUrl'],
            isGuest: isGuest,
          ));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user: $e');
      }
    }
  }

  Future<void> logOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen.newInstance()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
        // print('Lỗi khi đăng xuất: $e');
      }
    }
  }

  void updateUsername(String newName) async {
    if (newName.isNotEmpty) {
      final userId = await Database().getCurrentUserID();
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .update({'customerName': newName});

        emit(state.copyWith(username: newName));
      }
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        final email = user.email;

        // Kiểm tra và cập nhật trong collection 'users'
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          batch.update(_firestore.collection('users').doc(user.uid), {
            'avatarUrl': avatarUrl,
          });
        }

        // Kiểm tra và cập nhật trong collection 'customers'
        final customersQuery = await _firestore
            .collection('customers')
            .where('email', isEqualTo: email)
            .get();
        if (customersQuery.docs.isNotEmpty) {
          batch.update(_firestore.collection('customers').doc(user.uid), {
            'avatarUrl': avatarUrl,
          });
        }

        // Kiểm tra và cập nhật trong collection 'employees'
        final employeesQuery = await _firestore
            .collection('employees')
            .where('email', isEqualTo: email)
            .get();
        if (employeesQuery.docs.isNotEmpty) {
          batch.update(_firestore.collection('employees').doc(user.uid), {
            'avatarUrl': avatarUrl,
          });
        }

        await batch.commit();
        emit(state.copyWith(avatarUrl: avatarUrl));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating avatar: $e');
      }
      rethrow;
    }
  }
}
