import 'package:flutter/cupertino.dart';
import 'package:gizmoglobe_client/enums/voucher_related/distribution_type.dart';

import '../../enums/voucher_related/voucher_status.dart';

abstract class Voucher {
  String? voucherID;
  String voucherName;
  DateTime startTime;
  int discountValue;
  int minimumPurchase;
  int maxUsagePerPerson;
  DistributionType distributionType;
  bool isEnabled;
  String? enDescription;
  String? viDescription;
  int? redeemPrice;

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
    required this.distributionType,
    required this.isEnabled,
    this.enDescription,
    this.viDescription,
    required this.isPercentage,
    required this.hasEndTime,
    required this.isLimited,
    this.redeemPrice,
  });

  void updateVoucher({
    String? voucherID,
    String? voucherName,
    int? discountValue,
    int? minimumPurchase,
    int? maxUsagePerPerson,
    DateTime? startTime,
    String? enDescription,
    String? viDescription,
    DistributionType? distributionType,
    int? redeemPrice,
    bool? isEnabled,
  }) {
    this.voucherID = voucherID ?? this.voucherID;
    this.voucherName = voucherName ?? this.voucherName;
    this.startTime = startTime ?? this.startTime;
    this.discountValue = discountValue ?? this.discountValue;
    this.minimumPurchase = minimumPurchase ?? this.minimumPurchase;
    this.maxUsagePerPerson = maxUsagePerPerson ?? this.maxUsagePerPerson;
    this.distributionType = distributionType ?? this.distributionType;
    this.isEnabled = isEnabled ?? this.isEnabled;
    this.enDescription = enDescription ?? this.enDescription;
    this.viDescription = viDescription ?? this.viDescription;
    this.redeemPrice = redeemPrice ?? this.redeemPrice;
  }

  String? getDescription(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'vi') {
      return viDescription;
    } else {
      return enDescription;
    }
  }

  VoucherTimeStatus get voucherTimeStatus;
  bool get voucherRanOut;
  Widget detailsWidget(BuildContext context);
}
