import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_state.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit() : super(const OrderDetailState());

  void loadOrderDetail(SalesInvoice invoice) {
    emit(state.copyWith(
        processState: ProcessState.loading, clearErrorMessage: true));
    try {
      final hydratedInvoice = _hydrateInvoice(invoice);
      emit(state.copyWith(
        salesInvoice: hydratedInvoice,
        processState: ProcessState.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  SalesInvoice _hydrateInvoice(SalesInvoice invoice) {
    if (invoice.details.isNotEmpty) {
      return invoice;
    }
    final fallback = Database()
        .salesInvoiceList
        .where(
          (element) => element.salesInvoiceID == invoice.salesInvoiceID,
        )
        .toList();
    if (fallback.isNotEmpty) {
      return fallback.first;
    }
    return invoice;
  }

  void reset() {
    emit(const OrderDetailState());
  }
}
