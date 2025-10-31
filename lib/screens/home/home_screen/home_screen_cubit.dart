import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/product_factory.dart';
import 'package:gizmoglobe_client/services/recommendation_service.dart';
import '../../../data/firebase/firebase.dart';
import '../../../widgets/product/favorites/favorites_cubit.dart';
import 'home_screen_state.dart';

class HomeScreenCubit extends Cubit<HomeScreenState> {
  final FavoritesCubit favoritesCubit;
  late final StreamSubscription _favoritesSubscription;
  final Firebase _firebase = Firebase();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late dynamic user;

  HomeScreenCubit({required this.favoritesCubit})
      : super(const HomeScreenState()) {
    // Lắng nghe thay đổi từ FavoritesCubit
    emit(state.copyWith(cartItems: Database().cartItems));
    _favoritesSubscription = favoritesCubit.stream.listen((favoriteIds) async {
      await _updateFavoriteProducts();
    });

    _updateRecommendedProducts();

    user = _auth.currentUser;

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

      final user = _auth.currentUser;
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

  void _updateRecommendedProducts() {
    final cartItems = state.cartItems;
    final cartProducts = cartItems.map((c) => c.product).toList();

    if (cartProducts.isEmpty) {
      if (!isClosed) emit(state.copyWith(recommendedProducts: []));
      return;
    }

    final recommendedProducts = RecommendationService()
        .getRecommendationsForBuild(cartProducts, topN: 20);

    if (!isClosed) {
      emit(state.copyWith(recommendedProducts: recommendedProducts));
    }
  }

  void changeSearchText(String? searchText) {
    if (!isClosed) {
      emit(state.copyWith(searchText: searchText));
    }
  }

  Future<void> loadCartItems() async {
    try {
      if (isClosed) return;
      await Database().getCartItems();
      if (!isClosed) {
        emit(state.copyWith(cartItems: Database().cartItems));
      }
    } catch (e) {
      if (isClosed) return;
      // emit(state.copyWith(
      //     processState: ProcessState.failure, error: e.toString()));
    }
  }
}
