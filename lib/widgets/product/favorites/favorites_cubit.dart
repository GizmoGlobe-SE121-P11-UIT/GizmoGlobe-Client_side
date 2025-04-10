import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firebase/firebase.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FavoritesCubit() : super({}) {
    loadFavorites();
  }

  Future<bool> _isGuestUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.exists && (userDoc.data()?['isGuest'] ?? false);
  }

  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isGuest = await _isGuestUser();
    if (isGuest) {
      emit({});
      return;
    }

    final favorites = await _firebase.getFavorites(user.uid);
    emit(favorites.toSet());
  }

  Future<bool> canUseFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final isGuest = await _isGuestUser();
    return !isGuest;
  }

  Future<void> toggleFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isGuest = await _isGuestUser();
    if (isGuest) {
      return;
    }

    final currentFavorites = Set<String>.from(state);
    if (currentFavorites.contains(productId)) {
      currentFavorites.remove(productId);
      await _firebase.removeFavorite(user.uid, productId);
    } else {
      currentFavorites.add(productId);
      await _firebase.addFavorite(user.uid, productId);
    }
    emit(currentFavorites);
  }
}
