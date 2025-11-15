import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/services/sepay_services.dart';
import '../../../enums/processing/process_state_enum.dart';

const _noChange = Object();

class SePayPaymentScreenState extends Equatable {
  final SePayVirtualAccount? virtualAccount;
  final ProcessState processState;
  final String message;
  final bool isPolling;
  final SePayTransaction? transaction;
  final bool isRestoringCart;
  final String? dismissError;

  const SePayPaymentScreenState({
    this.virtualAccount,
    this.processState = ProcessState.idle,
    this.message = '',
    this.isPolling = false,
    this.transaction,
    this.isRestoringCart = false,
    this.dismissError,
  });

  SePayPaymentScreenState copyWith({
    SePayVirtualAccount? virtualAccount,
    ProcessState? processState,
    String? message,
    bool? isPolling,
    SePayTransaction? transaction,
    bool? isRestoringCart,
    Object? dismissError = _noChange,
  }) {
    return SePayPaymentScreenState(
      virtualAccount: virtualAccount ?? this.virtualAccount,
      processState: processState ?? this.processState,
      message: message ?? this.message,
      isPolling: isPolling ?? this.isPolling,
      transaction: transaction ?? this.transaction,
      isRestoringCart: isRestoringCart ?? this.isRestoringCart,
      dismissError: identical(dismissError, _noChange)
          ? this.dismissError
          : dismissError as String?,
    );
  }

  @override
  List<Object?> get props => [
        virtualAccount,
        processState,
        message,
        isPolling,
        transaction,
        isRestoringCart,
        dismissError,
      ];
}

