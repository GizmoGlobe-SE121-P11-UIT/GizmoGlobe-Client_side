import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';

import '../../enums/product_related/category_enum.dart';
import 'product_factory.dart';

abstract class Product {
  String? productID;
  String productName;
  CategoryEnum category;
  int price;
  double discount;
  double discountedPrice;
  DateTime release;
  int sales;
  int stock;
  Manufacturer manufacturer;
  ProductStatusEnum status;
  String? imageUrl;

  String? enDescription;
  String? viDescription;
  double priorityScore = 0.0;

  Product({
    this.productID,
    required this.productName,
    required this.manufacturer,
    required this.category,
    required this.price,
    required this.discount,
    required this.discountedPrice,
    required this.release,
    required this.sales,
    required this.stock,
    required this.status,
    this.imageUrl,

    this.enDescription,
    this.viDescription,
  });

  String? getDescription(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (kDebugMode) {
      print('Current locale: ${locale.languageCode}');
    }
    if (locale.languageCode == 'vi') {
      print('Returning Vietnamese description: $viDescription');
      return viDescription;
    } else {
      print('Returning English description: $enDescription');
      return enDescription;
    }
  }
}
