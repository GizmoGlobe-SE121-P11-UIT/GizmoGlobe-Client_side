import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'advanced_filter_search_state.dart';

class AdvancedFilterSearchCubit extends Cubit<AdvancedFilterSearchState> {
  AdvancedFilterSearchCubit() : super(const AdvancedFilterSearchState());

  void initialize({
    required List<CategoryEnum> initialSelectedCategories,
    required List<Manufacturer> initialSelectedManufacturers,
    String? initialMinPrice,
    String? initialMaxPrice,
  }) {
    emit(state.copyWith(
      selectedCategories: initialSelectedCategories,
      selectedManufacturers: initialSelectedManufacturers,
      minPrice: initialMinPrice?.toString(),
      maxPrice: initialMaxPrice?.toString(),
    ));
  }

  void updateMinPrice(String value) {
    emit(state.copyWith(minPrice: value));
  }

  void updateMaxPrice(String value) {
    emit(state.copyWith(maxPrice: value));
  }

  void toggleCategory(CategoryEnum category) {
    final selectedCategories = List<CategoryEnum>.from(state.selectedCategories);

    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }

    emit(state.copyWith(selectedCategories: selectedCategories));
  }

  void toggleManufacturer(Manufacturer manufacturer) {
    final selectedManufacturers = List<Manufacturer>.from(state.selectedManufacturers);
    if (selectedManufacturers.contains(manufacturer)) {
      selectedManufacturers.remove(manufacturer);
    } else {
      selectedManufacturers.add(manufacturer);
    }

    emit(state.copyWith(selectedManufacturers: selectedManufacturers));
  }
}