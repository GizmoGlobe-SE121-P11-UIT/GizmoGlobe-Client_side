import 'package:flutter/cupertino.dart';

import '../../enums/voucher_related/voucher_status.dart';

abstract class Voucher {
  String? voucherID;
  String voucherName;
  DateTime startTime;
  double discountValue;
  int minimumPurchase;
  int maxUsagePerPerson;
  bool isVisible;
  bool isEnabled;
  String? enDescription;
  String? viDescription;

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
    this.enDescription,
    this.viDescription,
    required this.isPercentage,
    required this.hasEndTime,
    required this.isLimited,
  });

  void updateVoucher({
    String? voucherID,
    String? voucherName,
    double? discountValue,
    int? minimumPurchase,
    int? maxUsagePerPerson,
    DateTime? startTime,
    String? enDescription,
    String? viDescription,
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
    this.enDescription = enDescription ?? this.enDescription;
    this.viDescription = viDescription ?? this.viDescription;
  }

  String? getDescription(BuildContext context) {
    final locale = Localizations.localeOf(context);
    print('Current locale: ${locale.languageCode}');
    if (locale.languageCode == 'vi') {
      print('Returning Vietnamese description: $viDescription');
      return viDescription;
    } else {
      print('Returning English description: $enDescription');
      return enDescription;
    }
  }

  VoucherTimeStatus get voucherTimeStatus;
  bool get voucherRanOut;
  Widget detailsWidget(BuildContext context);
}
