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

    emit(state.copyWith(
      productList: Database().productList,
      manufacturerList: Database().manufacturerList,
      selectedManufacturerList: Database().manufacturerList,
      selectedCategoryList: CategoryEnum.values.toList(),
    ));
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

  void updateFilter({
    List<CategoryEnum>? selectedCategoryList,
    List<Manufacturer>? selectedManufacturerList,
    String? minPrice,
    String? maxPrice,
  }) {
    emit(state.copyWith(
      selectedCategoryList: selectedCategoryList,
      selectedManufacturerList: selectedManufacturerList,
      minPrice: minPrice,
      maxPrice: maxPrice,
    ));
    applyFilters();
  }

  void applyFilters() {
    final double min = double.tryParse(state.minPrice) ?? 0;
    final double max = double.tryParse(state.maxPrice) ?? double.infinity;

    final filteredProducts = Database().productList.where((product) {
      final matchesCategory = state.selectedCategoryList.contains(product.category);
      final matchesManufacturer = state.selectedManufacturerList.contains(product.manufacturer);
      final matchesPrice = (product.price >= min) && (product.price <= max);
      return matchesCategory && matchesManufacturer && matchesPrice;
    }).toList();

    emit(state.copyWith(productList: filteredProducts));
  }
}