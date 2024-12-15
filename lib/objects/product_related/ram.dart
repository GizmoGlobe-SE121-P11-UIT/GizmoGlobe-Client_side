import 'product.dart';

class RAM extends Product {
  final String bus;
  final String capacity;
  final String ramType;

  RAM({
    required super.productName,
    required super.price,
    required super.manufacturerID,
    required this.bus,
    required this.capacity,
    required this.ramType,
  });
}