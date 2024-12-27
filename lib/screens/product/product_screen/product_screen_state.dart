import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../../enums/processing/sort_enum.dart';

class ProductScreenState extends Equatable {
  final String? searchText;
  final int selectedTabIndex;
  final SortEnum selectedSortOption;

  const ProductScreenState({
    this.searchText,
    this.selectedTabIndex = 0,
    this.selectedSortOption = SortEnum.releaseLatest,
  });

  @override
  List<Object?> get props => [
    searchText,
    selectedTabIndex,
    selectedSortOption,
  ];

  ProductScreenState copyWith({
    String? searchText,
    int? selectedTabIndex,
    SortEnum? selectedSortOption,
  }) {
    return ProductScreenState(
      searchText: searchText ?? this.searchText,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedSortOption: selectedSortOption ?? this.selectedSortOption,
    );
  }
}