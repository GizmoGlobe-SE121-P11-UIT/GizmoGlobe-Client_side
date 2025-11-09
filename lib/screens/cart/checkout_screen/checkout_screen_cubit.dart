import 'dart:convert';
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
import 'package:gizmoglobe_client/services/stripe_web_helper_stub.dart'
    if (dart.library.html) 'package:gizmoglobe_client/services/stripe_web_helper_web.dart';
import 'checkout_screen_state.dart';
import '../../../enums/processing/process_state_enum.dart';

class CheckoutScreenCubit extends Cubit<CheckoutScreenState> {
  final Firebase _firebase = Firebase();

  CheckoutScreenCubit() : super(const CheckoutScreenState());

  /// Create a new sales invoice from cart items and save it to Firebase
  /// Returns the created invoice ID
  Future<String> createInvoiceFromCartItems(
      List<Map<Product, int>> cartItems) async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
      List<SalesInvoiceDetail> details = cartItems.map((item) {
        final product = item.keys.first;
        final quantity = item.values.first;
        // Use the already-calculated discountedPrice from the product
        // discountedPrice is already in the correct unit (price after discount)
        final sellingPrice = product.discountedPrice;
        final subtotal = sellingPrice * quantity;

        return SalesInvoiceDetail(
          product: product,
          quantity: quantity,
          sellingPrice: sellingPrice,
          subtotal: subtotal,
          salesInvoiceID: '',
        );
      }).toList();

      SalesInvoice salesInvoice = SalesInvoice(
        customerID: Database().userID,
        date: DateTime.now(),
        salesStatus: SalesStatus.pending,
        address: Address.nullAddress,
        paymentStatus: PaymentStatus.unpaid,
        totalPrice: details.fold(
            0.0, (previousValue, element) => previousValue + element.subtotal),
        details: details,
      );

      // Save invoice to Firebase to get the ID
      await _firebase.addSalesInvoice(salesInvoice);

      // Get the created invoice with ID
      if (salesInvoice.salesInvoiceID == null ||
          salesInvoice.salesInvoiceID!.isEmpty) {
        throw Exception('Failed to create invoice: No ID returned');
      }

      emit(state.copyWith(
        salesInvoice: salesInvoice,
        processState: ProcessState.idle,
      ));

