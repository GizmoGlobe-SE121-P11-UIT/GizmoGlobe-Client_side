import 'product.dart';

class Drive extends Product {
  final String type;
  final String capacity;

  Drive({
    required super.productName,
    required super.price,
    required super.vendorID,
    required this.type,
    required this.capacity,
  });
}