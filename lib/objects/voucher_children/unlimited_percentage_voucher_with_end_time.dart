import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/voucher_related/percentage_interface.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import '../../enums/voucher_related/voucher_status.dart';
import '../../functions/helper.dart';
import '../../widgets/general/app_text_style.dart';
import '../voucher_related/end_time_interface.dart';

class UnlimitedPercentageVoucherWithEndTime
    extends Voucher
    implements EndTimeInterface, PercentageInterface {
  double _maximumDiscountValue;
  DateTime _endTime;

  UnlimitedPercentageVoucherWithEndTime({
    super.voucherID,
    required super.voucherName,
    required super.startTime,
    required super.discountValue,
    required super.minimumPurchase,
    required super.maxUsagePerPerson,
    required super.isVisible,
    required super.isEnabled,
    super.description,

    super.isPercentage = false,
    super.hasEndTime = true,
    super.isLimited = false,

    required DateTime endTime,
    required double maximumDiscountValue,
  }) :
        _endTime = endTime,
        _maximumDiscountValue = maximumDiscountValue;

  @override
  DateTime get endTime => _endTime;
  @override
  set endTime(DateTime value) => _endTime = value;

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
    String? description,

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
      description: description,
    );

    this.endTime = endTime ?? this.endTime;
    this.maximumDiscountValue = maximumDiscountValue ?? this.maximumDiscountValue;
  }

  @override
  Widget detailsWidget(BuildContext context) {
    String time = Helper.getShortVoucherTimeWithEnd(startTime, endTime);

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
          Helper.getShortVoucherTimeWithEnd(startTime, endTime),
          style: time == 'Expired' ? AppTextStyle.regularText.copyWith(color: Colors.red) : AppTextStyle.regularText,
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
    if (endTime.isBefore(DateTime.now())) {
      return VoucherTimeStatus.expired;
    }
    return VoucherTimeStatus.ongoing;
  }

  @override
  bool get voucherRanOut {
    return false;
  }
}