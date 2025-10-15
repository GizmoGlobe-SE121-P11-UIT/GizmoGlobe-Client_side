import 'dart:html' as html;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WebGuestService {
  static const String _guestUserKey = 'gizmoglobe_guest_user';
  static const String _guestUserIdKey = 'gizmoglobe_guest_user_id';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a guest user is already stored in localStorage
  Future<bool> hasGuestUser() async {
    if (!kIsWeb) return false;

    try {
      final guestUserId = html.window.localStorage[_guestUserIdKey];
      return guestUserId != null && guestUserId.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking guest user: $e');
      }
      return false;
    }
  }

  /// Get stored guest user ID from localStorage
  String? getStoredGuestUserId() {
    if (!kIsWeb) return null;

    try {
      return html.window.localStorage[_guestUserIdKey];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored guest user ID: $e');
      }
      return null;
    }
  }

  /// Store guest user ID in localStorage
  Future<void> storeGuestUserId(String userId) async {
    if (!kIsWeb) return;

    try {
      html.window.localStorage[_guestUserIdKey] = userId;
      html.window.localStorage[_guestUserKey] = 'true';
    } catch (e) {
      if (kDebugMode) {
        print('Error storing guest user ID: $e');
      }
    }
  }

  /// Clear guest user data from localStorage
  Future<void> clearGuestUser() async {
    if (!kIsWeb) return;

    try {
      html.window.localStorage.remove(_guestUserIdKey);
      html.window.localStorage.remove(_guestUserKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing guest user data: $e');
      }
    }
  }

  /// Create or retrieve guest user for web
  Future<User?> createOrGetGuestUser() async {
    if (!kIsWeb) return null;

    try {
      // Check if we already have a stored guest user ID
      final storedUserId = getStoredGuestUserId();

      if (storedUserId != null) {
        // Try to sign in with the stored user ID
        try {
          // Check if the user still exists in Firebase
          final userDoc =
              await _firestore.collection('users').doc(storedUserId).get();
          if (userDoc.exists && (userDoc.data()?['isGuest'] ?? false)) {
            // User exists and is a guest, try to sign them in
            // Note: We can't directly sign in with a UID, so we'll create a new guest
            // but preserve the same user data
            await _auth.signOut(); // Clear any existing auth
          }
        } catch (e) {
          if (kDebugMode) {
            print('Stored guest user not found, creating new one: $e');
          }
        }
      }

      // Sign in anonymously (creates new guest user)
      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        // Set up user data
        await _setupGuestUserData(userCredential.user!);

        // Store the user ID in localStorage
        await storeGuestUserId(userCredential.user!.uid);

        return userCredential.user;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating/retrieving guest user: $e');
      }
      return null;
    }
  }

  /// Set up guest user data in Firestore
  Future<void> _setupGuestUserData(User user) async {
    try {
      // Generate guest data
      final String guestId = user.uid.substring(0, 6);
      final String guestName = 'Guest_$guestId';
      final String guestEmail = 'guest.$guestId@gizmoglobe.com';
      final String guestPhone = '+0000$guestId';

      // Prepare user data
      final Map<String, dynamic> userData = {
        'username': guestName,
        'email': guestEmail,
        'userid': user.uid,
        'role': 'customer',
        'isGuest': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Prepare customer data
      final Map<String, dynamic> customerData = {
        'customerID': user.uid,
        'customerName': guestName,
        'email': guestEmail,
        'phoneNumber': guestPhone,
        'isGuest': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use batch write to ensure both operations succeed or fail together
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(user.uid), userData);
      batch.set(_firestore.collection('customers').doc(user.uid), customerData);
      await batch.commit();

      if (kDebugMode) {
        print('Guest user data set up successfully for ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up guest user data: $e');
      }
      throw Exception('Failed to set up guest user data: $e');
    }
  }

  /// Check if current user is a guest
  Future<bool> isCurrentUserGuest() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.exists && (userDoc.data()?['isGuest'] ?? false);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user is guest: $e');
      }
      return false;
    }
  }
}
