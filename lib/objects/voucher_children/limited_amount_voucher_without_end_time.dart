import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import '../../enums/voucher_related/voucher_status.dart';
import '../../functions/helper.dart';
import '../../widgets/general/app_text_style.dart';
import '../voucher_related/limited_interface.dart';

class LimitedAmountVoucherWithoutEndTime extends Voucher
    implements LimitedInterface {
  int _maximumUsage;
  int _usageLeft;

  LimitedAmountVoucherWithoutEndTime({
    super.voucherID,
    required super.voucherName,
    required super.startTime,
    required super.discountValue,
    required super.minimumPurchase,
    required super.maxUsagePerPerson,
    required super.isVisible,
    required super.isEnabled,
    super.enDescription,
    super.viDescription,
    super.isPercentage = false,
    super.hasEndTime = false,
    super.isLimited = true,
    required int maximumUsage,
    required int usageLeft,
  })  : _maximumUsage = maximumUsage,
        _usageLeft = usageLeft;

  @override
  int get maximumUsage => _maximumUsage;
  @override
  set maximumUsage(int value) => _maximumUsage = value;

  @override
  int get usageLeft => _usageLeft;
  @override
  set usageLeft(int value) => _usageLeft = value;

  @override
  void updateVoucher({
    String? voucherID,
    String? voucherName,
    DateTime? startTime,
    double? discountValue,
    int? minimumPurchase,
    int? maxUsagePerPerson,
    bool? isVisible,
    bool? isEnabled,
    String? enDescription,
    String? viDescription,
    int? maximumUsage,
    int? usageLeft,
  }) {
    super.updateVoucher(
      voucherID: voucherID,
      voucherName: voucherName,
      startTime: startTime,
      discountValue: discountValue,
      minimumPurchase: minimumPurchase,
      maxUsagePerPerson: maxUsagePerPerson,
      isVisible: isVisible,
      isEnabled: isEnabled,
      enDescription: enDescription,
      viDescription: viDescription,
    );

    this.maximumUsage = maximumUsage ?? this.maximumUsage;
    this.usageLeft = usageLeft ?? this.usageLeft;
  }

  @override
  VoucherTimeStatus get voucherTimeStatus {
    if (startTime.isAfter(DateTime.now())) {
      return VoucherTimeStatus.upcoming;
    }
    return VoucherTimeStatus.ongoing;
  }

  @override
  bool get voucherRanOut {
    if (usageLeft <= 0) {
      return true;
    }
    return false;
  }

  @override
  Widget detailsWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(voucherName, style: AppTextStyle.regularTitle),
        const SizedBox(height: 4),
        Text(
          'Discount ${Helper.toCurrencyFormat(discountValue)}',
          style: AppTextStyle.regularText,
        ),
        const SizedBox(height: 4),
        Text(
          'Minimum purchase: ${Helper.toCurrencyFormat(minimumPurchase)}',
          style: AppTextStyle.regularText,
        ),
        const SizedBox(height: 4),
        usageLeft > 0
            ? Text(
                'Usage left: $usageLeft/$maximumUsage',
                style: AppTextStyle.regularText,
              )
            : Text(
                'Ran out',
                style: AppTextStyle.regularText.copyWith(color: Colors.red),
              ),
        const SizedBox(height: 4),
        Text(
          Helper.getShortVoucherTimeWithoutEnd(startTime),
          style: AppTextStyle.regularText,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
