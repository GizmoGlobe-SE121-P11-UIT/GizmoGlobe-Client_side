import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/product_factory.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import '../../../data/database/database.dart';
import '../../../enums/invoice_related/sales_status.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/processing/sort_enum.dart';
import '../../../enums/product_related/cpu_enums/cpu_family.dart';
import '../../../enums/product_related/drive_enums/drive_capacity.dart';
import '../../../enums/product_related/drive_enums/drive_type.dart';
import '../../../enums/product_related/gpu_enums/gpu_bus.dart';
import '../../../enums/product_related/gpu_enums/gpu_capacity.dart';
import '../../../enums/product_related/gpu_enums/gpu_series.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_compatibility.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_form_factor.dart';
import '../../../enums/product_related/mainboard_enums/mainboard_series.dart';
import '../../../enums/product_related/product_status_enum.dart';
// Import các enum cần thiết cho từng loại sản phẩm
import '../../../enums/product_related/psu_enums/psu_efficiency.dart';
import '../../../enums/product_related/psu_enums/psu_modular.dart';
import '../../../enums/product_related/ram_enums/ram_bus.dart';
import '../../../enums/product_related/ram_enums/ram_capacity_enum.dart';
import '../../../enums/product_related/ram_enums/ram_type.dart';
import '../../../objects/invoice_related/sales_invoice.dart';
// ... thêm các import khác

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