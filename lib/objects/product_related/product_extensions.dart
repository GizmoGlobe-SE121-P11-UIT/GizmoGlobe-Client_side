import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../enums/manufacturer/manufacturer_status.dart';

/// Extensions for Product class to provide additional functionality
extension ProductExtensions on Product {
  ProductStatusEnum get displayStatus {
    if (manufacturer.status == ManufacturerStatus.inactive) {
      return ProductStatusEnum.discontinued;
    }
    return status;
  }
}
