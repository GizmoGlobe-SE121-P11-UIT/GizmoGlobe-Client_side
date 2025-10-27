import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/data/database/database.dart';

import '../../../../data/firebase/firebase.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../enums/processing/sort_enum.dart';
import '../../../../objects/product_related/cpu_related/cpu.dart';
import '../../../../objects/product_related/drive_related/drive.dart';
import '../../../../objects/product_related/filter_argument.dart';
import '../../../../objects/product_related/gpu_related/gpu.dart';
import '../../../../objects/product_related/mainboard_related/mainboard.dart';
import '../../../../objects/product_related/psu_related/psu.dart';
import '../../../../objects/product_related/ram_related/ram.dart';
import 'product_tab_state.dart';

abstract class TabCubit extends Cubit<TabState> {
  TabCubit() : super(const TabState());

  void initialize(FilterArgument filter, {String? searchText, required List<Product> initialProducts}) {
    emit(state.copyWith(
      manufacturerList: Database().manufacturerList,
      productList: initialProducts.isEmpty ? Database().productList : initialProducts,
      filteredProductList: initialProducts.isEmpty ? Database().productList : initialProducts,
      searchText: searchText ?? ''
    ));

    // Set the active category based on this tab's index so filters apply correctly on init
    final initialCategory = _categoryForIndex(getIndex());
    emit(state.copyWith(activeCategory: initialCategory));
    applyFilters();
  }

  // Map tab index explicitly to a category. Keeps mapping clear and resilient to enum order changes.
  CategoryEnum _categoryForIndex(int index) {
    switch (index) {
      case 1:
        return CategoryEnum.ram;
      case 2:
        return CategoryEnum.cpu;
      case 3:
        return CategoryEnum.psu;
      case 4:
        return CategoryEnum.gpu;
      case 5:
        return CategoryEnum.drive;
      case 6:
        return CategoryEnum.mainboard;
      default:
        return CategoryEnum.empty;
    }
  }

