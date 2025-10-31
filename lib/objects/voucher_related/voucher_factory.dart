import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/objects/voucher_children/limited_percentage_voucher_with_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_children/limited_percentage_voucher_without_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_children/limited_amount_voucher_with_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_children/limited_amount_voucher_without_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_children/unlimited_percentage_voucher_with_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_children/unlimited_percentage_voucher_without_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_children/unlimited_amount_voucher_with_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_children/unlimited_amount_voucher_without_end_time.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';

typedef VoucherConstructor = Voucher Function(Map<String, dynamic>);

class VoucherFactory {
  static final Map<String, VoucherConstructor> voucherConstructors = {
    'limited_percentage_end': (props) => LimitedPercentageVoucherWithEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: true,
      isLimited: true,
      hasEndTime: true,
      maximumUsage: props['maximumUsage'],
      usageLeft: props['usageLeft'],
      maximumDiscountValue: props['maximumDiscountValue'],
      endTime: props['endTime'],
    ),

    'limited_percentage_noend': (props) => LimitedPercentageVoucherWithoutEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: true,
      isLimited: true,
      hasEndTime: false,
      maximumUsage: props['maximumUsage'],
      usageLeft: props['usageLeft'],
      maximumDiscountValue: props['maximumDiscountValue'],
    ),

    'limited_amount_end': (props) => LimitedAmountVoucherWithEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: false,
      isLimited: true,
      hasEndTime: true,
      maximumUsage: props['maximumUsage'],
      usageLeft: props['usageLeft'],
      endTime: props['endTime'],
    ),

    'limited_amount_noend': (props) => LimitedAmountVoucherWithoutEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: false,
      isLimited: true,
      hasEndTime: false,
      maximumUsage: props['maximumUsage'],
      usageLeft: props['usageLeft'],
    ),

    'unlimited_percentage_end': (props) => UnlimitedPercentageVoucherWithEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: true,
      isLimited: false,
      hasEndTime: true,
      maximumDiscountValue: props['maximumDiscountValue'],
      endTime: props['endTime'],
    ),

    'unlimited_percentage_noend': (props) => UnlimitedPercentageVoucherWithoutEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: true,
      isLimited: false,
      hasEndTime: false,
      maximumDiscountValue: props['maximumDiscountValue'],
    ),

    'unlimited_amount_end': (props) => UnlimitedAmountVoucherWithEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: false,
      isLimited: false,
      hasEndTime: true,
      endTime: props['endTime'],
    ),

    'unlimited_amount_noend': (props) => UnlimitedAmountVoucherWithoutEndTime(
      voucherID: props['voucherID'],
      voucherName: props['voucherName'],
      startTime: props['startTime'],
      discountValue: props['discountValue'],
      minimumPurchase: props['minimumPurchase'],
      maxUsagePerPerson: props['maxUsagePerPerson'],
      isVisible: props['isVisible'],
      isEnabled: props['isEnabled'],
      enDescription: props['enDescription'],
      viDescription: props['viDescription'],
      isPercentage: false,
      isLimited: false,
      hasEndTime: false,
    ),
  };

  static String getKey({
    required bool isLimited,
    required bool isPercentage,
    required bool hasEndTime,
  }) {
    return '${isLimited ? "limited" : "unlimited"}_'
        '${isPercentage ? "percentage" : "amount"}_'
        '${hasEndTime ? "end" : "noend"}';
  }

  static Map<String, dynamic> _normalizeProperties(Map<String, dynamic> props) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(props);

    // Keys expected as double
    final List<String> doubleKeys = [
      'discountValue',
    ];

    for (final key in doubleKeys) {
      final v = copy[key];
      if (v == null) continue;
      if (v is num) {
        copy[key] = v.toDouble();
      } else if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) copy[key] = parsed;
      }
    }

    final List<String> intKeys = [
      'minimumPurchase',
      'maximumDiscountValue',
      'maximumUsage',
      'usageLeft',
      'maxUsagePerPerson',
    ];

    for (final key in intKeys) {
      final v = copy[key];
      if (v == null) continue;
      if (v is num) {
        copy[key] = v.toInt();
      } else if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) copy[key] = parsed;
      }
    }

    // Datetime handling: accept DateTime, Firestore Timestamp, numeric millis, or ISO string
    final List<String> dateKeys = ['startTime', 'endTime'];
    for (final key in dateKeys) {
      final v = copy[key];
      if (v == null) continue;
      if (v is Timestamp) {
        copy[key] = v.toDate();
      } else if (v is int) {
        copy[key] = DateTime.fromMillisecondsSinceEpoch(v);
      } else if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) copy[key] = parsed;
      }
    }

    // Safe defaults
    copy['voucherName'] ??= '';
    copy['enDescription'] ??= '';
    copy['viDescription'] ??= '';

    // Defaults for numeric fields and ensure correct types
    if (copy['discountValue'] == null) copy['discountValue'] = 0.0;
    if (copy['minimumPurchase'] == null) copy['minimumPurchase'] = 0; // int
    if (copy['maxUsagePerPerson'] == null) copy['maxUsagePerPerson'] = 1.0;
    if (copy['maximumUsage'] == null) copy['maximumUsage'] = 0.0;
    if (copy['usageLeft'] == null) copy['usageLeft'] = 0.0;
    if (copy['maximumDiscountValue'] == null) copy['maximumDiscountValue'] = 0; // int

    copy['isVisible'] ??= true;
    copy['isEnabled'] ??= true;
    copy['isPercentage'] ??= false;
    copy['isLimited'] ??= false;
    copy['hasEndTime'] ??= false;

    if (copy['startTime'] == null) copy['startTime'] = DateTime.now();
    if (copy['hasEndTime'] == true && copy['endTime'] == null) {
      copy['endTime'] = DateTime.now().add(const Duration(days: 30));
    }

    return copy;
  }

  static Voucher createVoucher({
    required bool isLimited,
    required bool isPercentage,
    required bool hasEndTime,
    required Map<String, dynamic> properties,
  }) {
    final key = getKey(isLimited: isLimited, isPercentage: isPercentage, hasEndTime: hasEndTime);
    final constructor = voucherConstructors[key];
    if (constructor == null) throw Exception('Invalid voucher type: $key');

    final normalized = _normalizeProperties(properties);
    return constructor(normalized);
  }

  static Voucher fromMap(String voucherID, Map<String, dynamic> map) {
    final props = Map<String, dynamic>.from(map);
    props['voucherID'] = voucherID;

    final normalized = _normalizeProperties(props);

    return createVoucher(
      isLimited: normalized['isLimited'] as bool,
      isPercentage: normalized['isPercentage'] as bool,
      hasEndTime: normalized['hasEndTime'] as bool,
      properties: normalized,
    );
  }
}