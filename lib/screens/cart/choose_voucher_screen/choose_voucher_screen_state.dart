// lib/screens/cart/choose_voucher_screen/choose_voucher_screen_state.dart
import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import '../../../objects/voucher_related/voucher.dart';

class ChooseVoucherScreenState with EquatableMixin {
  final List<Voucher> availableVouchers;
  final ProcessState processState;
  final String? errorMessage;

  const ChooseVoucherScreenState({
    this.availableVouchers = const [],
    this.processState = ProcessState.idle,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [availableVouchers, processState, errorMessage];

  ChooseVoucherScreenState copyWith({
    List<Voucher>? availableVouchers,
    ProcessState? processState,
    String? errorMessage,
  }) {
    return ChooseVoucherScreenState(
      availableVouchers: availableVouchers ?? this.availableVouchers,
      processState: processState ?? this.processState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}