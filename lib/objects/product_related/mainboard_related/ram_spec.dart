import 'package:flutter/material.dart';

import '../../../enums/product_related/ram_enums/ram_type.dart';
import '../../../generated/l10n.dart';

class RamSpec {
  RAMType type;
  int slots;
  int maxSingleDimmGb;

  RamSpec({
    required this.type,
    required this.slots,
    required this.maxSingleDimmGb,
  });

  void updateRamSpec(
      {RAMType? type, int? slots, int? maxSingleDimmGb, int? maxTotalGb}) {
    this.type = type ?? this.type;
    this.slots = slots ?? this.slots;
    this.maxSingleDimmGb = maxSingleDimmGb ?? this.maxSingleDimmGb;
  }

  factory RamSpec.fromJson(Map<String, dynamic> json) => RamSpec(
        type: RAMTypeExtension.fromName(json['type'].toString()),
        slots: (json['slots'] is num)
            ? (json['slots'] as num).toInt()
            : int.tryParse(json['slots']?.toString() ?? '') ?? 0,
        maxSingleDimmGb: (json['maxSingleDimmGb'] is num)
            ? (json['maxSingleDimmGb'] as num).toInt()
            : int.tryParse(json['maxSingleDimmGb']?.toString() ?? '') ?? 0,
      );

  @override
  String toString() {
    final total = slots * maxSingleDimmGb;
    return '$slots x ${type.toString()}\nMax $maxSingleDimmGb GB each\n$total GB in total';
  }

  String toLocalizedString(S s) {
    final total = slots * maxSingleDimmGb;
    return '$slots x ${type.toString()}\n${s.max} $maxSingleDimmGb ${s.gbEach}\n$total ${s.gbInTotal}';
  }
}

class RamSpecControllers {
  final TextEditingController typeController;
  final TextEditingController slotsController;
  final TextEditingController maxSingleDimmGbController;

  RamSpecControllers({
    RAMType? type,
    int? slots,
    int? maxSingleDimmGb,
  })  : typeController = TextEditingController(text: type.toString()),
        slotsController = TextEditingController(text: slots.toString()),
        maxSingleDimmGbController =
            TextEditingController(text: maxSingleDimmGb.toString());

  void dispose() {
    typeController.dispose();
    slotsController.dispose();
    maxSingleDimmGbController.dispose();
  }
}
