import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';

import '../../../../data/firebase/firebase.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../enums/processing/sort_enum.dart';
import '../../../../objects/product_related/cpu.dart';
import '../../../../objects/product_related/drive.dart';
import '../../../../objects/product_related/filter_argument.dart';
import '../../../../objects/product_related/gpu.dart';
import '../../../../objects/product_related/mainboard.dart';
import '../../../../objects/product_related/psu.dart';
import '../../../../objects/product_related/ram.dart';
import 'product_tab_state.dart';

abstract class TabCubit extends Cubit<TabState> {
  TabCubit() : super(const TabState());

  void initialize(FilterArgument filter, {String? searchText}) {
    emit(state.copyWith(
      productList: Database().productList,
      filteredProductList: Database().productList,
      searchText: searchText ?? '',
    ));
    emit(state.copyWith(
      manufacturerList: getManufacturerList(),
      filterArgument: filter.copyWith(
        manufacturerList: getManufacturerList(),
      ),
    ));
    applyFilters();
  }

  void updateFilter({
    FilterArgument? filter,
  }) {
    emit(state.copyWith(
      filterArgument: filter,
    ));
  }

  void toLoading() {
    emit(state.copyWith(processState: ProcessState.loading));
  }

  void updateSearchText(String? searchText) {
    emit(state.copyWith(searchText: searchText));
    applyFilters();
  }

  void updateTabIndex(int index) {
    emit(state.copyWith(filterArgument: state.filterArgument.copyWith(categoryList: [CategoryEnum.values[index]])));
    applyFilters();
  }

  void updateSortOption(SortEnum selectedOption) {
    emit(state.copyWith(selectedSortOption: selectedOption));
    applyFilters();
  }

  void setSelectedProduct(Product? product) {
    emit(state.copyWith(selectedProduct: product));
  }

  void applyFilters() {
    print('Apply filter');
    final filteredProducts = state.productList.where((product) {
      if (!product.productName.toLowerCase().contains(state.searchText.toLowerCase())) {
        return false;
      }

      if (!state.filterArgument.manufacturerList.any((manufacturer) => manufacturer.manufacturerID == product.manufacturer.manufacturerID)) {
        return false;
      }


      if (!matchesMinMax((product.price*(1 - product.discount)).toDouble(), state.filterArgument.minPrice, state.filterArgument.maxPrice)) {
        return false;
      }

      final bool matchesCategory;
      final index = getIndex();
      switch (index) {
        case 0:
          matchesCategory = state.filterArgument.categoryList.contains(product.category);
          break;
        case 1:
          matchesCategory = product.category == CategoryEnum.ram;
          break;
        case 2:
          matchesCategory = product.category == CategoryEnum.cpu;
          break;
        case 3:
          matchesCategory = product.category == CategoryEnum.psu;
          break;
        case 4:
          matchesCategory = product.category == CategoryEnum.gpu;
          break;
        case 5:
          matchesCategory = product.category == CategoryEnum.drive;
          break;
        case 6:
          matchesCategory = product.category == CategoryEnum.mainboard;
          break;
        default:
          matchesCategory = false;
      }

      if (!matchesCategory) {
        return false;
      }

      return matchFilter(product, state.filterArgument);
     }).toList();

    switch (state.selectedSortOption) {
      case SortEnum.releaseLatest:
        filteredProducts.sort((a, b) => b.release.compareTo(a.release));
        break;
      case SortEnum.releaseOldest:
        filteredProducts.sort((a, b) => a.release.compareTo(b.release));
        break;
      case SortEnum.salesHighest:
        filteredProducts.sort((a, b) => b.sales.compareTo(a.sales));
        break;
      case SortEnum.salesLowest:
        filteredProducts.sort((a, b) => a.sales.compareTo(b.sales));
        break;
      case SortEnum.cheapest:
        filteredProducts.sort((a, b) => (a.price * (1 - a.discount)).compareTo(b.price * (1 - b.discount)));
        break;
      case SortEnum.expensive:
        filteredProducts.sort((a, b) => (b.price * (1 - b.discount)).compareTo(a.price * (1 - a.discount)));
        break;
      case SortEnum.discountHighest:
        filteredProducts.sort((a, b) => b.discount.compareTo(a.discount));
        break;
      case SortEnum.discountLowest:
        filteredProducts.sort((a, b) => a.discount.compareTo(b.discount));
        break;
    }

    emit(state.copyWith(filteredProductList: filteredProducts));
  }

  int getIndex();
  List<Manufacturer> getManufacturerList();

  bool matchesMinMax(double value, String? minStr, String? maxStr) {
    final double min = double.tryParse(minStr ?? '') ?? 0;
    final double max = double.tryParse(maxStr ?? '') ?? double.infinity;
    return value >= min && value <= max;
  }

