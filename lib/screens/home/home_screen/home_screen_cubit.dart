import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import '../../../widgets/product/favorites/favorites_cubit.dart';
import 'home_screen_state.dart';

class HomeScreenCubit extends Cubit<HomeScreenState> {
  final FavoritesCubit favoritesCubit;
  late final StreamSubscription _favoritesSubscription;

  HomeScreenCubit({required this.favoritesCubit})
      : super(const HomeScreenState()) {
    // Lắng nghe thay đổi từ FavoritesCubit
    _favoritesSubscription = favoritesCubit.stream.listen((favoriteIds) async {
      await _updateFavoriteProducts();
    });
  }

  @override
  Future<void> close() {
    _favoritesSubscription.cancel();
    return super.close();
  }

  Future<void> initialize() async {
    if (isClosed) return; // Prevent emitting after cubit is closed

    await _updateFavoriteProducts();

    if (!isClosed) {
      // Check again before emitting
      emit(state.copyWith(
        bestSellerProducts: Database().bestSellerProducts,
      ));
    }
  }

  Future<void> _updateFavoriteProducts() async {
    try {
      if (isClosed) return; // Prevent emitting after cubit is closed

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteProducts =
            await Database().fetchFavoriteProducts(user.uid);
        if (!isClosed) {
          // Check again before emitting
          emit(state.copyWith(favoriteProducts: favoriteProducts));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating favorite products: $e');
      }
      // print('Lỗi khi cập nhật danh sách sản phẩm yêu thích: $e');
    }
  }

  void changeSearchText(String? searchText) {
    if (!isClosed) {
      emit(state.copyWith(searchText: searchText));
    }
  }
}
