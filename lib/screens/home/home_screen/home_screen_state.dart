import 'package:equatable/equatable.dart';

import '../../../objects/product_related/product.dart';

class HomeScreenState extends Equatable {
  final String username;
  final String searchText;
  final List<Product> bestSellerProducts;
  final List<Product> favoriteProducts;

  const HomeScreenState({
    this.username = '',
    this.searchText = '',
    this.bestSellerProducts = const [],
    this.favoriteProducts = const [],
  });

  @override
  List<Object?> get props => [username, searchText, bestSellerProducts, favoriteProducts];

  HomeScreenState copyWith({
    String? username,
    String? searchText,
    List<Product>? bestSellerProducts,
    List<Product>? favoriteProducts,
  }) {
    return HomeScreenState(
      username: username ?? this.username,
      searchText: searchText ?? this.searchText,
      bestSellerProducts: bestSellerProducts ?? this.bestSellerProducts,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
    );
  }
}