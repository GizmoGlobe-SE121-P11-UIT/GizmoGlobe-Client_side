import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import '../../../data/firebase/firebase.dart';
import '../../../objects/product_related/product.dart';
import 'home_screen_state.dart';

class HomeScreenCubit extends Cubit<HomeScreenState> {
  HomeScreenCubit() : super(const HomeScreenState());

  void initialize() {
    emit(state.copyWith(
      favoriteProducts: Database().favoriteProducts,
      bestSellerProducts: Database().bestSellerProducts,
    ));
  }

  // Future<void> fetchProducts() async {
  //   try {
  //     final bestSellerProducts = await Database().fetchBestSellerProducts();
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       final favoriteProducts = await Database().fetchFavoriteProducts(user.uid);
  //       fetchBestSellerProducts(bestSellerProducts);
  //       fetchFavoriteProducts(favoriteProducts);
  //     }
  //   } catch (e) {
  //     print('Error fetching products: $e');
  //   }
  // }

  void changeSearchText(String? searchText) {
    emit(state.copyWith(searchText: searchText));
  }

  void fetchBestSellerProducts(List<Product> products) {
    emit(state.copyWith(bestSellerProducts: products));
  }

  void fetchFavoriteProducts(List<Product> products) {
    emit(state.copyWith(favoriteProducts: products));
  }
}