import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_state.dart';
import '../../../../data/database/database.dart';
import 'package:flutter/foundation.dart';

import '../../../../enums/processing/dialog_name_enum.dart';
import '../../../../enums/processing/process_state_enum.dart';

class VoucherScreenCubit extends Cubit<VoucherScreenState> {
  VoucherScreenCubit() : super(const VoucherScreenState());

  void toLoading() {
    emit(state.copyWith(processState: ProcessState.loading));
  }

  Future<void> initialize() async {
    try {
      // Use the Database class to update voucher lists
      await Database().updateVoucherLists();

      // Get the updated voucher lists from Database
      final userVouchers = Database().getUserVouchers();
      final ongoingVouchers = Database().getOngoingVouchers();
      final upcomingVouchers = Database().getUpcomingVouchers();

      // Update state with voucher lists from Database
      emit(state.copyWith(
        voucherList: userVouchers,
        ongoingList: ongoingVouchers,
        upcomingList: upcomingVouchers,
        processState: ProcessState.success,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing vouchers: $e');
      }
      emit(state.copyWith(
        processState: ProcessState.failure,
        dialogName: DialogName.failure,
        dialogMessage: e.toString(),
      ));
    }
  }
}
