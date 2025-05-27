import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher_factory.dart';

class VoucherArgument {
  String? voucherID;
  String? voucherName;
  DateTime? startTime;
  double? discountValue;
  double? minimumPurchase;
  int? maxUsagePerPerson;
  bool? isVisible;
  bool? isEnabled;
  String? description;

  bool? isPercentage;
  bool? hasEndTime;
  bool? isLimited;

  double? maximumDiscountValue;

  int? maximumUsage;
  int? usageLeft;

  DateTime? endTime;

  VoucherArgument({
    this.voucherID,
    this.voucherName,
    this.startTime,
    this.discountValue,
    this.minimumPurchase,
    this.maxUsagePerPerson,
    this.isVisible,
    this.isEnabled,
    this.description,

    this.isPercentage,
    this.hasEndTime,
    this.isLimited,
    
    this.maximumDiscountValue,
    
    this.maximumUsage,
    this.usageLeft,
    
    this.endTime,
  });

  VoucherArgument copyWith({
    String? voucherID,
    String? voucherName,
    DateTime? startTime,
    double? discountValue,
    double? minimumPurchase,
    int? maxUsagePerPerson,
    bool? isVisible,
    bool? isEnabled,
    String? description,

    bool? isPercentage,
    bool? hasEndTime,
    bool? isLimited,

    double? maximumDiscountValue,

    int? maximumUsage,
    int? usageLeft,

    DateTime? endTime,
  }) {
    return VoucherArgument(
      voucherID: voucherID ?? this.voucherID,
      voucherName: voucherName ?? this.voucherName,
      startTime: startTime ?? this.startTime,
      discountValue: discountValue ?? this.discountValue,
      minimumPurchase: minimumPurchase ?? this.minimumPurchase,
      maxUsagePerPerson: maxUsagePerPerson ?? this.maxUsagePerPerson,
      isVisible: isVisible ?? this.isVisible,
      isEnabled: isEnabled ?? this.isEnabled,
      description: description ?? this.description,

      isPercentage: isPercentage ?? this.isPercentage,
      hasEndTime: hasEndTime ?? this.hasEndTime,
      isLimited: isLimited ?? this.isLimited,

      maximumDiscountValue: maximumDiscountValue ?? this.maximumDiscountValue,

      maximumUsage: maximumUsage ?? this.maximumUsage,
      usageLeft: usageLeft ?? this.usageLeft,

      endTime: endTime ?? this.endTime,
    );
  }

  Voucher createVoucher() {
    try {
      if (isLimited == null || isPercentage == null || hasEndTime == null) {
        throw Exception('Voucher type properties must not be null');
      }
      return VoucherFactory.createVoucher(
        isLimited: isLimited!,
        isPercentage: isPercentage!,
        hasEndTime: hasEndTime!,
        properties: {
          'voucherID': voucherID,
          'voucherName': voucherName,
          'startTime': startTime,
          'discountValue': discountValue,
          'minimumPurchase': minimumPurchase,
          'maxUsagePerPerson': maxUsagePerPerson,
          'isVisible': isVisible,
          'isEnabled': isEnabled,
          'description': description,
          'maximumDiscountValue': maximumDiscountValue,
          'maximumUsage': maximumUsage,
          'usageLeft': usageLeft,
          'endTime': endTime,
          'isLimited': isLimited,
          'isPercentage': isPercentage,
          'hasEndTime': hasEndTime,
        },
      );
    } catch (e) {
      throw Exception('Failed to create voucher: $e');
    }
  }
}