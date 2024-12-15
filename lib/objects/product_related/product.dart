import '../../enums/product_related/category_enum.dart';
import 'product_factory.dart';

abstract class Product {
  String? productID;
  final String productName;
  final double price;
  final String manufacturerID;

  Product({
    this.productID,
    required this.productName,
    required this.price,
    required this.manufacturerID,
  });

  Product changeCategory(Category newCategory, Map<String, dynamic> properties) {
    properties['productID'] = productID;
    return ProductFactory.createProduct(newCategory, properties);
  }
}