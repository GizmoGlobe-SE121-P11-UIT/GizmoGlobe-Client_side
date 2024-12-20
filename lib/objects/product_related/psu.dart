import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_efficiency.dart';
import 'package:gizmoglobe_client/enums/product_related/psu_enums/psu_modular.dart';

import '../../enums/product_related/category_enum.dart';
import 'product.dart';

class PSU extends Product {
  final int wattage;
  final PSUEfficiency efficiency;
  final PSUModular modular;

  PSU({
    required super.productName,
    required super.price,
    required super.manufacturer,
    super.category = CategoryEnum.psu,
    required this.wattage,
    required this.efficiency,
    required this.modular,
  });
}