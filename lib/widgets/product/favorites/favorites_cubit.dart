import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firebase/firebase.dart';
import '../../../services/local_guest_service.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGuestService _localGuestService = LocalGuestService();

  FavoritesCubit() : super({}) {
    loadFavorites();
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
}
