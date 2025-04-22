import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';

class OrderScreenState extends Equatable {
  final OrderOption orderOption;
  final List<SalesInvoice> toShipList;
  final List<SalesInvoice> toReceiveList;
  final List<SalesInvoice> completedList;
  final ProcessState processState;

  const OrderScreenState({
    this.orderOption = OrderOption.toShip,
    this.toShipList = const [],
    this.toReceiveList = const [],
    this.completedList = const [],
    this.processState = ProcessState.idle,
  });

  @override
  List<Object?> get props => [
    orderOption,
    toShipList,
    toReceiveList,
    completedList,
    processState,
  ];

  OrderScreenState copyWith({
    OrderOption? orderOption,
    List<SalesInvoice>? toShipList,
    List<SalesInvoice>? toReceiveList,
    List<SalesInvoice>? completedList,
    ProcessState? processState,
  }) {
    return OrderScreenState(
      orderOption: orderOption ?? this.orderOption,
      toShipList: toShipList ?? this.toShipList,
      toReceiveList: toReceiveList ?? this.toReceiveList,
      completedList: completedList ?? this.completedList,
      processState: processState ?? this.processState,
    );
  }
}