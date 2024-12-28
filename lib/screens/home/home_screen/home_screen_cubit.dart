import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import '../../../data/firebase/firebase.dart';
import '../../../objects/product_related/product.dart';
import '../../../widgets/product/favorites/favorites_cubit.dart';
import 'home_screen_state.dart';

class HomeScreenCubit extends Cubit<HomeScreenState> {
  final FavoritesCubit favoritesCubit;

  HomeScreenCubit({required this.favoritesCubit}) : super(const HomeScreenState()) {
    // Lắng nghe thay đổi từ FavoritesCubit
    favoritesCubit.stream.listen((favoriteIds) async {
      await _updateFavoriteProducts();
    });
  }

  Future<void> initialize() async {
    emit(state.copyWith(
      bestSellerProducts: Database().bestSellerProducts,
    ));
    await _updateFavoriteProducts();
  }

  Future<void> _updateFavoriteProducts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteProducts = await Database().fetchFavoriteProducts(user.uid);
        emit(state.copyWith(favoriteProducts: favoriteProducts));
      }
    } catch (e) {
      print('Error updating favorite products: $e');
    }
  }

  void changeSearchText(String? searchText) {
    emit(state.copyWith(searchText: searchText));
  }
}