import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';

import '../../../enums/product_related/category_enum.dart';
import '../../../objects/product_related/cpu.dart';
import '../../../objects/product_related/drive.dart';
import '../../../objects/product_related/gpu.dart';
import '../../../objects/product_related/mainboard.dart';
import '../../../objects/product_related/psu.dart';
import '../../../objects/product_related/ram.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(Product product) : super(ProductDetailState(product: product)) {
    _initializeTechnicalSpecs();
  }

  void _initializeTechnicalSpecs() {
    final product = state.product;
    final Map<String, String> specs = {};

    switch (product.category) {
      case CategoryEnum.ram:
        final ram = product as RAM;
        specs.addAll({
          'Bus': ram.bus.toString(),
          'Capacity': ram.capacity.toString(),
          'Type': ram.ramType.toString(),
        });
        break;

      case CategoryEnum.cpu:
        final cpu = product as CPU;
        specs.addAll({
          'Family': cpu.family.toString(),
          'Core': cpu.core.toString(),
          'Thread': cpu.thread.toString(),
          'Clock Speed': '${cpu.clockSpeed} GHz',
        });
        break;

      case CategoryEnum.gpu:
        final gpu = product as GPU;
        specs.addAll({
          'Series': gpu.series.toString(),
          'Memory': gpu.capacity.toString(),
          'Bus Width': gpu.bus.toString(),
          'Clock Speed': '${gpu.clockSpeed} MHz',
        });
        break;

      case CategoryEnum.mainboard:
        final mainboard = product as Mainboard;
        specs.addAll({
          'Form Factor': mainboard.formFactor.toString(),
          'Series': mainboard.series.toString(),
          'Compatibility': mainboard.compatibility.toString(),
        });
        break;

      case CategoryEnum.drive:
        final drive = product as Drive;
        specs.addAll({
          'Type': drive.type.toString(),
          'Capacity': drive.capacity.toString(),
        });
        break;

      case CategoryEnum.psu:
        final psu = product as PSU;
        specs.addAll({
          'Wattage': '${psu.wattage}W',
          'Efficiency': psu.efficiency.toString(),
          'Modular': psu.modular.toString(),
        });
        break;
    }

    emit(state.copyWith(technicalSpecs: specs));
  }
}