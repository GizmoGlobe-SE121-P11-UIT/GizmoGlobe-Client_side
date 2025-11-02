import 'package:gizmoglobe_client/enums/product_related/ram_enums/ram_type.dart';

import '../../../enums/product_related/category_enum.dart';
import '../../../enums/product_related/product_status_enum.dart';
import '../../manufacturer.dart';
import '../product.dart';

class RAM extends Product {
  RAMType type;
  int bus;
  int clLatency;
  int kitStickCount;
  int capacityPerStickGb;

  RAM({
    required super.productName,
    required super.price,
    required super.discount,
    required super.release,
    required super.manufacturer,

    super.imageUrl,
    super.enDescription,
    super.viDescription,
    super.category = CategoryEnum.ram,

    required this.type,
    required this.bus,
    required this.clLatency,
    required this.kitStickCount,
    required this.capacityPerStickGb,
    required super.sales,
    required super.stock,
    required super.status, required super.discountedPrice,
  });
}
