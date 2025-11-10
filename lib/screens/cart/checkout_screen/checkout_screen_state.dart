import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import '../../../enums/invoice_related/payment_method.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';

class CheckoutScreenState extends Equatable {
  final SalesInvoice? salesInvoice;
  final ProcessState processState;
  final DialogName dialogName;
  final String message;
  final PaymentMethod selectedPaymentMethod;

  const CheckoutScreenState({
    this.salesInvoice,
    this.processState = ProcessState.idle,
    this.dialogName = DialogName.empty,
    this.message = '',
    this.selectedPaymentMethod = PaymentMethod.cod,
  });

  CheckoutScreenState copyWith({
    SalesInvoice? salesInvoice,
    ProcessState? processState,
    DialogName? dialogName,
    String? message,
    PaymentMethod? selectedPaymentMethod,
  }) {
    return CheckoutScreenState(
      salesInvoice: salesInvoice ?? this.salesInvoice,
      processState: processState ?? this.processState,
      dialogName: dialogName ?? this.dialogName,
      message: message ?? this.message,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
    );
  }

  @override
  List<Object?> get props => [salesInvoice, processState, dialogName, message, selectedPaymentMethod];
}