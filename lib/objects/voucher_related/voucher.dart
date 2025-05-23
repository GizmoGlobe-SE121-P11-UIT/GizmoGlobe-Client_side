import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../enums/voucher_related/voucher_status.dart';

abstract class Voucher {
  String? voucherID;
  String voucherName;
  DateTime startTime;
  double discountValue;
  double minimumPurchase;
  int maxUsagePerPerson;
  bool isVisible;
  bool isEnabled;
  String? description;

  bool isPercentage;
  bool hasEndTime;
  bool isLimited;

  Voucher({
    this.voucherID,
    required this.voucherName,
    required this.startTime,
    required this.discountValue,
    required this.minimumPurchase,
    required this.maxUsagePerPerson,
    required this.isVisible,
    required this.isEnabled,
    this.description,

    required this.isPercentage,
    required this.hasEndTime,
    required this.isLimited,
  });

  void updateVoucher({
    String? voucherID,
    String? voucherName,
    double? discountValue,
    double? minimumPurchase,
    int? maxUsagePerPerson,
    DateTime? startTime,

    String? description,
    bool? isVisible,
    bool? isEnabled,
  }) {
    this.voucherID = voucherID ?? this.voucherID;
    this.voucherName = voucherName ?? this.voucherName;
    this.startTime = startTime ?? this.startTime;
    this.discountValue = discountValue ?? this.discountValue;
    this.minimumPurchase = minimumPurchase ?? this.minimumPurchase;
    this.maxUsagePerPerson = maxUsagePerPerson ?? this.maxUsagePerPerson;
    this.isVisible = isVisible ?? this.isVisible;
    this.isEnabled = isEnabled ?? this.isEnabled;
    this.description = description ?? this.description;
  }

  VoucherTimeStatus get voucherTimeStatus;
  bool get voucherRanOut;
  Widget detailsWidget(BuildContext context);
}

