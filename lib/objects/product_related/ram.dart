import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_bus.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_capacity_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';

import '../../enums/product_related/category_enum.dart';
import 'product.dart';

class RAM extends Product {
  final RAMBus bus;
  final RAMCapacity capacity;
  final RAMType ramType;

  RAM({
    required super.productName,
    required super.price,
    required super.manufacturer,
    super.category = CategoryEnum.ram,
    required this.bus,
    required this.capacity,
    required this.ramType,
  });
}