import 'package:gizmoglobe_client/enums/product_related/cpu_enums/cpu_family.dart';

import '../../enums/product_related/category_enum.dart';
import 'product.dart';

class CPU extends Product {
  final CPUFamily family;
  final int core;
  final int thread;
  final double clockSpeed;

  CPU({
    required super.productName,
    required super.price,
    required super.manufacturer,
    super.category = CategoryEnum.cpu,
    required this.family,
    required this.core,
    required this.thread,
    required this.clockSpeed,
  });
}