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

  Future<void> updateRecommendedProducts() async {
    List<Product> recommendedProducts = [];
    List<Product> cartProducts = [];
    await loadCartItems();
    final cartItems = state.cartItems ?? [];
    for (var item in cartItems) {
      final product = item['product'] as Map<String, dynamic>;
      cartProducts.add(ProductFactory.createProduct(product));
    }

    Product mostExpensiveProduct = cartProducts.firstWhere(
        (product) => product.discountedPrice == cartProducts
            .map((p) => p.discountedPrice)
            .reduce((a, b) => a > b ? a : b),
        orElse: () => ProductFactory.createProduct({}));

    RecommendationService recommendationService = RecommendationService();
    recommendedProducts = recommendationService.getRecommendedProducts(mostExpensiveProduct);
    emit(state.copyWith(recommendedProducts: recommendedProducts));
  }

  void changeSearchText(String? searchText) {
    if (!isClosed) {
      emit(state.copyWith(searchText: searchText));
    }
  }

  Future<void> loadCartItems() async {
    try {
      if (isClosed) return;
      
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in');
        }
        return ;
        // emit(state.copyWith(
        //     processState: ProcessState.failure, error: 'User not logged in'));
        // return;
      }

      final cartItems = await _firebase.getCartItems(user!.uid);

      if (isClosed) return;

      // Tính subtotal cho mỗi item
      final updatedItems = cartItems.map((item) {
        final product = item['product'] as Map<String, dynamic>;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
        final price = (product['sellingPrice'] as num?)?.toDouble() ?? 0;
        final discount = (product['discount'] as num?)?.toDouble() ?? 0;

        // Tính giá sau giảm giá
        final discountedPrice = price * (1 - discount / 100);
        final subtotal = discountedPrice * quantity;

        return {
          ...item,
          'subtotal': subtotal,
        };
      }).toList();

      if (isClosed) return;
      emit(state.copyWith(
        cartItems: updatedItems,
      ));
    } catch (e) {
      if (isClosed) return;
      // emit(state.copyWith(
      //     processState: ProcessState.failure, error: e.toString()));
    }
  }
}
