import 'package:gizmoglobe_client/enums/product_related/gpu_enums/gpu_series.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';

import '../../../enums/product_related/category_enum.dart';
import '../../../enums/product_related/gpu_enums/gpu_version.dart';
import '../mainboard_related/io_port.dart';
import '../../manufacturer.dart';
import '../product.dart';

class GPU extends Product {
  GPUSeries series;
  GPUVersion version;
  int memory;
  double boostClock;
  int tdp;
  List<IOPort> ports;

  GPU({
    required super.productName,
    required super.price,
    required super.discount,
    required super.release,
    required super.manufacturer,

    super.imageUrl,
    super.enDescription,
    super.viDescription,
    super.category = CategoryEnum.gpu,

    required this.series,
    required this.version,
    required this.memory,
    required this.boostClock,
    required this.tdp,
    required this.ports,
    required super.sales,
    required super.stock,
    required super.status, required super.discountedPrice,
  });
}