  bool matchFilter(Product product, FilterArgument filterArgument) {
    switch (product.category) {
      case CategoryEnum.ram:
        product as RAM;
        return filterArgument.ramBusList.contains(product.bus) &&
            filterArgument.ramCapacityList.contains(product.capacity) &&
            filterArgument.ramTypeList.contains(product.ramType);

      case CategoryEnum.cpu:
        product as CPU;
        final matchesCpuCore = matchesMinMax(product.core.toDouble(), state.filterArgument.minCpuCore, state.filterArgument.maxCpuCore);
        final matchesCpuThread = matchesMinMax(product.thread.toDouble(), state.filterArgument.minCpuThread, state.filterArgument.maxCpuThread);
        final matchesCpuClockSpeed = matchesMinMax(product.clockSpeed.toDouble(), state.filterArgument.minCpuClockSpeed, state.filterArgument.maxCpuClockSpeed);
        return filterArgument.cpuFamilyList.contains(product.family) &&
            matchesCpuCore &&
            matchesCpuThread &&
            matchesCpuClockSpeed;

      case CategoryEnum.gpu:
        product as GPU;
        final matchesGpuClockSpeed = matchesMinMax(product.clockSpeed, state.filterArgument.minGpuClockSpeed, state.filterArgument.maxGpuClockSpeed);
        return filterArgument.gpuBusList.contains(product.bus) &&
            filterArgument.gpuCapacityList.contains(product.capacity) &&
            filterArgument.gpuSeriesList.contains(product.series) &&
            matchesGpuClockSpeed;

      case CategoryEnum.mainboard:
        product as Mainboard;
        return filterArgument.mainboardFormFactorList.contains(product.formFactor) &&
            filterArgument.mainboardSeriesList.contains(product.series) &&
            filterArgument.mainboardCompatibilityList.contains(product.compatibility);

      case CategoryEnum.drive:
        product as Drive;
        return filterArgument.driveTypeList.contains(product.type) &&
            filterArgument.driveCapacityList.contains(product.capacity);

      case CategoryEnum.psu:
        product as PSU;
        final matchesPsuWattage = matchesMinMax(product.wattage.toDouble() ?? 0, state.filterArgument.minPsuWattage, state.filterArgument.maxPsuWattage);
        return filterArgument.psuModularList.contains(product.modular) &&
            filterArgument.psuEfficiencyList.contains(product.efficiency) &&
            matchesPsuWattage;
      default:
        return false;
    }
  }
}

class AllTabCubit extends TabCubit {
  @override
  int getIndex() {
    return 0;
  }

  @override
  List<Manufacturer> getManufacturerList() {
    return Database().manufacturerList;
  }
}

class RamTabCubit extends TabCubit {
  @override
  int getIndex() {
    return 1;
  }

  @override
  List<Manufacturer> getManufacturerList() {
    return state.productList
        .where((product) => product.category == CategoryEnum.ram)
        .map((product) => product.manufacturer)
        .toSet()
        .toList();
  }
}

class CpuTabCubit extends TabCubit {
  @override
  int getIndex() {
    return 2;
  }

  @override
  List<Manufacturer> getManufacturerList() {
    return state.productList
        .where((product) => product.category == CategoryEnum.cpu)
        .map((product) => product.manufacturer)
        .toSet()
        .toList();
  }
}

class PsuTabCubit extends TabCubit {
  @override
  int getIndex() {
    return 3;
  }

  @override
  List<Manufacturer> getManufacturerList() {
    return state.productList
        .where((product) => product.category == CategoryEnum.psu)
        .map((product) => product.manufacturer)
        .toSet()
        .toList();
  }
}

class GpuTabCubit extends TabCubit {
  @override
  int getIndex() {
    return 4;
  }

  @override
  List<Manufacturer> getManufacturerList() {
    return state.productList
        .where((product) => product.category == CategoryEnum.gpu)
        .map((product) => product.manufacturer)
        .toSet()
        .toList();
  }
}

class DriveTabCubit extends TabCubit {
  @override
  int getIndex() {
    return 5;
  }

  @override
  List<Manufacturer> getManufacturerList() {
    return state.productList
        .where((product) => product.category == CategoryEnum.drive)
        .map((product) => product.manufacturer)
        .toSet()
        .toList();
  }
}

class MainboardTabCubit extends TabCubit {
  @override
  int getIndex() {
    return 6;
  }

  @override
  List<Manufacturer> getManufacturerList() {
    return state.productList
        .where((product) => product.category == CategoryEnum.mainboard)
        .map((product) => product.manufacturer)
        .toSet()
        .toList();
  }
}