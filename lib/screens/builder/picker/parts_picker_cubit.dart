import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_state.dart';

class PartsPickerCubit extends Cubit<PartsPickerState> {
  final Database _database = Database();
  final CategoryEnum category;

  PartsPickerCubit(this.category) : super(const PartsPickerState());

  void loadProducts() {
    emit(state.copyWith(processState: ProcessState.loading));

    try {
      List<Product> products = [];

      switch (category) {
        case CategoryEnum.cpu:
          products = _database.cpuList
              .where((p) =>
                  p.status.getName() == 'active' ||
                  p.status.getName() == 'outOfStock')
              .toList();
          break;
        case CategoryEnum.mainboard:
          products = _database.mainboardList
              .where((p) =>
                  p.status.getName() == 'active' ||
                  p.status.getName() == 'outOfStock')
              .toList();
          break;
        case CategoryEnum.ram:
          products = _database.ramList
              .where((p) =>
                  p.status.getName() == 'active' ||
                  p.status.getName() == 'outOfStock')
              .toList();
          break;
        case CategoryEnum.gpu:
          products = _database.gpuList
              .where((p) =>
                  p.status.getName() == 'active' ||
                  p.status.getName() == 'outOfStock')
              .toList();
          break;
        case CategoryEnum.psu:
          products = _database.psuList
              .where((p) =>
                  p.status.getName() == 'active' ||
                  p.status.getName() == 'outOfStock')
              .toList();
          break;
        case CategoryEnum.drive:
          products = _database.driveList
              .where((p) =>
                  p.status.getName() == 'active' ||
                  p.status.getName() == 'outOfStock')
              .toList();
          break;
        default:
          products = [];
      }

      emit(state.copyWith(
        products: products,
        processState: ProcessState.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: e.toString(),
      ));
    }
  }

  void toggleProductSelection(Product product) {
    final currentSelected = List<Product>.from(state.selectedProducts);
    if (currentSelected.contains(product)) {
      currentSelected.remove(product);
    } else {
      currentSelected.add(product);
    }
    emit(state.copyWith(selectedProducts: currentSelected));
  }

  void clearSelection() {
    emit(state.copyWith(selectedProducts: []));
  }
}
