import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/enums/processing/notify_message_enum.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

import '../../../../objects/voucher_related/voucher.dart';


class VoucherDetailState extends Equatable {
  final Voucher voucher;
  final ProcessState processState;
  final DialogName dialogName;
  final NotifyMessage notifyMessage;

  const VoucherDetailState({
    required this.voucher,
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.notifyMessage = NotifyMessage.empty,
  });

  @override
  List<Object?> get props => [voucher, processState, dialogName, notifyMessage];

  VoucherDetailState copyWith({
    Voucher? voucher,
    ProcessState? processState,
    DialogName? dialogName,
    NotifyMessage? notifyMessage,
  }) {
    return VoucherDetailState(
      voucher: voucher ?? this.voucher,
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      notifyMessage: notifyMessage ?? this.notifyMessage,
    );
  }
}