import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import '../../../enums/processing/sort_enum.dart';
// Import các enum cần thiết cho từng loại sản phẩm
// ... thêm các import khác

class ProductScreenCubit extends Cubit<ProductScreenState> {
  ProductScreenCubit() : super(const ProductScreenState());

  void initialize(List<Product> initialProducts, SortEnum initialSortOption) {
    emit(state.copyWith(
      initialProducts: initialProducts,
      initialSortOption: initialSortOption,
      selectedSortOption: initialSortOption,
    ));
  }

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