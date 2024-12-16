import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'product_list_search_state.dart';

class ProductListSearchCubit extends Cubit<ProductListSearchState> {
  ProductListSearchCubit() : super(const ProductListSearchState());

  void initialize(String? initialSearchText) {
    emit(state.copyWith(searchText: initialSearchText));
    searchProducts(initialSearchText);
  }

  void changeSearchText(String? searchText) {
    emit(state.copyWith(searchText: searchText));
    searchProducts(searchText);
  }

  void searchProducts(String? searchText) {
    final filteredProducts = Database().productList.where((product) {
      return searchText == null || product.productName.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    emit(state.copyWith(productList: filteredProducts, searchText: searchText));
  }

  void applyFilters(CategoryEnum? category, Manufacturer? manufacturer, double? minPrice, double? maxPrice) {
    final filteredProducts = Database().productList.where((product) {
      final matchesCategory = category == null || product.category == category;
      final matchesManufacturer = manufacturer == null || product.manufacturer == manufacturer;
      final matchesPrice = (minPrice == null || product.price >= minPrice) && (maxPrice == null || product.price <= maxPrice);
      return matchesCategory && matchesManufacturer && matchesPrice;
    }).toList();
    emit(state.copyWith(productList: filteredProducts));
  }
}