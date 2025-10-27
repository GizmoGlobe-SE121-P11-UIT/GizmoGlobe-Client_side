import 'package:flutter/material.dart';

class PCIeSlot {
  int physicalSize;
  int electricalSpeed;
  int gen;
  int quantity;

  PCIeSlot({required this.physicalSize, required this.electricalSpeed, required this.gen, required this.quantity});

  factory PCIeSlot.fromJson(Map<String, dynamic> json) => PCIeSlot(
    physicalSize: (json['physicalSize'] is num) ? (json['physicalSize'] as num).toInt() : int.tryParse(json['physicalSize']?.toString() ?? '') ?? 0,
    electricalSpeed: (json['electricalSpeed'] is num) ? (json['electricalSpeed'] as num).toInt() : int.tryParse(json['electricalSpeed']?.toString() ?? '') ?? 0,
    gen: (json['gen'] is num) ? (json['gen'] as num).toInt() : int.tryParse(json['gen']?.toString() ?? '') ?? 0,
    quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
  );

  @override
  String toString() {
    final mode = (physicalSize == electricalSpeed)
        ? 'PCIe $gen.0 x$physicalSize mode'
        : 'PCIe $gen.0 x$physicalSize and running at x$electricalSpeed';
    return '$quantity x $mode (input $physicalSize-$electricalSpeed-$gen-$quantity)';
  }

  PCIeSlot copyWith({
    int? physicalSize,
    int? electricalSpeed,
    int? gen,
    int? quantity,
  }) {
    return PCIeSlot(
      physicalSize: physicalSize ?? this.physicalSize,
      electricalSpeed: electricalSpeed ?? this.electricalSpeed,
      gen: gen ?? this.gen,
      quantity: quantity ?? this.quantity,
    );
  }
}

class PCIeSlotControllers {
  final TextEditingController physicalSizeController;
  final TextEditingController electricalSpeedController;
  final TextEditingController genController;
  final TextEditingController quantityController;

  PCIeSlotControllers({
    String? physicalSize,
    String? electricalSpeed,
    String? gen,
    String? quantity,
  })  : physicalSizeController = TextEditingController(text: physicalSize),
        electricalSpeedController = TextEditingController(text: electricalSpeed),
        genController = TextEditingController(text: gen),
        quantityController = TextEditingController(text: quantity);

  void dispose() {
    physicalSizeController.dispose();
    electricalSpeedController.dispose();
    genController.dispose();
    quantityController.dispose();
  }
}