// lib/screens/cart/choose_voucher_screen/choose_voucher_screen_cubit.dart
import 'package:bloc/bloc.dart';
import '../../../data/database/database.dart';
import '../../../enums/voucher_related/voucher_status.dart';
import '../../../objects/voucher_related/percentage_interface.dart';
import '../../../objects/voucher_related/voucher.dart';
import 'choose_voucher_screen_state.dart';
import 'package:intl/intl.dart';

class ChooseVoucherScreenCubit extends Cubit<ChooseVoucherScreenState> {
  ChooseVoucherScreenCubit() : super(const ChooseVoucherScreenState());

  void initialize(double totalAmount) {
    emit(state.copyWith(isLoading: true));
    loadAvailableVouchers(totalAmount);
  }

  void loadAvailableVouchers(double totalAmount) {
    final vouchers = Database().voucherList.where((voucher) {
      if (!voucher.isVisible || !voucher.isEnabled) return false;

      if (voucher.minimumPurchase > totalAmount) return false;

      if (voucher.voucherTimeStatus == VoucherTimeStatus.ongoing) {
        return true;
      }

      return false;
    }).toList();

    emit(state.copyWith(
      availableVouchers: vouchers,
      isLoading: false,
    ));
  }

  double calculateDiscount(Voucher voucher, double totalAmount) {
    if (voucher.isPercentage) {
      final calculatedDiscount = totalAmount * (voucher.discountValue / 100);

      final percentageVoucher = voucher as PercentageInterface;
      return calculatedDiscount > percentageVoucher.maximumDiscountValue
          ? percentageVoucher.maximumDiscountValue
          : calculatedDiscount;
    } else {
      return voucher.discountValue > totalAmount ? totalAmount : voucher.discountValue;
    }
  }
}