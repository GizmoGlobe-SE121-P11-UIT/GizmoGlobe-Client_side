import 'package:flutter/cupertino.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';

import '../../enums/product_related/category_enum.dart';

abstract class Product {
  String? productID;
  String productName;
  CategoryEnum category;
  int price;
  double discount;
  int discountedPrice;
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
    if (locale.languageCode == 'vi') {
      return viDescription;
    } else {
      return enDescription;
    }
  }
}
