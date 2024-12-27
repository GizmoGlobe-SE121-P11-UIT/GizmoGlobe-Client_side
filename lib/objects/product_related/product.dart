import 'package:gizmoglobe_client/objects/manufacturer.dart';

import '../../enums/product_related/category_enum.dart';
import '../../enums/product_related/product_status_enum.dart';
import 'product_factory.dart';

abstract class Product {
  String? productID;
  final String productName;
  final CategoryEnum category;
  final double price;
  final double? discount;
  DateTime release;
  int stock;
  final Manufacturer manufacturer;
  ProductStatusEnum status;

  double get discountedPrice => 
    discount != null ? price * (1 - discount! / 100) : price;

  Product({
    this.productID,
    required this.productName,
    required this.price,
    required this.manufacturer,
    required this.category,
    this.discount,
    required this.release,
    required this.stock,
    required this.status,
  });

  Product changeCategory(CategoryEnum newCategory, Map<String, dynamic> properties) {
    properties['productID'] = productID;
    return ProductFactory.createProduct(newCategory, properties);
  }
}