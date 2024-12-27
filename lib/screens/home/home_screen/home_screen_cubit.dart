import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/firebase/firebase.dart';
import '../../../objects/product_related/product.dart';
import 'home_screen_state.dart';

class HomeScreenCubit extends Cubit<HomeScreenState> {
  HomeScreenCubit() : super(const HomeScreenState());

  Future<void> initialize() async {
    await fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final bestSellerProducts = await Firebase().fetchBestSellerProducts();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteProducts = await Firebase().fetchFavoriteProducts(user.uid);
        fetchBestSellerProducts(bestSellerProducts);
        fetchFavoriteProducts(favoriteProducts);
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

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