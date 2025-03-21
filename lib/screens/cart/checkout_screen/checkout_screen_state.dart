import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import '../../../enums/processing/process_state_enum.dart';

class CheckoutScreenState extends Equatable {
  final SalesInvoice? salesInvoice;
  final ProcessState processState;
  final String? error;

  const CheckoutScreenState({
    this.salesInvoice,
    this.processState = ProcessState.idle,
    this.error,
  });

  CheckoutScreenState copyWith({
    SalesInvoice? salesInvoice,
    ProcessState? processState,
    String? error,
  }) {
    return CheckoutScreenState(
      salesInvoice: salesInvoice ?? this.salesInvoice,
      processState: processState ?? this.processState,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [salesInvoice, processState, error];
}
