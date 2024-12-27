import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/cpu_family.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../../../enums/processing/sort_enum.dart';
import '../../../../objects/product_related/filter_argument.dart';

class TabState extends Equatable{
  final String searchText;
  final List<Product> productList;
  final ProcessState processState;
  final SortEnum selectedSortOption;
  final FilterArgument filterArgument;
  final Product? selectedProduct;
  final List<Manufacturer> manufacturerList;
  final List<Product> filteredProductList;

  const TabState({
    this.searchText = '',
    this.productList = const [],
    this.manufacturerList = const [],
    this.selectedSortOption = SortEnum.releaseLatest,
    this.selectedProduct,
    this.filterArgument = const FilterArgument(),
    this.processState = ProcessState.idle,
    this.filteredProductList = const [],
  });

  @override
  List<Object?> get props => [
    searchText,
    productList,
    manufacturerList,
    selectedSortOption,
    selectedProduct,
    filterArgument,
    processState,
    filteredProductList,
  ];

  TabState copyWith({
    String? searchText,
    List<Product>? productList,
    SortEnum? selectedSortOption,
    Product? selectedProduct,
    FilterArgument? filterArgument,
    ProcessState? processState,
    List<Manufacturer>? manufacturerList,
    List<Product>? filteredProductList,
  }) {
    return TabState(
      searchText: searchText ?? this.searchText,
      productList: productList ?? this.productList,
      selectedSortOption: selectedSortOption ?? this.selectedSortOption,
      selectedProduct: selectedProduct,
      filterArgument: filterArgument ?? this.filterArgument,
      processState: processState ?? this.processState,
      manufacturerList: manufacturerList ?? this.manufacturerList,
      filteredProductList: filteredProductList ?? this.filteredProductList,
    );
  }
}