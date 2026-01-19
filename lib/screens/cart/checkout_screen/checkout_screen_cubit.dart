import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';
import '../../../data/firebase/firebase.dart';
import '../../../enums/invoice_related/payment_method.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CheckoutScreenCubit() : super(const CheckoutScreenState());

  Future<String> _getCustomerName() async {
    try {
      final userID = Database().userID;
      if (userID.isEmpty) {
        return '';
      }

      final customerDoc =
          await _firestore.collection('customers').doc(userID).get();

      if (customerDoc.exists) {
        final data = customerDoc.data() as Map<String, dynamic>;
        return data['customerName'] as String? ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  void updatePaymentMethod(PaymentMethod paymentMethod) {
    // Reset failure state when changing payment method to prevent error dialog from reappearing
    if (state.processState == ProcessState.failure) {
      emit(state.copyWith(
        selectedPaymentMethod: paymentMethod,
        processState: ProcessState.idle,
        message: '',
      ));
    } else {
      emit(state.copyWith(selectedPaymentMethod: paymentMethod));
    }
  }

  /// Clear error state - call this after showing error dialog
  void clearError() {
    if (state.processState == ProcessState.failure) {
      emit(state.copyWith(
        processState: ProcessState.idle,
        message: '',
      ));
    }
  }

  Future<String> createInvoiceFromCartItems(
      List<Map<Product, int>> cartItems) async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
      final customerName = await _getCustomerName();

      List<SalesInvoiceDetail> details = cartItems.map((item) {
        final product = item.keys.first;
        final quantity = item.values.first;
        // Use the already-calculated discountedPrice from the product
        // discountedPrice is already in the correct unit (price after discount)
        // Don't round here - store exact values for accurate calculations
        int sellingPrice = product.discountedPrice;
        final subtotal = sellingPrice * quantity;

        return SalesInvoiceDetail(
          product: product,
          quantity: quantity,
          sellingPrice: sellingPrice,
          subtotal: subtotal,
          salesInvoiceID: '',
        );
      }).toList();

      // Calculate total without rounding - will be rounded once at checkout
      final totalPrice = details.fold(
          0, (previousValue, element) => previousValue + element.subtotal);

      SalesInvoice salesInvoice = SalesInvoice(
        customerID: Database().userID,
        customerName: customerName,
        date: DateTime.now(),
        salesStatus: SalesStatus.pending,
        address: Address.nullAddress,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: state.selectedPaymentMethod,
        totalPrice: totalPrice,
        details: details,
      );

      // Save invoice to Firebase to get ID (for page refresh recovery)
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
  /// This creates the invoice in memory only
  Future<void> initialize(List<Map<Product, int>> cartItems) async {
    final customerName = await _getCustomerName();

    List<SalesInvoiceDetail> details = cartItems.map((item) {
      final product = item.keys.first;
      final quantity = item.values.first;
      // Use the already-calculated discountedPrice from the product
      // discountedPrice is already in the correct unit (price after discount)
      // Don't round here - store exact values for accurate calculations
      int sellingPrice = product.discountedPrice;
      final subtotal = sellingPrice * quantity;

      return SalesInvoiceDetail(
        product: product,
        quantity: quantity,
        sellingPrice: sellingPrice,
        subtotal: subtotal,
        salesInvoiceID: '',
      );
    }).toList();

    // Calculate total without rounding - will be rounded once at checkout
    final totalPrice = details.fold(
        0, (previousValue, element) => previousValue + element.subtotal);

    SalesInvoice salesInvoice = SalesInvoice(
      customerID: Database().userID,
      customerName: customerName,
      date: DateTime.now(),
      salesStatus: SalesStatus.pending,
      address: Address.nullAddress,
      paymentStatus: PaymentStatus.unpaid,
      paymentMethod: state.selectedPaymentMethod,
      totalPrice: totalPrice,
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
      // Don't throw - cancellation cleanup should not block UI
    }
  }

  /// Cancel an invoice by ID (used when invoice is not in current state)
  Future<void> cancelInvoiceFromId(String salesInvoiceID) async {
    try {
      await _firebase.cancelSalesInvoice(salesInvoiceID);
    } catch (e) {
      // Don't throw - cancellation cleanup should not block UI
    }
  }

  Future<void> checkout() async {
    emit(state.copyWith(processState: ProcessState.loading));
    try {
      if (state.salesInvoice == null) {
        throw Exception('No invoice to checkout');
      }

      final currentAddress = state.salesInvoice!.address;

      // Get customer name if needed
      String? customerName = state.salesInvoice!.customerName;
      if (customerName == null || customerName.isEmpty) {
        customerName = await _getCustomerName();
      }

      // Create invoice with all fields explicitly set to avoid any state timing issues
      SalesInvoice invoiceToProcess = state.salesInvoice!.copyWith(
        customerName: customerName,
        address: currentAddress,
      );

      // Calculate final total: sum all items, apply voucher discount, then round once
      final totalBeforeVoucher = invoiceToProcess.getTotalBasedPrice();
      final voucherDiscount = invoiceToProcess.voucherDiscount;
      final totalAfterDiscount = totalBeforeVoucher - voucherDiscount;
      final finalTotal = totalAfterDiscount > 0.0 ? totalAfterDiscount : 0.0;

      // If total is 0, force COD payment method
      PaymentMethod paymentMethod = state.selectedPaymentMethod;
      if (finalTotal == 0 &&
          (paymentMethod == PaymentMethod.sepay ||
              paymentMethod == PaymentMethod.stripe)) {
        paymentMethod = PaymentMethod.cod;
      }

      // Update invoice with correct payment method
      invoiceToProcess = invoiceToProcess.copyWith(
        paymentMethod: paymentMethod,
      );

      // Round only once at the end - round to 3 decimal places
      final roundedTotalPrice = (finalTotal).round();

      // Update invoice with rounded total price and current state
      final invoiceWithRoundedTotal = invoiceToProcess.copyWith(
        totalPrice: roundedTotalPrice,
      );

      // Create invoice in Firebase only when user places the order
      // Invoice was only in memory until now
      if (invoiceWithRoundedTotal.salesInvoiceID == null ||
          invoiceWithRoundedTotal.salesInvoiceID!.isEmpty) {
        // Create invoice in Firebase
        await _firebase.addSalesInvoice(invoiceWithRoundedTotal);
        if (invoiceWithRoundedTotal.salesInvoiceID == null ||
            invoiceWithRoundedTotal.salesInvoiceID!.isEmpty) {
          throw Exception('Failed to create invoice: No ID returned');
        }
        // Update state with invoice that now has ID
        emit(state.copyWith(salesInvoice: invoiceWithRoundedTotal));
      } else {
        // Invoice already exists in Firebase (e.g., from page refresh recovery), update it
        await _firebase.updateSalesInvoice(invoiceWithRoundedTotal);
        // Update state with the updated invoice
        emit(state.copyWith(salesInvoice: invoiceWithRoundedTotal));
      }

      // Reserve stock atomically for this invoice (prevents overselling under concurrency).
      await _firebase.reserveProductStockForInvoice(
        invoiceWithRoundedTotal.salesInvoiceID!,
        invoiceWithRoundedTotal.details,
      );

      // Handle different payment methods
      if (paymentMethod == PaymentMethod.cod) {
        // COD: Invoice already exists with unpaid status, just update to pending
        final invoiceToSave = invoiceWithRoundedTotal.copyWith(
          salesStatus: SalesStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        );

        // Update invoice in Firebase
        await _firebase.updateSalesInvoice(invoiceToSave);

        // Clear cart items
        for (var detail in invoiceToSave.details) {
          await _firebase.removeFromCart(
              Database().userID, detail.product.productID ?? '');
        }

        emit(state.copyWith(
          salesInvoice: invoiceToSave,
          processState: ProcessState.success,
        ));
        return;
      } else if (paymentMethod == PaymentMethod.sepay) {
        // SePay: Create invoice and navigate to SePay payment screen
        // Invoice is already created in Firebase above
        // Update invoice status to pending (payment not yet confirmed)
        final invoiceToSave = invoiceWithRoundedTotal.copyWith(
          salesStatus: SalesStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        );

        // Update invoice in Firebase
        await _firebase.updateSalesInvoice(invoiceToSave);

        // Clear cart items (invoice is created, payment will be handled separately)
        for (var detail in invoiceToSave.details) {
          await _firebase.removeFromCart(
              Database().userID, detail.product.productID ?? '');
        }

        // Emit special state to indicate SePay payment screen should be shown
        // The UI will handle navigation to SePay payment screen
        emit(state.copyWith(
          salesInvoice: invoiceToSave,
          processState:
              ProcessState.idle, // Don't emit success yet - wait for payment
        ));
        return;
      } else if (paymentMethod == PaymentMethod.stripe) {
        // Stripe: Handle payment first, then update invoice on success
        // Invoice is already created in Firebase above, now store checkout data
        // Store checkout data with rounded total before redirect
        if (kIsWeb) {
          await _storeCheckoutDataForWeb(roundedTotalPrice);
        }

        String? result;
        try {
          result = await StripeServices.instance.makePayment(roundedTotalPrice);
        } catch (paymentError) {
          // Payment initiation failed - cancel the invoice
          if (invoiceWithRoundedTotal.salesInvoiceID != null &&
              invoiceWithRoundedTotal.salesInvoiceID!.isNotEmpty) {
            await cancelInvoiceFromId(invoiceWithRoundedTotal.salesInvoiceID!);
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
          // Payment failed - cancel the invoice
          if (invoiceWithRoundedTotal.salesInvoiceID != null &&
              invoiceWithRoundedTotal.salesInvoiceID!.isNotEmpty) {
            await cancelInvoiceFromId(invoiceWithRoundedTotal.salesInvoiceID!);
          }
          emit(state.copyWith(
              processState: ProcessState.failure, message: 'Payment failed'));
          return;
        }

        // Payment successful - update invoice to paid status with rounded total
        final invoiceToSave = invoiceWithRoundedTotal.copyWith(
          paymentStatus: PaymentStatus.paid,
        );

        await _firebase.updateSalesInvoice(invoiceToSave);

        // Clear cart items after successful payment
        for (var detail in invoiceToSave.details) {
          await _firebase.removeFromCart(
              Database().userID, detail.product.productID ?? '');
        }

        emit(state.copyWith(
          salesInvoice: invoiceToSave,
          processState: ProcessState.success,
        ));
      }
    } catch (e) {
      // Any error during checkout - cancel the invoice if it was created
      if (state.salesInvoice?.salesInvoiceID != null &&
          state.salesInvoice!.salesInvoiceID!.isNotEmpty) {
        await cancelInvoiceFromId(state.salesInvoice!.salesInvoiceID!);
      }
      emit(state.copyWith(
          processState: ProcessState.failure, message: e.toString()));
    }
  }

  /// Store checkout data in sessionStorage for web (before redirect)
  /// Uses the rounded total price passed from checkout() method
  Future<void> _storeCheckoutDataForWeb(int roundedTotalPrice) async {
    if (!kIsWeb || state.salesInvoice == null) return;

    try {
      // Store invoice summary - convert DateTime to ISO string for JSON encoding
      final invoiceMap = state.salesInvoice!.toMap();
      // Update totalPrice with rounded value (already calculated in checkout)
      invoiceMap['totalPrice'] = roundedTotalPrice;

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
        'paymentMethod': state.selectedPaymentMethod
            .getName(), // Store payment method explicitly
      };

      final checkoutDataJson = jsonEncode(checkoutData);
      StripeWebHelper.setSessionStorage(
          'stripe_checkout_data', checkoutDataJson);
    } catch (e) {
      // Error storing checkout data
    }
  }

  /// Complete checkout after successful payment (called from checkout success page)
  /// This method updates the existing invoice to paid status after successful Stripe payment
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

      // Restore payment method from stored data (in case it wasn't saved correctly)
      final storedPaymentMethod = checkoutData['paymentMethod'] as String?;
      PaymentMethod paymentMethod =
          PaymentMethod.stripe; // Default for Stripe checkout
      if (storedPaymentMethod != null) {
        paymentMethod = PaymentMethod.values.firstWhere(
          (e) => e.getName() == storedPaymentMethod,
          orElse: () => PaymentMethod.stripe,
        );
      }

      // Update invoice with paid status and correct payment method
      final updatedInvoice = salesInvoice.copyWith(
        paymentStatus: PaymentStatus.paid,
        paymentMethod: paymentMethod,
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
      rethrow;
    }
  }

  /// Complete SePay payment - called when payment is confirmed
  /// Updates the invoice to paid status after successful SePay payment
  Future<void> completeSePayPayment(String salesInvoiceID) async {
    try {
      // Load the existing invoice from Firebase
      final salesInvoice = await _firebase.getSalesInvoiceById(salesInvoiceID);
      if (salesInvoice == null) {
        throw Exception('Invoice not found: $salesInvoiceID');
      }

      // Update invoice with paid status
      final updatedInvoice = salesInvoice.copyWith(
        paymentStatus: PaymentStatus.paid,
        salesStatus: SalesStatus.pending, // Keep as pending until shipped
      );

      // Update invoice in Firebase
      await _firebase.updateSalesInvoice(updatedInvoice);

      // Emit success state
      emit(state.copyWith(
        salesInvoice: updatedInvoice,
        processState: ProcessState.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.failure,
        message: e.toString(),
      ));
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

    // Invoice is only in memory until checkout, so no need to update Firebase here
    // Changes will be saved to Firebase when user places the order
  }

  Future<void> updateVoucher(Voucher voucher) async {
    if (state.salesInvoice == null) return;

    // Calculate voucher discount without rounding
    final voucherDiscount = _calculateVoucherDiscount(voucher);

    final updatedInvoice = state.salesInvoice!.copyWith(
      voucher: voucher,
      voucherDiscount: voucherDiscount,
    );

    // Calculate total price with voucher discount (without rounding)
    // Rounding will happen only once at checkout
    final totalBeforeDiscount = updatedInvoice.getTotalBasedPrice();
    final totalAfterDiscount = totalBeforeDiscount - voucherDiscount;
    final finalTotal = totalAfterDiscount > 0 ? totalAfterDiscount : 0;

    final finalInvoice = updatedInvoice.copyWith(
      totalPrice: finalTotal,
    );

    // If total is 0, automatically switch to COD and disable SePay/Stripe
    PaymentMethod paymentMethod = state.selectedPaymentMethod;
    if (finalTotal == 0 &&
        (paymentMethod == PaymentMethod.sepay ||
            paymentMethod == PaymentMethod.stripe)) {
      paymentMethod = PaymentMethod.cod;
    }

    emit(state.copyWith(
      salesInvoice: finalInvoice,
      selectedPaymentMethod: paymentMethod,
    ));

    // Invoice is only in memory until checkout, so no need to update Firebase here
    // Changes will be saved to Firebase when user places the order
  }

  int _calculateVoucherDiscount(Voucher voucher) {
    final totalBeforeDiscount = state.salesInvoice!.getTotalBasedPrice();

    int discount;
    if (voucher.isPercentage) {
      int calculatedDiscount =
          (totalBeforeDiscount * (voucher.discountValue / 100)).round();
      final percentageVoucher = voucher as PercentageInterface;
      discount = calculatedDiscount > percentageVoucher.maximumDiscountValue
          ? percentageVoucher.maximumDiscountValue
          : calculatedDiscount;
    } else {
      final discountValue = voucher.discountValue.toInt();
      discount = discountValue > totalBeforeDiscount
          ? totalBeforeDiscount
          : discountValue;
    }
    return discount;
  }
}
