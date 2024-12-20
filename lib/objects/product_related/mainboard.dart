import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_compatibility.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import 'package:gizmoglobe_client/enums/product_related/mainboard_enums/mainboard_series.dart';

import '../../enums/product_related/category_enum.dart';
import 'product.dart';

class Mainboard extends Product {
  final MainboardFormFactor formFactor;
  final MainboardSeries series;
  final MainboardCompatibility compatibility;

  Mainboard({
    required super.productName,
    required super.price,
    required super.manufacturer,
    super.category = CategoryEnum.mainboard,
    required this.formFactor,
    required this.series,
    required this.compatibility,
  });
}