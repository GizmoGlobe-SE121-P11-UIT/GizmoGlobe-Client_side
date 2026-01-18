import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import '../../../data/firebase/firebase.dart';
import '../../../services/local_guest_service_platform.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGuestService _localGuestService = LocalGuestService();
  StreamSubscription<User?>? _authSubscription;
  User? _previousUser;

  FavoritesCubit() : super({}) {
    loadFavorites();
    _previousUser = _auth.currentUser;
    
    // Listen to auth state changes to reload favorites when user logs in
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null && _previousUser == null) {
        // User just logged in
        loadFavorites();
      } else if (user != null && _previousUser != null && user.uid != _previousUser!.uid) {
        // User switched accounts
        loadFavorites();
      } else if (user == null && _previousUser != null) {
        // User logged out - clear favorites
        emit({});
      }
      _previousUser = user;
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<bool> _isGuestUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Check if we have a local guest user
      return await _localGuestService.isCurrentUserGuest();
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && (userDoc.data()?['isGuest'] ?? false);
  }

  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    final isGuest = await _isGuestUser();

    if (isGuest) {
      // Load favorites from local storage for guest users
      final guestFavorites = await _localGuestService.getGuestFavorites();
      emit(guestFavorites.toSet());
      return;
    }

    if (user == null) return;

    final favorites = await _firebase.getFavorites(user.uid);
    emit(favorites.toSet());
  }

  Future<bool> canUseFavorites() async {
    // Guest users can now use favorites (stored locally)
    return true;
  }

  Future<void> toggleFavorite(String productId) async {
    final user = _auth.currentUser;
    final isGuest = await _isGuestUser();

    final currentFavorites = Set<String>.from(state);

    if (isGuest) {
      // Handle guest favorites locally
      if (currentFavorites.contains(productId)) {
        currentFavorites.remove(productId);
      } else {
        currentFavorites.add(productId);
      }

      // Store updated favorites locally
      await _localGuestService.storeGuestFavorites(currentFavorites.toList());
      emit(currentFavorites);
      return;
    }

    if (user == null) return;

    // Handle authenticated user favorites in Firebase
    if (currentFavorites.contains(productId)) {
      currentFavorites.remove(productId);
      await _firebase.removeFavorite(user.uid, productId);
    } else {
      currentFavorites.add(productId);
      await _firebase.addFavorite(user.uid, productId);
    }
    emit(currentFavorites);
  }

  void _updateDatabaseFavorites(Set<String> favoriteIds) {
    final db = Database();
    // Use fullProductList to find product objects for the IDs
    // If fullProductList is empty, we might need to rely on productList or fetch them,
    // but typically fullProductList should be populated.
    db.favoriteProducts = db.fullProductList
        .where((p) => favoriteIds.contains(p.productID))
        .toList();
  }

  @override
  void onChange(Change<Set<String>> change) {
    super.onChange(change);
    _updateDatabaseFavorites(change.nextState);
  }
}
