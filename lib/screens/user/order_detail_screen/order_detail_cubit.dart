import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_state.dart';
import 'package:gizmoglobe_client/services/sales_detail_pdf_service.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_cubit.dart';
import 'package:printing/printing.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final Firebase _firebase = Firebase();

  OrderDetailCubit() : super(const OrderDetailState());

  Future<void> _closeDetailModal(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      await navigator.maybePop();
      // Give the modal a brief moment to fully dismiss before showing feedback
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

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

  Future<void> cancelInvoice(BuildContext context) async {
    final invoice = state.salesInvoice;
    if (invoice == null || (invoice.salesInvoiceID ?? '').isEmpty) return;

    if (!context.mounted) return;

    final canCancel = invoice.salesStatus == SalesStatus.pending ||
        invoice.salesStatus == SalesStatus.preparing;
    if (!canCancel) {
      await _closeDetailModal(context);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => InformationDialog(
          dialogName: DialogName.failure,
          title: S.of(context).cannotCancelTitle,
          content: S.of(context).cannotCancelMessage,
        ),
      );
      return;
    }

    try {
      await _firebase.cancelSalesInvoice(invoice.salesInvoiceID!);
      final updatedInvoice =
          invoice.copyWith(salesStatus: SalesStatus.cancelled);
      await Database().fetchSalesInvoice();

      // Update local state immediately
      emit(state.copyWith(
        salesInvoice: updatedInvoice,
        processState: ProcessState.success,
      ));

      // Refresh order lists if cubit is available upstream
      OrderScreenCubit? orderCubit;
      try {
        orderCubit = BlocProvider.of<OrderScreenCubit>(context, listen: false);
      } catch (_) {}

      // Await the initialize to ensure state is refreshed before closing modal
      if (orderCubit != null) {
        await orderCubit.initialize(orderCubit.state.orderOption);
      }

      // Close detail modal before showing snackbar
      await _closeDetailModal(context);
      if (!context.mounted) return;
      SnackbarService.showSuccess(
        context,
        title: S.of(context).cancelSuccessTitle,
        message: S.of(context).cancelSuccessMessage,
      );
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        errorMessage: e.toString(),
      ));
      // Close detail modal before showing dialog
      await _closeDetailModal(context);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => InformationDialog(
          dialogName: DialogName.failure,
          title: S.of(context).cancelFailedTitle,
          content: S.of(context).cancelFailedMessage(e.toString()),
        ),
      );
    }
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
      // Unable to generate invoice PDF
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
