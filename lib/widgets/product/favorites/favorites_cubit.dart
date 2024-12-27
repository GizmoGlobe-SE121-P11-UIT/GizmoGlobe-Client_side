// lib/widgets/product/favorites/favorites_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/firebase/firebase.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FavoritesCubit() : super({}) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final favorites = await _firebase.getFavorites(user.uid);
    emit(favorites.toSet());
  }

  Future<void> toggleFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

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