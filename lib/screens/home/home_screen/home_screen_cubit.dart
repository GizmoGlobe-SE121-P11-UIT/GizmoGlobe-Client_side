import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/services/recommendation/recommendation_service.dart';
import '../../../widgets/product/favorites/favorites_cubit.dart';
import 'home_screen_state.dart';

class HomeScreenCubit extends Cubit<HomeScreenState> {
  final FavoritesCubit favoritesCubit;
  late final StreamSubscription _favoritesSubscription;
  late final StreamSubscription _authSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _previousUser;

  HomeScreenCubit({required this.favoritesCubit})
      : super(const HomeScreenState()) {
    // Lắng nghe thay đổi từ FavoritesCubit
    emit(state.copyWith(cartItems: Database().cartItems));
    _favoritesSubscription = favoritesCubit.stream.listen((favoriteIds) async {
      await _updateFavoriteProducts();
    });

    _updateRecommendedProducts();

    _previousUser = _auth.currentUser;

    // Listen to auth state changes to refresh data when user signs in
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      // If user changed from null/guest to authenticated, refresh data
      if (user != null && _previousUser == null) {
        await _refreshDataAfterSignIn();
      }
      // If user changed from one user to another, refresh data
      else if (user != null &&
          _previousUser != null &&
          user.uid != _previousUser!.uid) {
        await _refreshDataAfterSignIn();
      }
      // If user signed out, clear user-specific data
      else if (user == null && _previousUser != null) {
        if (!isClosed) {
          emit(state.copyWith(
            favoriteProducts: [],
            recommendedProducts: [],
            cartItems: [],
          ));
        }
      }
      _previousUser = user;
    });
  }

  @override
  Future<void> close() {
    _favoritesSubscription.cancel();
    _authSubscription.cancel();
    return super.close();
  }

  Future<void> _refreshDataAfterSignIn() async {
    if (isClosed) return;

    // Reload favorites in FavoritesCubit so heart icons update immediately
    await favoritesCubit.loadFavorites();

    // Reload cart items from Firebase
    await loadCartItems();

    // Update favorite products
    await _updateFavoriteProducts();

    // Update recommended products based on new cart items
    _updateRecommendedProducts();
  }

  Future<void> initialize() async {
    if (isClosed) return; // Prevent emitting after cubit is closed

    // Load cart items first to enable recommendations
    await loadCartItems();

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

        // Filter out products with stock == 0
        final inStockFavorites =
            favoriteProducts.where((product) => product.stock > 0).toList();

        if (!isClosed) {
          // Check again before emitting
          emit(state.copyWith(favoriteProducts: inStockFavorites));
        }
      }
    } catch (e) {
      // Error updating favorite products
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
        final updatedCartItems = Database().cartItems;
        emit(state.copyWith(cartItems: updatedCartItems));
        // Update recommended products after cart items are loaded
        _updateRecommendedProducts();
      }
    } catch (e) {
      if (isClosed) return;
      // emit(state.copyWith(
      //     processState: ProcessState.failure, error: e.toString()));
    }
  }
}
