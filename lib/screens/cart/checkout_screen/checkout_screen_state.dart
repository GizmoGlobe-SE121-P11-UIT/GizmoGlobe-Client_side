import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';

class CheckoutScreenState extends Equatable {
  final SalesInvoice? salesInvoice;
  final ProcessState processState;
  final DialogName dialogName;
  final String message;


  const CheckoutScreenState({
    this.salesInvoice,
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.message = '',
  });

  CheckoutScreenState copyWith({
    SalesInvoice? salesInvoice,
    ProcessState? processState,
    DialogName? dialogName,
    String? message,
  }) {
    return CheckoutScreenState(
      salesInvoice: salesInvoice ?? this.salesInvoice,
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [salesInvoice, processState, dialogName, message];
}