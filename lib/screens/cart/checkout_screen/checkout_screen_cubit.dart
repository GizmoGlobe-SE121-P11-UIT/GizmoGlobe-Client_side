import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';
import '../../../data/firebase/firebase.dart';
import '../../../enums/invoice_related/sales_status.dart';
import '../../../objects/product_related/product.dart';
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
        sellingPrice: product.price,
        subtotal: product.price * quantity,
      );
    }).toList();

    SalesInvoice salesInvoice = SalesInvoice(
      customerID: FirebaseAuth.instance.currentUser!.uid,
      date: DateTime.now(),
      salesStatus: SalesStatus.pending,
      totalPrice: 0,
      details: details,
    );

    emit(state.copyWith(salesInvoice: salesInvoice ));
  }
}