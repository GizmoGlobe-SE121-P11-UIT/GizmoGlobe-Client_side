import 'product.dart';

class Mainboard extends Product {
  final String formFactor;
  final String series;
  final String compatibility;

  Mainboard({
    required super.productName,
    required super.price,
    required super.manufacturerID,
    required this.formFactor,
    required this.series,
    required this.compatibility,
  });
}