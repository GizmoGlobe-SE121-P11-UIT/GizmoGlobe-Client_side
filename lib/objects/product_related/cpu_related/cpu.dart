import 'package:gizmoglobe_client/enums/product_related/cpu_enums/cpu_series.dart';
import 'package:gizmoglobe_client/enums/product_related/cpu_enums/socket.dart';

import '../../../enums/product_related/category_enum.dart';
import '../../../enums/product_related/product_status_enum.dart';
import '../../manufacturer.dart';
import '../product.dart';

class CPU extends Product {
  CPUSeries series;
  Socket socket;
  int core;
  int thread;
  double baseClock;
  double turboClock;
  int tdp;

  CPU({
    required super.price,
    required super.discount,
    required super.release,
    required super.manufacturer,

    super.imageUrl,
    super.enDescription,
    super.viDescription,
    super.category = CategoryEnum.cpu,

    required this.series,
    required this.socket,
    required this.core,
    required this.thread,
    required this.baseClock,
    required this.tdp,
    required this.turboClock,
    required super.sales,
    required super.stock,
    required super.status,
    required super.productName,
    required super.discountedPrice,
  });
}