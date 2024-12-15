import 'product.dart';

class GPU extends Product {
  final String series;
  final String capacity;
  final String bus;
  final double clockSpeed;

  GPU({
    required super.productName,
    required super.price,
    required super.manufacturerID,
    required this.series,
    required this.capacity,
    required this.bus,
    required this.clockSpeed,
  });
}