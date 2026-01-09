import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_state.dart';
import '../../../../data/database/database.dart';

import '../../../../data/firebase/firebase.dart';
import '../../../../enums/processing/dialog_name_enum.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../objects/voucher_related/voucher.dart';

class VoucherScreenCubit extends Cubit<VoucherScreenState> {
  VoucherScreenCubit() : super(const VoucherScreenState());

  void toLoading() {
    if (isClosed) return;
    emit(state.copyWith(processState: ProcessState.loading));
  }

  void toSuccess() {
    if (isClosed) return;
    emit(state.copyWith(processState: ProcessState.success));
  }

  void toFailure(String message) {
    if (isClosed) return;
    emit(state.copyWith(
      processState: ProcessState.failure,
      dialogName: DialogName.failure,
      dialogMessage: message,
    ));
  }

  void setPoints(int points) {
    emit(state.copyWith(points: points));
  }

  void reloadVoucher() {
    try {
      final userVouchers = Database().ownedVoucherList;
      final ongoingVouchers = Database().ongoingVouchers;
      final upcomingVouchers = Database().upcomingVouchers;
      final redeemableVouchers = Database().redeemableVoucherList;

      if (isClosed) return;
      emit(state.copyWith(
        voucherList: userVouchers,
        ongoingList: ongoingVouchers,
        upcomingList: upcomingVouchers,
        redeemableList: redeemableVouchers,
        processState: ProcessState.success,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        dialogMessage: e.toString(),
      ));
    }
  }

  Future<void> initialize() async {
    // Load vouchers from Firebase first
    await Database().updateVoucherLists();

    // Then reload voucher lists into state
    reloadVoucher();
    setPoints(Database().loyalPoint);
  }

  Future<void> redeemVoucher(Voucher voucher) async {
    try {
      toLoading();
      final customerId = Database().userID;
      if (customerId.isEmpty) {
        throw Exception('No logged in user');
      }

      await Firebase().redeemVoucher(customerId, voucher);

      try {
        final int? redeemPrice = voucher.redeemPrice;
        if (redeemPrice != null && redeemPrice > 0) {
          await Database().subtractLoyalPoint(redeemPrice);
          setPoints(Database().loyalPoint);
        }
      } catch (e) {
        rethrow;
      }

      await initialize();
      toSuccess();
    } catch (e) {
      toFailure(e.toString());
      rethrow;
    }
  }
}
