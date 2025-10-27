import 'package:flutter/material.dart';

class IOPort {
  String port;
  int quantity;

  IOPort({required this.port, required this.quantity});

  factory IOPort.fromJson(Map<String, dynamic> json) => IOPort(
    port: json['port']?.toString() ?? '',
    quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
  );

  @override
  String toString() => '$quantity x $port';

  IOPort copyWith({
    String? port,
    int? quantity,
  }) {
    return IOPort(
      port: port ?? this.port,
      quantity: quantity ?? this.quantity,
    );
  }
}

class IOPortControllers {
  final TextEditingController portController;
  final TextEditingController quantityController;

  IOPortControllers({
    String? port,
    String? quantity,
  })  : portController = TextEditingController(text: port),
        quantityController = TextEditingController(text: quantity);

  void dispose() {
    portController.dispose();
    quantityController.dispose();
  }
}