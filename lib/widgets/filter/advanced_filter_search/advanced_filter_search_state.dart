import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';

class AdvancedFilterSearchState extends Equatable {
  final List<CategoryEnum> selectedCategories;
  final List<Manufacturer> selectedManufacturers;
  final String minPrice;
  final String maxPrice;

  const AdvancedFilterSearchState({
    this.selectedCategories = const [],
    this.selectedManufacturers = const [],
    this.minPrice = '',
    this.maxPrice = '',
  });

  @override
  List<Object?> get props => [selectedCategories, selectedManufacturers, minPrice, maxPrice];

  AdvancedFilterSearchState copyWith({
    List<CategoryEnum>? selectedCategories,
    List<Manufacturer>? selectedManufacturers,
    String? minPrice,
    String? maxPrice,
  }) {
    return AdvancedFilterSearchState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedManufacturers: selectedManufacturers ?? this.selectedManufacturers,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}