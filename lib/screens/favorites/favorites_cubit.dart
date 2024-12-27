import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  FavoritesCubit() : super({});

  void toggleFavorite(String productId) {
    final newFavorites = Set<String>.from(state);
    if (newFavorites.contains(productId)) {
      newFavorites.remove(productId);
    } else {
      newFavorites.add(productId);
    }
    emit(newFavorites);
  }

  bool isFavorite(String productId) {
    return state.contains(productId);
  }
} 