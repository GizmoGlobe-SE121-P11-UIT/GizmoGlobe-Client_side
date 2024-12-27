import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/product_factory.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import '../../../enums/processing/sort_enum.dart';
import '../../../enums/product_related/cpu_enums/cpu_family.dart';
import '../../../enums/product_related/drive_enums/drive_capacity.dart';
import '../../../enums/product_related/drive_enums/drive_type.dart';
import '../../../enums/product_related/gpu_enums/gpu_bus.dart';
import '../../../enums/product_related/gpu_enums/gpu_capacity.dart';
import '../../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_compatibility.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_series.dart';
import '../../../enums/product_related/product_status_enum.dart';
// Import các enum cần thiết cho từng loại sản phẩm
import '../../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../../enums/product_related/psu_enums/psu_modular.dart';
import '../../../enums/product_related/ram_enums/ram_bus.dart';
import '../../../enums/product_related/ram_enums/ram_capacity_enum.dart';
import '../../../enums/product_related/ram_enums/ram_type.dart';
// ... thêm các import khác

class ProductScreenCubit extends Cubit<ProductScreenState> {
  ProductScreenCubit() : super(const ProductScreenState());

  void updateSelectedTabIndex(int index) {
    emit(state.copyWith(selectedTabIndex: index));
  }

  void updateSearchText(String? searchText) {
    emit(state.copyWith(searchText: searchText));
  }

  void updateSortOption(SortEnum selectedOption) {
    emit(state.copyWith(selectedSortOption: selectedOption));
  }
}