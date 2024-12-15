import 'product.dart';

class CPU extends Product {
  final String family;
  final String core;
  final String thread;
  final double clockSpeed;

  CPU({
    required super.productName,
    required super.price,
    required super.manufacturerID,
    required this.family,
    required this.core,
    required this.thread,
    required this.clockSpeed,
  });
}