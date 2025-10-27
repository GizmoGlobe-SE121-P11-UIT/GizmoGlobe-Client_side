import 'package:flutter/material.dart';

class Connector {
  String type;
  int quantity;

  Connector({required this.type, required this.quantity});

  factory Connector.fromJson(Map<String, dynamic> json) => Connector(
    type: json['type']?.toString() ?? '',
    quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
  );

  @override
  String toString() {
    return '$quantity x $type';
  }

  Connector copyWith({
    String? type,
    int? quantity,
  }) {
    return Connector(
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ConnectorControllers {
  final TextEditingController typeController;
  final TextEditingController quantityController;

  ConnectorControllers({
    String? type,
    String? quantity,
  })  : typeController = TextEditingController(text: type),
        quantityController = TextEditingController(text: quantity);

  void dispose() {
    typeController.dispose();
    quantityController.dispose();
  }
}