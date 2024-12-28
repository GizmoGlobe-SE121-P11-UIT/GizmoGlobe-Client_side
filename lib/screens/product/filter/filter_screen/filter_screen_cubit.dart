import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import '../../../../objects/product_related/filter_argument.dart';
import 'filter_screen_state.dart';

class FilterScreenCubit extends Cubit<FilterScreenState> {
  FilterScreenCubit() : super(const FilterScreenState());

  void initialize({
    required FilterArgument initialFilterValue,
    required int selectedTabIndex,
    required List<Manufacturer> manufacturerList,
  }) {
    emit(state.copyWith(
      filterArgument: initialFilterValue,
      selectedTabIndex: selectedTabIndex,
      manufacturerList: manufacturerList,
    ));
  }

  void updateFilterArgument(FilterArgument filterArgument) {
    emit(state.copyWith(filterArgument: filterArgument));
  }

  void toggleManufacturer(Manufacturer manufacturer) {
    final selectedManufacturers = List<Manufacturer>.from(state.filterArgument.manufacturerList);
    if (selectedManufacturers.contains(manufacturer)) {
      selectedManufacturers.remove(manufacturer);
    } else {
      selectedManufacturers.add(manufacturer);
    }

    updateFilterArgument(state.filterArgument.copyWith(manufacturerList: selectedManufacturers));
  }
}