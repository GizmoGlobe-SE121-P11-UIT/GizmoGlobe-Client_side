import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';
import '../../../data/firebase/firebase.dart';
import '../../../enums/invoice_related/payment_status.dart';
import '../../../enums/invoice_related/sales_status.dart';
import '../../../objects/address_related/address.dart';
import '../../../objects/product_related/product.dart';
import '../../../objects/voucher_related/percentage_interface.dart';
import '../../../objects/voucher_related/voucher.dart';
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
        if (kDebugMode) {
          print('Payment failed');
        }
        emit(state.copyWith(processState: ProcessState.failure, message: 'Payment failed'));
        return;
      }

      emit(state.copyWith(salesInvoice: state.salesInvoice!.copyWith(paymentStatus: PaymentStatus.paid)));
      await saveSalesInvoice();
      emit(state.copyWith(processState: ProcessState.success));
    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure, message: e.toString()));
    }
  }

  Future<void> saveSalesInvoice() async {
    try {
      await Firebase().addSalesInvoice(state.salesInvoice!);
      for (var detail in state.salesInvoice!.details) {
        await Firebase().removeFromCart(Database().userID, detail.product.productID ?? '');
      }

    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure, message: e.toString()));
    }
  }

  void updateAddress(Address address) {
    emit(state.copyWith(salesInvoice: state.salesInvoice!.copyWith(address: address)));
  }

  void updateVoucher(Voucher voucher) {
    if (state.salesInvoice == null) return;

    final updatedInvoice = state.salesInvoice!.copyWith(
      voucher: voucher,
      voucherDiscount: _calculateVoucherDiscount(voucher),
    );

    // Recalculate total price with voucher discount
    final totalAfterDiscount = updatedInvoice.getTotalBasedPrice() - updatedInvoice.voucherDiscount;
    final finalInvoice = updatedInvoice.copyWith(
      totalPrice: totalAfterDiscount > 0 ? totalAfterDiscount : 0,
    );

    emit(state.copyWith(salesInvoice: finalInvoice));
  }

  double _calculateVoucherDiscount(Voucher voucher) {
    final totalBeforeDiscount = state.salesInvoice!.getTotalBasedPrice();

    if (voucher.isPercentage) {
      final calculatedDiscount = totalBeforeDiscount * (voucher.discountValue / 100);
      final percentageVoucher = voucher as PercentageInterface;
      return calculatedDiscount > percentageVoucher.maximumDiscountValue
          ? percentageVoucher.maximumDiscountValue
          : calculatedDiscount;
    } else {
      return voucher.discountValue > totalBeforeDiscount ? totalBeforeDiscount : voucher.discountValue;
    }
  }
}