      return salesInvoice.salesInvoiceID!;
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: e.toString(),
      ));
      rethrow;
    }
  }

  /// Initialize from cart items (legacy method, kept for backward compatibility)
  /// This creates the invoice in memory only, use createInvoiceFromCartItems for new flow
  void initialize(List<Map<Product, int>> cartItems) {
    List<SalesInvoiceDetail> details = cartItems.map((item) {
      final product = item.keys.first;
      final quantity = item.values.first;
      // Use the already-calculated discountedPrice from the product
      // discountedPrice is already in the correct unit (price after discount)
      final sellingPrice = product.discountedPrice;
      final subtotal = sellingPrice * quantity;

      return SalesInvoiceDetail(
        product: product,
        quantity: quantity,
        sellingPrice: sellingPrice,
        subtotal: subtotal,
        salesInvoiceID: '',
      );
    }).toList();

    SalesInvoice salesInvoice = SalesInvoice(
      customerID: Database().userID,
      date: DateTime.now(),
      salesStatus: SalesStatus.pending,
      address: Address.nullAddress,
      paymentStatus: PaymentStatus.unpaid,
      totalPrice: details.fold(
          0.0, (previousValue, element) => previousValue + element.subtotal),
      details: details,
    );

    emit(state.copyWith(salesInvoice: salesInvoice));
  }

  /// Initialize from an existing sales invoice ID
  Future<void> initializeFromInvoiceId(String salesInvoiceID) async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
      final salesInvoice = await _firebase.getSalesInvoiceById(salesInvoiceID);
      if (salesInvoice == null) {
        emit(state.copyWith(
          processState: ProcessState.failure,
          message: 'Invoice not found',
        ));
        return;
      }

      emit(state.copyWith(
        salesInvoice: salesInvoice,
        processState: ProcessState.idle,
      ));
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: e.toString(),
      ));
    }
  }

  /// Cancel the current invoice (mark as cancelled)
  Future<void> cancelInvoice() async {
    if (state.salesInvoice?.salesInvoiceID == null ||
        state.salesInvoice!.salesInvoiceID!.isEmpty) {
      return; // No invoice to cancel
    }

    try {
      await _firebase.cancelSalesInvoice(state.salesInvoice!.salesInvoiceID!);
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling invoice: $e');
      }
      // Don't throw - cancellation cleanup should not block UI
    }
  }

  /// Cancel an invoice by ID (used when invoice is not in current state)
  Future<void> cancelInvoiceFromId(String salesInvoiceID) async {
    try {
      await _firebase.cancelSalesInvoice(salesInvoiceID);
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling invoice by ID: $e');
      }
      // Don't throw - cancellation cleanup should not block UI
    }
  }

  Future<void> checkout() async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
      // Update the invoice with current state (address, voucher, etc.) before payment
      if (state.salesInvoice?.salesInvoiceID != null &&
          state.salesInvoice!.salesInvoiceID!.isNotEmpty) {
        // Invoice already exists, update it
        await _firebase.updateSalesInvoice(state.salesInvoice!);
      } else {
        // Legacy flow: invoice doesn't exist yet, create it
        if (state.salesInvoice == null) {
          throw Exception('No invoice to checkout');
        }
        await saveSalesInvoice();
      }

      // On web, store invoice data before redirect for post-payment completion
      if (kIsWeb && state.salesInvoice != null) {
        await _storeCheckoutDataForWeb();
      }

      String? result;
      try {
        result = await StripeServices.instance
            .makePayment(state.salesInvoice!.totalPrice);
      } catch (paymentError) {
        // Payment initiation failed - cancel the invoice
        if (state.salesInvoice?.salesInvoiceID != null &&
            state.salesInvoice!.salesInvoiceID!.isNotEmpty) {
          await cancelInvoice();
        }
        emit(state.copyWith(
            processState: ProcessState.failure,
            message: 'Payment failed: ${paymentError.toString()}'));
        return;
      }

      // On web, makePayment returns null because it redirects to Stripe Checkout
      // The payment will be completed after redirect, so we don't emit success here
      if (kIsWeb && result == null) {
        // Payment redirect initiated, will be handled by checkout success page
        // Don't emit failure - the redirect is in progress
        return;
      }

      if (result == null) {
        if (kDebugMode) {
          print('Payment failed');
        }
        // Payment failed - cancel the invoice
        if (state.salesInvoice?.salesInvoiceID != null &&
            state.salesInvoice!.salesInvoiceID!.isNotEmpty) {
          await cancelInvoice();
        }
        emit(state.copyWith(
            processState: ProcessState.failure, message: 'Payment failed'));
        return;
      }

      // Update invoice payment status to paid
      final updatedInvoice = state.salesInvoice!.copyWith(
        paymentStatus: PaymentStatus.paid,
      );
      emit(state.copyWith(salesInvoice: updatedInvoice));

      if (updatedInvoice.salesInvoiceID != null &&
          updatedInvoice.salesInvoiceID!.isNotEmpty) {
        await _firebase.updateSalesInvoice(updatedInvoice);
      } else {
        await saveSalesInvoice();
      }

      // Clear cart items after successful payment
      for (var detail in state.salesInvoice!.details) {
        await _firebase.removeFromCart(
            Database().userID, detail.product.productID ?? '');
      }

      emit(state.copyWith(processState: ProcessState.success));
    } catch (e) {
      // Any error during checkout - cancel the invoice
      if (state.salesInvoice?.salesInvoiceID != null &&
          state.salesInvoice!.salesInvoiceID!.isNotEmpty) {
        await cancelInvoice();
      }
      emit(state.copyWith(
          processState: ProcessState.failure, message: e.toString()));
    }
  }

  /// Store checkout data in sessionStorage for web (before redirect)
  Future<void> _storeCheckoutDataForWeb() async {
    if (!kIsWeb || state.salesInvoice == null) return;

    try {
      // Store invoice summary - convert DateTime to ISO string for JSON encoding
      final invoiceMap = state.salesInvoice!.toMap();
      // Convert DateTime to ISO string for JSON encoding
      final invoiceMapEncodable = Map<String, dynamic>.from(invoiceMap);
      if (invoiceMapEncodable['date'] is DateTime) {
        invoiceMapEncodable['date'] =
            (invoiceMapEncodable['date'] as DateTime).toIso8601String();
      }

      // Store invoice details (product IDs and quantities)
      final detailsData = state.salesInvoice!.details
          .map((detail) => {
                'productID': detail.product.productID,
                'quantity': detail.quantity,
                'sellingPrice': detail.sellingPrice,
                'subtotal': detail.subtotal,
              })
          .toList();

      final checkoutData = {
        'invoice': invoiceMapEncodable,
        'details': detailsData,
        'salesInvoiceID': state
            .salesInvoice!.salesInvoiceID, // Store invoice ID for completion
      };

      final checkoutDataJson = jsonEncode(checkoutData);
      StripeWebHelper.setSessionStorage(
          'stripe_checkout_data', checkoutDataJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error storing checkout data: $e');
      }
    }
  }

  /// Complete checkout after successful payment (called from checkout success page)
  /// This method updates the existing invoice with paid status
  Future<void> completeCheckoutFromStoredData(String paymentIntentId) async {
    if (!kIsWeb) return;

    try {
      // Retrieve stored checkout data
      final checkoutDataJson =
          StripeWebHelper.getSessionStorage('stripe_checkout_data');
      if (checkoutDataJson == null) {
        throw Exception('Checkout data not found');
      }

      final checkoutData = jsonDecode(checkoutDataJson) as Map<String, dynamic>;
      final salesInvoiceID = checkoutData['salesInvoiceID'] as String?;

      if (salesInvoiceID == null || salesInvoiceID.isEmpty) {
        throw Exception('Invoice ID not found in checkout data');
      }

      // Load the existing invoice from Firebase
      final salesInvoice = await _firebase.getSalesInvoiceById(salesInvoiceID);
      if (salesInvoice == null) {
        throw Exception('Invoice not found: $salesInvoiceID');
      }

      // Update invoice with paid status
      final updatedInvoice = salesInvoice.copyWith(
        paymentStatus: PaymentStatus.paid,
      );

      // Update invoice in Firebase
      await _firebase.updateSalesInvoice(updatedInvoice);

      // Clear cart items
      for (var detail in updatedInvoice.details) {
        await _firebase.removeFromCart(
            Database().userID, detail.product.productID ?? '');
      }

      // Clear stored checkout data
      StripeWebHelper.removeSessionStorage('stripe_checkout_data');
    } catch (e) {
      if (kDebugMode) {
        print('Error completing checkout from stored data: $e');
      }
      rethrow;
    }
  }

  Future<void> saveSalesInvoice() async {
    try {
      await Firebase().addSalesInvoice(state.salesInvoice!);
      for (var detail in state.salesInvoice!.details) {
        await Firebase()
            .removeFromCart(Database().userID, detail.product.productID ?? '');
      }
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, message: e.toString()));
    }
  }

  Future<void> updateAddress(Address address) async {
    if (state.salesInvoice == null) return;

    final updatedInvoice = state.salesInvoice!.copyWith(address: address);
    emit(state.copyWith(salesInvoice: updatedInvoice));

    // Update invoice in Firebase if it already exists
    if (updatedInvoice.salesInvoiceID != null &&
        updatedInvoice.salesInvoiceID!.isNotEmpty) {
      try {
        await _firebase.updateSalesInvoice(updatedInvoice);
      } catch (e) {
        if (kDebugMode) {
          print('Error updating address in invoice: $e');
        }
        // Don't emit error - user can still continue
      }
    }
  }

  Future<void> updateVoucher(Voucher voucher) async {
    if (state.salesInvoice == null) return;

    final updatedInvoice = state.salesInvoice!.copyWith(
      voucher: voucher,
      voucherDiscount: _calculateVoucherDiscount(voucher),
    );

    // Recalculate total price with voucher discount
    final totalAfterDiscount =
        updatedInvoice.getTotalBasedPrice() - updatedInvoice.voucherDiscount;
    final finalInvoice = updatedInvoice.copyWith(
      totalPrice: totalAfterDiscount > 0 ? totalAfterDiscount : 0,
    );

    emit(state.copyWith(salesInvoice: finalInvoice));

    // Update invoice in Firebase if it already exists
    if (finalInvoice.salesInvoiceID != null &&
        finalInvoice.salesInvoiceID!.isNotEmpty) {
      try {
        await _firebase.updateSalesInvoice(finalInvoice);
      } catch (e) {
        if (kDebugMode) {
          print('Error updating voucher in invoice: $e');
        }
        // Don't emit error - user can still continue
      }
    }
  }

  double _calculateVoucherDiscount(Voucher voucher) {
    final totalBeforeDiscount = state.salesInvoice!.getTotalBasedPrice();

    if (voucher.isPercentage) {
      final calculatedDiscount =
          totalBeforeDiscount * (voucher.discountValue / 100);
      final percentageVoucher = voucher as PercentageInterface;
      return calculatedDiscount >
              percentageVoucher.maximumDiscountValue.toDouble()
          ? percentageVoucher.maximumDiscountValue.toDouble()
          : calculatedDiscount;
    } else {
      return voucher.discountValue > totalBeforeDiscount
          ? totalBeforeDiscount
          : voucher.discountValue;
    }
  }
}
