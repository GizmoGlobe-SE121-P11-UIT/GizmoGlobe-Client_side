import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/voucher_related/percentage_interface.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import '../../enums/voucher_related/voucher_status.dart';
import '../../functions/helper.dart';
import '../../widgets/general/app_text_style.dart';
import '../voucher_related/end_time_interface.dart';
import '../voucher_related/limited_interface.dart';

class LimitedPercentageVoucherWithEndTime
    extends Voucher
    implements LimitedInterface, EndTimeInterface, PercentageInterface {
  int _maximumUsage;
  int _usageLeft;
  int _maximumDiscountValue;
  DateTime _endTime;

  LimitedPercentageVoucherWithEndTime({
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

    super.isPercentage = true,
    super.hasEndTime = true,
    super.isLimited = true,

    required int maximumUsage,
    required int usageLeft,
    required DateTime endTime,
    required int maximumDiscountValue,
  }) :
        _maximumUsage = maximumUsage,
        _usageLeft = usageLeft,
        _endTime = endTime,
        _maximumDiscountValue = maximumDiscountValue;

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
  int get maximumDiscountValue => _maximumDiscountValue;
  @override
  set maximumDiscountValue(int value) => _maximumDiscountValue = value;

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
    DateTime? endTime,
    int? maximumDiscountValue,
  }) {
    super.updateVoucher(
      voucherID: voucherID,
      voucherName: voucherName,
      startTime: startTime,
      discountValue: discountValue,
      minimumPurchase: minimumPurchase,
      maxUsagePerPerson: maxUsagePerPerson,
      isVisible: isVisible,
      enDescription: enDescription,
      viDescription: viDescription,
    );

    this.maximumUsage = maximumUsage ?? this.maximumUsage;
    this.usageLeft = usageLeft ?? this.usageLeft;
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
          'Discount $discountValue% maximum discount ${Helper.toCurrencyFormat(maximumDiscountValue)}',
          style: AppTextStyle.regularText,
        ),
        const SizedBox(height: 4),

        Text(
          'Minimum purchase: ${Helper.toCurrencyFormat(minimumPurchase)}',
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
}