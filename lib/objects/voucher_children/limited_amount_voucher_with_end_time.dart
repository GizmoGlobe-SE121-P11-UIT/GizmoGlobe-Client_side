import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/functions/converter.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import '../../enums/voucher_related/voucher_status.dart';
import '../../widgets/general/app_text_style.dart';
import '../voucher_related/end_time_interface.dart';
import '../voucher_related/limited_interface.dart';

class LimitedAmountVoucherWithEndTime
    extends Voucher
    implements LimitedInterface, EndTimeInterface {
  int _maximumUsage;
  int _usageLeft;
  DateTime _endTime;

  LimitedAmountVoucherWithEndTime({
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
    super.isLimited = true,

    required int maximumUsage,
    required int usageLeft,
    required DateTime endTime,
  }) :
        _maximumUsage = maximumUsage,
        _usageLeft = usageLeft,
        _endTime = endTime;

  @override
  int get maximumUsage => _maximumUsage;
  @override
  set maximumUsage(int value) => _maximumUsage = value;

  @override
  int get usageLeft => _usageLeft;
  @override
  set usageLeft(int value) => _usageLeft = value;

  @override
  DateTime get endTime => _endTime;
  @override
  set endTime(DateTime value) => _endTime = value;

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

    int? maximumUsage,
    int? usageLeft,
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
      description: description,
    );

    this.maximumUsage = maximumUsage ?? this.maximumUsage;
    this.usageLeft = usageLeft ?? this.usageLeft;
    this.endTime = endTime ?? this.endTime;
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
    if (usageLeft <= 0) {
      return true;
    }
    return false;
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
          'Discount \$$discountValue',
          style: AppTextStyle.regularText,
        ),
        const SizedBox(height: 4),

        Text(
          'Minimum purchase: \$$minimumPurchase',
          style: AppTextStyle.regularText,
        ),
        const SizedBox(height: 4),

        usageLeft > 0 ?
        Text(
          'Usage left: $usageLeft/$maximumUsage',
          style: AppTextStyle.regularText,
        ) :
        Text(
          'Ran out',
          style: AppTextStyle.regularText.copyWith(color: Colors.red),
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
}