  Future<void> _fetchProducts() async {
    try {
      List<Product> products = await Firebase().getProducts();
      Database().updateProductList(products);

      emit(state.copyWith(productList: Database().productList, filteredProductList: Database().productList));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void updateFilter({FilterArgument? filter}) {
    emit(state.copyWith(filterArgument: filter));
  }

  void toLoading() {
    emit(state.copyWith(processState: ProcessState.loading));
  }

  void updateSearchText(String? searchText) {
    emit(state.copyWith(searchText: searchText));
    applyFilters();
  }

  void updateTabIndex(int index) {
    final newCategory = _categoryForIndex(index);
    emit(state.copyWith(activeCategory: newCategory));
    applyFilters();
  }

  void updateSortOption(SortEnum selectedOption) {
    emit(state.copyWith(selectedSortOption: selectedOption));
    applyFilters();
  }

  void updateProduct(List<Product> products) {
    emit(state.copyWith(productList: products));
    applyFilters();
  }

  void setSelectedProduct(Product? product) {
    emit(state.copyWith(selectedProduct: product));
  }

  void applyFilters() {
    if (kDebugMode) {
      print('Apply filter');
    }

    final allProducts = state.productList;
    final fa = state.filterArgument;
    final activeCategory = state.activeCategory;
    final query = state.searchText.trim();
    final applyCategory = activeCategory != CategoryEnum.empty;
    final applySearch = query.isNotEmpty;
    final queryLower = query.toLowerCase();

    final selectedMans = fa.manufacturerList;
    final applyManufacturer = selectedMans.isNotEmpty && !_isAllManufacturersSelected(selectedMans, state.manufacturerList);

    final List<Product> filteredProducts = <Product>[];

    for (final product in allProducts) {
      // Category
      if (applyCategory && product.category != activeCategory) continue;

      // Search
      if (applySearch && !product.productName.toLowerCase().contains(queryLower)) continue;

      // Manufacturer
      if (applyManufacturer) {
        final manu = product.manufacturer;
        if (!selectedMans.contains(manu)) continue;
      }

      // Price range
      if (!matchesMinMax(product.discountedPrice, fa.minPrice, fa.maxPrice)) continue;

      // Category-specific filters
      if (!matchFilter(product, fa)) continue;

      // Passed all checks
      filteredProducts.add(product);
    }

    // Sorting
    switch (state.selectedSortOption) {
      case SortEnum.releaseOldest:
        filteredProducts.sort((a, b) => a.release.compareTo(b.release));
        break;
      case SortEnum.priceHighest:
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortEnum.priceLowest:
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortEnum.salesHighest:
        filteredProducts.sort((a, b) => b.sales.compareTo(a.sales));
        break;
      case SortEnum.salesLowest:
        filteredProducts.sort((a, b) => a.sales.compareTo(b.sales));
        break;
      case SortEnum.discountHighest:
        filteredProducts.sort((a, b) => b.discount.compareTo(a.discount));
        break;
      case SortEnum.discountLowest:
        filteredProducts.sort((a, b) => a.discount.compareTo(b.discount));
        break;
      default:
        filteredProducts.sort((a, b) => b.sales.compareTo(a.sales));
    }

    emit(state.copyWith(filteredProductList: filteredProducts));
  }

  Future<void> changeStatus(Product product) async {
    try {
      ProductStatusEnum status;
      if (product.status == ProductStatusEnum.discontinued) {
        if (product.stock == 0) {
          status = ProductStatusEnum.outOfStock;
        } else {
          status = ProductStatusEnum.active;
        }
      } else {
        status = ProductStatusEnum.discontinued;
      }

      await Firebase().changeProductStatus(product.productID!, status);
      await reloadProducts();

      emit(state.copyWith(processState: ProcessState.success));
      applyFilters();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      emit(state.copyWith(processState: ProcessState.failure));
    }
  }

  Future<void> reloadProducts() async {
    toLoading();
    await _fetchProducts();
    emit(state.copyWith(manufacturerList: getManufacturerList()));
    applyFilters();
    emit(state.copyWith(processState: ProcessState.idle));
  }

  int getIndex();

  List<Manufacturer> getManufacturerList() {
    return Database().manufacturerList;
  }

  bool matchesMinMax(double value, String? minStr, String? maxStr) {
    final double min = double.tryParse(minStr ?? '') ?? 0;
    final double max = double.tryParse(maxStr ?? '') ?? double.infinity;
    return value >= min && value <= max;
  }

  bool matchedCpuClockSpeed(double baseClock, double turboClock, String? minStr, String? maxStr) {;
    final double min = double.tryParse(minStr ?? '') ?? 0;
    final double max = double.tryParse(maxStr ?? '') ?? double.infinity;
    return turboClock >= min && baseClock <= max;
  }

  // dart
  bool matchFilter(Product product, FilterArgument filterArgument) {
    // helpers
    bool shouldApplyRange(String? min, String? max) =>
        (min?.isNotEmpty == true) || (max?.isNotEmpty == true);

    bool applyRangeCheck(double value, String? min, String? max) {
      if (!shouldApplyRange(min, max)) return true;
      return matchesMinMax(value, min, max);
    }

    switch (product.category) {
      case CategoryEnum.ram:
        product as RAM;
        final memGb = (product.capacityPerStickGb * product.kitStickCount).toDouble();
        if (!applyRangeCheck(memGb, filterArgument.minMemoryGb, filterArgument.maxMemoryGb)) {
          return false;
        }
        if (filterArgument.ramType.isNotEmpty && !filterArgument.ramType.contains(product.type)) {
          return false;
        }
        return true;

      case CategoryEnum.cpu:
        product as CPU;
        if (shouldApplyRange(filterArgument.minClockSpeed, filterArgument.maxClockSpeed)) {
          if (!matchedCpuClockSpeed(
              product.baseClock, product.turboClock, filterArgument.minClockSpeed, filterArgument.maxClockSpeed)) {
            return false;
          }
        }

        if (!applyRangeCheck(product.tdp.toDouble(), filterArgument.minTdp, filterArgument.maxTdp)) {
          return false;
        }

        if (filterArgument.cpuSeries.isNotEmpty && !filterArgument.cpuSeries.contains(product.series)) {
          return false;
        }
        if (filterArgument.sockets.isNotEmpty && !filterArgument.sockets.contains(product.socket)) {
          return false;
        }

        return true;

      case CategoryEnum.gpu:
        product as GPU;
        if (shouldApplyRange(filterArgument.minClockSpeed, filterArgument.maxClockSpeed)) {
          if (!applyRangeCheck(product.boostClock.toDouble(), filterArgument.minClockSpeed, filterArgument.maxClockSpeed)) {
            return false;
          }
        }

        if (!applyRangeCheck(product.memory.toDouble(), filterArgument.minMemoryGb, filterArgument.maxMemoryGb)) {
          return false;
        }

        if (!applyRangeCheck(product.tdp.toDouble(), filterArgument.minTdp, filterArgument.maxTdp)) {
          return false;
        }

        if (filterArgument.gpuVersion.isNotEmpty && !filterArgument.gpuVersion.contains(product.version)) {
          return false;
        }

        if (filterArgument.gpuSeries.isNotEmpty && !filterArgument.gpuSeries.contains(product.series)) {
          return false;
        }

        return true;

      case CategoryEnum.mainboard:
        product as Mainboard;
        final maxRamGb = (product.ramSpec.maxSingleDimmGb * product.ramSpec.slots).toDouble();
        if (!applyRangeCheck(maxRamGb, filterArgument.minMemoryGb, filterArgument.maxMemoryGb)) {
          return false;
        }

        if (!applyRangeCheck(product.storageSlot.m2Slots.toDouble(), filterArgument.minM2Slots, filterArgument.maxM2Slots)) {
          return false;
        }

        if (!applyRangeCheck(product.storageSlot.sataPorts.toDouble(), filterArgument.minSataPorts, filterArgument.maxSataPorts)) {
          return false;
        }

        if (filterArgument.mainboardFormFactor.isNotEmpty && !filterArgument.mainboardFormFactor.contains(product.formFactor)) {
          return false;
        }

        if (filterArgument.sockets.isNotEmpty && !filterArgument.sockets.contains(product.socket)) {
          return false;
        }

        if (filterArgument.ramType.isNotEmpty && !filterArgument.ramType.contains(product.ramSpec.type)) {
          return false;
        }

        return true;

      case CategoryEnum.drive:
        product as Drive;
        if (!applyRangeCheck(product.memoryGb.toDouble(), filterArgument.minMemoryGb, filterArgument.maxMemoryGb)) {
          return false;
        }
        if (filterArgument.driveType.isNotEmpty && !filterArgument.driveType.contains(product.driveType)) {
          return false;
        }
        if (filterArgument.driveFormFactor.isNotEmpty && !filterArgument.driveFormFactor.contains(product.formFactor)) {
          return false;
        }
        if (filterArgument.interfaceType.isNotEmpty && !filterArgument.interfaceType.contains(product.interfaceType)) {
          return false;
        }
        if (filterArgument.gen.isNotEmpty && !filterArgument.gen.contains(product.gen)) {
          return false;
        }

        return true;

      case CategoryEnum.psu:
        product as PSU;
        if (!applyRangeCheck(product.maxWattage.toDouble(), filterArgument.minTdp, filterArgument.maxTdp)) {
          return false;
        }

        // If both lists empty -> don't filter by PSU attributes
        if (filterArgument.psuModularity.isEmpty && filterArgument.psuEfficiency.isEmpty) {
          return true;
        }

        if (filterArgument.psuModularity.isNotEmpty && !filterArgument.psuModularity.contains(product.modularity)) {
          return false;
        }

        if (filterArgument.psuEfficiency.isNotEmpty && !filterArgument.psuEfficiency.contains(product.efficiency)) {
          return false;
        }

        return true;

      default:
        return true;
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

bool _isAllManufacturersSelected(List<Manufacturer> selected, List<Manufacturer> all) {
  if (all.isEmpty) return false;
  final selIds = selected.map((m) => m.manufacturerID).toSet();
  final allIds = all.map((m) => m.manufacturerID).toSet();
  return selIds.length == allIds.length && selIds.containsAll(allIds);
}