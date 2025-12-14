import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import '../../../data/database/database.dart';
import '../../../enums/invoice_related/sales_status.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../objects/invoice_related/rating.dart';
import '../../../objects/invoice_related/sales_invoice.dart';

class OrderScreenCubit extends Cubit<OrderScreenState> {
  OrderScreenCubit() : super(const OrderScreenState());

  Future<void> initialize(OrderOption orderOption) async {
    List<SalesInvoice> toShipList = [];
    List<SalesInvoice> toReceiveList = [];
    List<SalesInvoice> completedList = [];
    List<SalesInvoice> cancelledList = [];

    if (Database().salesInvoiceList.isEmpty) {
      await Database().fetchSalesInvoice();
    }
    if (Database().addressList.isEmpty) {
      await Database().fetchAddress();
    }

    for (var salesInvoice in Database().salesInvoiceList) {
      switch (salesInvoice.salesStatus) {
        case SalesStatus.pending:
        case SalesStatus.preparing:
          toShipList.add(salesInvoice);
          break;
        case SalesStatus.shipping:
        case SalesStatus.shipped:
          toReceiveList.add(salesInvoice);
          break;
        case SalesStatus.received:
        case SalesStatus.completed:
          completedList.add(salesInvoice);
          break;
        case SalesStatus.cancelled:
          cancelledList.add(salesInvoice);
          break;
      }
    }

    int compareInvoiceDateDesc(SalesInvoice a, SalesInvoice b) =>
        b.date.compareTo(a.date);

    emit(state.copyWith(
      orderOption: orderOption,
      toShipList: [...toShipList]..sort(compareInvoiceDateDesc),
      toReceiveList: [...toReceiveList]..sort(compareInvoiceDateDesc),
      completedList: [...completedList]..sort(compareInvoiceDateDesc),
      cancelledList: [...cancelledList]..sort(compareInvoiceDateDesc),
    ));
  }

  void resetProcessState() {
    if (state.processState != ProcessState.idle) {
      emit(state.copyWith(processState: ProcessState.idle));
    }
  }

  Future<void> confirmDelivery(SalesInvoice salesInvoice) async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
      SalesInvoice updatedInvoice = salesInvoice.copyWith(
        salesStatus: SalesStatus.received,
      );
      await Firebase().confirmDelivery(updatedInvoice);
      emit(state.copyWith(processState: ProcessState.success));
    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure));
      return;
    }
  }

  Future<void> completeInvoiceIfAllProductsRated(
      SalesInvoice invoice,
      List<Rating> currentUserRatings,
      ) async {
    final invoiceId = invoice.salesInvoiceID ?? '';
    if (invoiceId.isEmpty) return;

    try {
      final invoiceProductIds = <String>{
        for (final detail in (invoice.details))
          detail.product.productID!
      }..removeWhere((id) => id.isEmpty);

      if (invoiceProductIds.isEmpty) return;

      String uid = Database().userID.isEmpty
          ? (await Database().getCurrentUserID() ?? '')
          : Database().userID;
      if (uid.isEmpty) return;

      final ratingSnapshot = await Firebase().firestore
          .collection('order_ratings')
          .where('userID', isEqualTo: uid)
          .get();

      final ratedProductIds = ratingSnapshot.docs
          .map((d) {
        final data = d.data();
        return (data['productID'] as String?) ?? '';
      })
          .where((id) => id.isNotEmpty)
          .toSet();

      if (invoiceProductIds.isNotEmpty &&
          invoiceProductIds.difference(ratedProductIds).isEmpty) {
        await Firebase().firestore
            .collection('sales_invoices')
            .doc(invoiceId)
            .update({'salesStatus': SalesStatus.completed.getName()});

        await Database().fetchSalesInvoice();
        await initialize(OrderOption.completed);
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('Error completing invoice after rating: $e\n$st');
      }
    }
  }
}
