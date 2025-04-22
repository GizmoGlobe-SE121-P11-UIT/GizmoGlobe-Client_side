import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import '../../../data/database/database.dart';
import '../../../enums/invoice_related/sales_status.dart';
import '../../../enums/processing/process_state_enum.dart';
// Import các enum cần thiết cho từng loại sản phẩm
import '../../../objects/invoice_related/sales_invoice.dart';

class OrderScreenCubit extends Cubit<OrderScreenState> {
  OrderScreenCubit() : super(const OrderScreenState());

  void initialize(OrderOption orderOption) {
    List<SalesInvoice> toShipList = [];
    List<SalesInvoice> toReceiveList = [];
    List<SalesInvoice> completedList = [];

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
        case SalesStatus.completed:
          completedList.add(salesInvoice);
          break;
        default:
          break;
      }
    }

    emit(state.copyWith(
      orderOption: orderOption,
      toShipList: toShipList,
      toReceiveList: toReceiveList,
      completedList: completedList,
    ));
  }

  Future<void> confirmDelivery(SalesInvoice salesInvoice) async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
    SalesInvoice updatedInvoice = salesInvoice.copyWith(
      salesStatus: SalesStatus.completed,
    );
    await Firebase().confirmDelivery(updatedInvoice);
    emit(state.copyWith(processState: ProcessState.success));
    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure));
      return;
    }
  }
}