import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_state.dart';
import 'package:gizmoglobe_client/services/sales_detail_pdf_service.dart';
import 'package:printing/printing.dart';

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

  Future<void> downloadInvoicePdf(
    BuildContext context,
    SalesInvoice invoice,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final products = <String, Product>{};
    for (final detail in invoice.details) {
      final productId = detail.product.productID;
      if (productId != null && productId.isNotEmpty) {
        products[productId] = detail.product;
      }
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = await SalesInvoicePdfService.generatePdf(
        invoice: invoice,
        products: products,
      );
      final bytes = await pdf.save();
      final fileName =
          'SalesInvoice_${invoice.salesInvoiceID ?? invoice.customerID}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Invoice PDF generated')),
      );
    } catch (error) {
      if (kDebugMode) {
        print('Unable to generate invoice PDF: $error');
      }
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Unable to generate invoice PDF: $error'),
        ),
      );
    } finally {
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}
