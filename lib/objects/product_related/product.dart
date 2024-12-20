import 'package:gizmoglobe_client/objects/manufacturer.dart';

import '../../enums/product_related/category_enum.dart';
import 'product_factory.dart';

abstract class Product {
  String? productID;
  final String productName;
  final double price;
  final Manufacturer manufacturer;
  final CategoryEnum category;

  Product({
    this.productID,
    required this.productName,
    required this.price,
    required this.manufacturer,
    required this.category,
  });

  Product changeCategory(CategoryEnum newCategory, Map<String, dynamic> properties) {
    properties['productID'] = productID;
    return ProductFactory.createProduct(newCategory, properties);
  }
}