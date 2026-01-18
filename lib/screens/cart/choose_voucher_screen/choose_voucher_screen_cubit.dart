import 'package:bloc/bloc.dart';
import '../../../data/database/database.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../objects/voucher_related/percentage_interface.dart';
import '../../../objects/voucher_related/voucher.dart';
import 'choose_voucher_screen_state.dart';

class ChooseVoucherScreenCubit extends Cubit<ChooseVoucherScreenState> {
  ChooseVoucherScreenCubit() : super(const ChooseVoucherScreenState());

  void initialize(int totalAmount) {
    toLoading();
    loadAvailableVouchers(totalAmount);
  }

  void toLoading() {
    emit(
        state.copyWith(processState: ProcessState.loading, errorMessage: null));
  }

  Future<void> loadAvailableVouchers(int totalAmount) async {
    toLoading();

    await Database().updateVoucherLists();
    final vouchers = Database().ongoingVouchers.where((voucher) {
      if (voucher.minimumPurchase > totalAmount) return false;
      return true;
    }).toList();

    emit(state.copyWith(
      availableVouchers: vouchers,
      processState: ProcessState.success,
    ));
  }

  int calculateDiscount(Voucher voucher, int totalAmount) {
    if (voucher.isPercentage) {
      final calculatedDiscount =
          (totalAmount * (voucher.discountValue / 100)).round();

      final percentageVoucher = voucher as PercentageInterface;
      return calculatedDiscount > percentageVoucher.maximumDiscountValue
          ? percentageVoucher.maximumDiscountValue
          : calculatedDiscount;
    } else {
      final discountValue = voucher.discountValue.toInt();
      return discountValue > totalAmount ? totalAmount : discountValue;
    }
  }
}
