import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';
import '../../../data/firebase/firebase.dart';
import '../../../enums/invoice_related/payment_status.dart';
import '../../../enums/invoice_related/sales_status.dart';
import '../../../objects/address_related/address.dart';
import '../../../objects/product_related/product.dart';
import '../../../services/stripe_services.dart';
import 'checkout_screen_state.dart';
import '../../../enums/processing/process_state_enum.dart';

class CheckoutScreenCubit extends Cubit<CheckoutScreenState> {
  CheckoutScreenCubit() : super(const CheckoutScreenState());

  void initialize(List<Map<Product, int>> cartItems) {
    List<SalesInvoiceDetail> details = cartItems.map((item) {
      final product = item.keys.first;
      final quantity = item.values.first;
      return SalesInvoiceDetail(
        product: product,
        quantity: quantity,
        sellingPrice: product.price * (1 - product.discount),
        subtotal: product.price * quantity * (1 - product.discount),
        salesInvoiceID: '',
      );
    }).toList();

    SalesInvoice salesInvoice = SalesInvoice(
      customerID: Database().userID,
      date: DateTime.now(),
      salesStatus: SalesStatus.pending,
      address: Address.nullAddress,
      paymentStatus: PaymentStatus.unpaid,
      totalPrice: details.fold(0, (previousValue, element) => previousValue + element.subtotal),
      details: details,
    );

    emit(state.copyWith(salesInvoice: salesInvoice ));
  }

  Future<void> checkout() async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
      String? result;
      result = await StripeServices.instance.makePayment(state.salesInvoice!.totalPrice);

      if (result == null) {
        emit(state.copyWith(processState: ProcessState.failure, error: 'Payment failed'));
        return;
      }

      emit(state.copyWith(salesInvoice: state.salesInvoice!.copyWith(paymentStatus: PaymentStatus.paid)));
      await saveSalesInvoice();
      emit(state.copyWith(processState: ProcessState.success));
    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure, error: e.toString()));
    }
  }

  Future<void> saveSalesInvoice() async {
    try {
      await Firebase().addSalesInvoice(state.salesInvoice!);
      for (var detail in state.salesInvoice!.details) {
        await Firebase().removeFromCart(Database().userID, detail.product.productID ?? '');
      }

    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure, error: e.toString()));
    }
  }

  void updateAddress(Address address) {
    emit(state.copyWith(salesInvoice: state.salesInvoice!.copyWith(address: address)));
  }
}