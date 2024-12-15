import 'product.dart';

class PSU extends Product {
  final int wattage;
  final String efficiency;
  final String modular;

  PSU({
    required super.productName,
    required super.price,
    required super.manufacturerID,
    required this.wattage,
    required this.efficiency,
    required this.modular,
  });
}