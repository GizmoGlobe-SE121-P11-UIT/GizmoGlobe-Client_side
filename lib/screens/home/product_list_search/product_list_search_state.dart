import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

class ProductListSearchState extends Equatable {
  final String? searchText;
  final List<Product> productList;

  const ProductListSearchState({
    this.searchText,
    this.productList = const [],
  });

  ProductListSearchState copyWith({
    String? searchText,
    List<Product>? productList,
  }) {
    return ProductListSearchState(
      searchText: searchText ?? this.searchText,
      productList: productList ?? this.productList,
    );
  }

  @override
  List<Object?> get props => [searchText, productList];
}