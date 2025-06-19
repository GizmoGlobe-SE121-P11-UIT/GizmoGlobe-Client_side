// lib/screens/cart/choose_voucher_screen/choose_voucher_screen_cubit.dart
import 'package:bloc/bloc.dart';
import '../../../data/database/database.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/voucher_related/voucher_status.dart';
import '../../../objects/voucher_related/percentage_interface.dart';
import '../../../objects/voucher_related/voucher.dart';
import 'choose_voucher_screen_state.dart';

class ChooseVoucherScreenCubit extends Cubit<ChooseVoucherScreenState> {
  ChooseVoucherScreenCubit() : super(const ChooseVoucherScreenState());

  void initialize(double totalAmount) {
    toLoading();
    loadAvailableVouchers(totalAmount);
  }

  void toLoading() {
    emit(state.copyWith(processState: ProcessState.loading, errorMessage: null));
  }

  Future<void> loadAvailableVouchers(double totalAmount) async {
    toLoading();

    await Database().updateVoucherLists();
    final vouchers = Database().getOngoingVouchers().where((voucher) {
      if (voucher.minimumPurchase > totalAmount) return false;
      return true;
    }).toList();

    emit(state.copyWith(
      availableVouchers: vouchers,
      processState: ProcessState.success,
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