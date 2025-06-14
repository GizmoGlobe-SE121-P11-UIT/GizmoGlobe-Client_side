import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/voucher_related/voucher_status.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_state.dart';
import '../../../../data/firebase/firebase.dart';
import 'package:flutter/foundation.dart';

class VoucherScreenCubit extends Cubit<VoucherScreenState> {
  VoucherScreenCubit() : super(const VoucherScreenState());

  Future<void> initialize() async {
    try {
      List<Voucher> voucherList = await Firebase().getVouchers();
      voucherList.sort((a, b) => a.startTime.compareTo(b.startTime));

      List<Voucher> upcomingList = [];
      List<Voucher> ongoingList = [];

      for (var voucher in voucherList) {
        VoucherTimeStatus voucherTimeStatus = voucher.voucherTimeStatus;

        if (voucherTimeStatus == VoucherTimeStatus.upcoming) {
          upcomingList.add(voucher);
        } else if (voucherTimeStatus == VoucherTimeStatus.ongoing) {
          ongoingList.add(voucher);
        }
      }

      emit(state.copyWith(
        voucherList: voucherList,
        ongoingList: ongoingList,
        upcomingList: upcomingList,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing voucher screen: $e');
      }
      rethrow;
    }
  }
}
