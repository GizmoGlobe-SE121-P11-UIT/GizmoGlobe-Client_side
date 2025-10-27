import 'package:flutter/material.dart';

class StorageSlot {
  int m2Slots;
  int sataPorts;

  StorageSlot({required this.m2Slots, required this.sataPorts});

  factory StorageSlot.fromJson(Map<String, dynamic> json) => StorageSlot(
    m2Slots: (json['m2Slots'] is num) ? (json['m2Slots'] as num).toInt() : int.tryParse(json['m2Slots']?.toString() ?? '') ?? 0,
    sataPorts: (json['sataPorts'] is num) ? (json['sataPorts'] as num).toInt() : int.tryParse(json['sataPorts']?.toString() ?? '') ?? 0,
  );

  @override
  String toString() {
    return '$m2Slots x M.2 Slots\n$sataPorts x SATA Ports';
  }

  StorageSlot copyWith({
    int? m2Slots,
    int? sataPorts,
  }) {
    return StorageSlot(
      m2Slots: m2Slots ?? this.m2Slots,
      sataPorts: sataPorts ?? this.sataPorts,
    );
  }
}

class StorageSlotControllers {
  final TextEditingController m2SlotsController;
  final TextEditingController sataPortsController;

  StorageSlotControllers({
    String? m2Slots,
    String? sataPorts,
  })  : m2SlotsController = TextEditingController(text: m2Slots),
        sataPortsController = TextEditingController(text: sataPorts);

  void dispose() {
    m2SlotsController.dispose();
    sataPortsController.dispose();
  }
}