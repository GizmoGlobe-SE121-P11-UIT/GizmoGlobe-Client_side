import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/voucher_related/percentage_interface.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import '../../enums/voucher_related/voucher_status.dart';
import '../../functions/helper.dart';
import '../../widgets/general/app_text_style.dart';

class UnlimitedPercentageVoucherWithoutEndTime
    extends Voucher
    implements PercentageInterface {
  double _maximumDiscountValue;

  UnlimitedPercentageVoucherWithoutEndTime({
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
    super.hasEndTime = true,
    super.isLimited = false,

    required double maximumDiscountValue,
  }) :
        _maximumDiscountValue = maximumDiscountValue;

  @override
  double get maximumDiscountValue => _maximumDiscountValue;
  @override
  set maximumDiscountValue(double value) => _maximumDiscountValue = value;

  @override
  void updateVoucher({
    String? voucherID,
    String? voucherName,
    DateTime? startTime,
    double? discountValue,
    double? minimumPurchase,
    int? maxUsagePerPerson,
    bool? isVisible,
    bool? isEnabled,
    String? enDescription,
    String? viDescription,
    DateTime? endTime,
    double? maximumDiscountValue,
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

    this.maximumDiscountValue = maximumDiscountValue ?? this.maximumDiscountValue;
  }

  @override
  Widget detailsWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            voucherName,
            style: AppTextStyle.regularTitle
        ),
        const SizedBox(height: 4),

        Text(
          'Discount $discountValue% maximum discount \$$maximumDiscountValue',
          style: AppTextStyle.regularText,
        ),
        const SizedBox(height: 4),

        Text(
          'Minimum purchase: \$$minimumPurchase',
          style: AppTextStyle.regularText,
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

  @override
  VoucherTimeStatus get voucherTimeStatus {
    if (startTime.isAfter(DateTime.now())) {
      return VoucherTimeStatus.upcoming;
    }

    return VoucherTimeStatus.ongoing;
  }

  @override
  bool get voucherRanOut {
    return false;
  }
}