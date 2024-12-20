import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/sort_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

class ProductListSearchState extends Equatable {
  final String? searchText;
  final List<Product> productList;
  final List<Manufacturer> manufacturerList;
  final List<Manufacturer> selectedManufacturerList;
  final List<CategoryEnum> selectedCategoryList;
  final String minPrice;
  final String maxPrice;
  final SortEnum selectedOption;


  const ProductListSearchState({
    this.searchText,
    this.productList = const [],
    this.manufacturerList = const [],
    this.selectedManufacturerList = const [],
    this.selectedCategoryList = const [],
    this.minPrice = '',
    this.maxPrice = '',
    this.selectedOption = SortEnum.bestSeller,
  });

  @override
  List<Object?> get props => [
    searchText,
    productList,
    manufacturerList,
    selectedManufacturerList,
    selectedCategoryList,
    minPrice,
    maxPrice,
    selectedOption,
  ];

  ProductListSearchState copyWith({
    String? searchText,
    List<Product>? productList,
    List<Manufacturer>? manufacturerList,
    List<Manufacturer>? selectedManufacturerList,
    List<CategoryEnum>? selectedCategoryList,
    String? minPrice,
    String? maxPrice,
    SortEnum? selectedOption,
  }) {
    return ProductListSearchState(
      searchText: searchText ?? this.searchText,
      productList: productList ?? this.productList,
      manufacturerList: manufacturerList ?? this.manufacturerList,
      selectedManufacturerList: selectedManufacturerList ?? this.selectedManufacturerList,
      selectedCategoryList: selectedCategoryList ?? this.selectedCategoryList,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedOption: selectedOption ?? this.selectedOption,
    );
  }
}