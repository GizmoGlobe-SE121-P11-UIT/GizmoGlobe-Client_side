import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../enums/manufacturer/manufacturer_status.dart';

/// Extensions for Product class to provide additional functionality
extension ProductExtensions on Product {
  /// Returns the display status for the product, accounting for manufacturer status
  ///
  /// If the manufacturer is inactive, the product will be displayed as discontinued
  /// regardless of its actual status in the database
  ProductStatusEnum get displayStatus {
    // If manufacturer is inactive, show product as discontinued
    if (manufacturer.status == ManufacturerStatus.inactive) {
      return ProductStatusEnum.discontinued;
    }

    // Otherwise use the product's actual status
    return status;
  }
}
