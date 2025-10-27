import 'package:gizmoglobe_client/enums/product_related/drive_enums/drive_type.dart';
import 'package:gizmoglobe_client/objects/product_related/drive_related/speed.dart';

import '../../../enums/product_related/category_enum.dart';
import '../../../enums/product_related/drive_enums/drive_form_factor.dart';
import '../../../enums/product_related/drive_enums/drive_gen.dart';
import '../../../enums/product_related/drive_enums/interface_type.dart';
import '../../../enums/product_related/product_status_enum.dart';
import '../../manufacturer.dart';
import '../product.dart';

class Drive extends Product {
  DriveGen gen;
  int memoryGb;
  InterfaceType interfaceType;
  Speed speed;
  DriveFormFactor formFactor;
  DriveType driveType;

  Drive({
    required super.productName,
    required super.price,
    required super.discount,
    required super.release,
    required super.manufacturer,

    super.imageUrl,
    super.enDescription,
    super.viDescription,
    super.category = CategoryEnum.drive,

    required this.gen,
    required this.memoryGb,
    required this.interfaceType,
    required this.speed,
    required this.formFactor,
    required this.driveType,
    required super.sales,
    required super.stock,
    required super.status,
    required super.discountedPrice,
  });
}


