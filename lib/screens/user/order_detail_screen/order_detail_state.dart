import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';

class OrderDetailState extends Equatable {
  final SalesInvoice? salesInvoice;
  final ProcessState processState;
  final String? errorMessage;

  const OrderDetailState({
    this.salesInvoice,
    this.processState = ProcessState.idle,
    this.errorMessage,
  });

  OrderDetailState copyWith({
    SalesInvoice? salesInvoice,
    bool removeInvoice = false,
    ProcessState? processState,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return OrderDetailState(
      salesInvoice: removeInvoice ? null : (salesInvoice ?? this.salesInvoice),
      processState: processState ?? this.processState,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        salesInvoice,
        processState,
        errorMessage,
      ];
}
