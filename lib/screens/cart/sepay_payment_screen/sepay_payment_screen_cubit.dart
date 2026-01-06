import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/services/sepay_payment_listener.dart';
import 'package:gizmoglobe_client/services/sepay_services.dart';
import '../../../enums/invoice_related/payment_status.dart';
import '../../../enums/processing/process_state_enum.dart';
import 'sepay_payment_screen_state.dart';

class SePayPaymentScreenCubit extends Cubit<SePayPaymentScreenState> {
  final SePayServices _sepayServices = SePayServices.instance;
  final SePayPaymentListener _paymentListener = SePayPaymentListener.instance;
  final Firebase _firebase = Firebase();
  String? _orderId;
  int? _amount;
  StreamSubscription<DocumentSnapshot>? _paymentStatusSubscription;
  Timer? _pollingTimer;

  SePayPaymentScreenCubit() : super(const SePayPaymentScreenState());

  /// Initialize payment and create virtual account
  Future<void> initializePayment({
    required String orderId,
    required int amount,
    String? customerName,
    String? description,
  }) async {
    emit(state.copyWith(processState: ProcessState.loading));
    _orderId = orderId;
    _amount = amount;

    try {
      // Create payment and get virtual account
      final result = await _sepayServices.createPayment(
        orderId: orderId,
        amount: amount,
        customerName: customerName,
        description: description ?? 'Order payment',
      );

      if (result.success && result.virtualAccount != null) {
        emit(state.copyWith(
          virtualAccount: result.virtualAccount,
          processState: ProcessState.idle,
          isPolling: true,
          message: result.message ?? '',
        ));

        // Start listening to Firestore for payment status changes (webhook support)
        _startPaymentStatusListener(orderId);

        // Also start polling as fallback (in case webhooks are not set up)
        _startPolling();
      } else {
        emit(state.copyWith(
          processState: ProcessState.failure,
          message: result.message ?? 'Failed to create payment',
        ));
      }
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Failed to create payment';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('no bank accounts') ||
          errorString.contains('cannot connect')) {
        errorMessage =
            'SePay service is currently unavailable. Please try again later or use a different payment method.';
      } else if (errorString.contains('bad state') ||
          errorString.contains('no element')) {
        errorMessage =
            'Payment processing error. Please try again or contact support.';
      } else if (errorString.contains('virtual account')) {
        errorMessage =
            'Failed to create virtual account. Please try again or use a different payment method.';
      } else if (errorString.contains('network') ||
          errorString.contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        // For other errors, try to extract a meaningful message
        final exceptionStr = e.toString();
        if (exceptionStr.contains('Exception: ')) {
          // Remove "Exception: " prefix and take first line
          final cleanMessage = exceptionStr
              .replaceFirst('Exception: ', '')
              .split('\n')
              .first
              .trim();
          if (cleanMessage.isNotEmpty && cleanMessage.length < 200) {
            errorMessage = cleanMessage;
          }
        }
      }

      emit(state.copyWith(
        processState: ProcessState.failure,
        message: errorMessage,
      ));
    }
  }

  /// Start listening to Firestore for payment status changes
  /// This listens for webhook updates that modify the invoice payment status
  void _startPaymentStatusListener(String invoiceId) {
    _paymentStatusSubscription = _paymentListener.listenToPaymentStatus(
      invoiceId: invoiceId,
      onPaymentStatusChanged: (PaymentStatus status) {
        if (status == PaymentStatus.paid &&
            state.processState != ProcessState.success) {
          // Payment confirmed via webhook or direct Firestore update
          _stopPolling();
          emit(state.copyWith(
            processState: ProcessState.success,
            isPolling: false,
            message: 'Payment confirmed successfully',
          ));
        }
      },
    );
  }

  /// Start polling as fallback (in case webhooks are not set up)
  void _startPolling() {
    // Poll every 10 seconds (less frequent since we have Firestore listener)
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (state.processState == ProcessState.success) {
        _stopPolling();
        return;
      }
      checkPaymentStatus();
    });
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Check payment status by polling SePay API
  Future<void> checkPaymentStatus() async {
    if (_orderId == null || _amount == null) {
      return;
    }

    if (state.processState == ProcessState.success) {
      // Payment already confirmed, stop polling
      return;
    }

    try {
      // Check if payment was made
      final transaction = await _sepayServices.checkPaymentByOrderId(
        orderId: _orderId!,
        amount: _amount!,
      );

      if (transaction != null && transaction.isPaid) {
        // Payment confirmed via polling
        _stopPolling();
        emit(state.copyWith(
          processState: ProcessState.success,
          transaction: transaction,
          isPolling: false,
          message: 'Payment confirmed successfully',
        ));
      } else {
        // Still waiting for payment
        emit(state.copyWith(isPolling: true));
      }
    } catch (e) {
      // Continue polling even if there's an error
      emit(state.copyWith(isPolling: true));
    }
  }

  /// Cancel payment polling and listeners
  void cancelPolling() {
    _stopPolling();
    _paymentStatusSubscription?.cancel();
    _paymentStatusSubscription = null;
    emit(state.copyWith(isPolling: false));
  }

  void clearDismissError() {
    if (state.dismissError != null) {
      emit(state.copyWith(dismissError: null));
    }
  }

  Future<bool> handleDismissal() async {
    _stopPolling();
    _paymentStatusSubscription?.cancel();
    _paymentStatusSubscription = null;

    if (_orderId == null) {
      emit(state.copyWith(
        isRestoringCart: false,
        dismissError: null,
      ));
      return true;
    }

    emit(state.copyWith(isRestoringCart: true, dismissError: null));
    String? errorMessage;

    try {
      final invoice = await _firebase.getSalesInvoiceById(_orderId!);
      final userID = Database().userID;

      if (invoice != null && invoice.details.isNotEmpty && userID.isNotEmpty) {
        for (final detail in invoice.details) {
          final productID = detail.product.productID;
          final quantity = detail.quantity;
          if (productID != null && productID.isNotEmpty && quantity > 0) {
            try {
              await _firebase.addToCart(userID, productID, quantity);
            } catch (e) {
              errorMessage ??=
                  'Some items could not be restored to your cart. Please review your cart.';
            }
          }
        }
      }

      try {
        await _firebase.cancelSalesInvoice(_orderId!);
      } catch (e) {
        errorMessage ??= 'Unable to cancel pending invoice properly.';
      }

      try {
        await _firebase.deleteSalesInvoice(_orderId!);
      } catch (e) {
        errorMessage ??= 'Unable to remove pending invoice.';
      }

      _orderId = null;
      _amount = null;
    } catch (e) {
      emit(state.copyWith(
        isRestoringCart: false,
        dismissError: e.toString(),
      ));
      return false;
    }

    emit(state.copyWith(
      isRestoringCart: false,
      dismissError: errorMessage,
    ));
    return errorMessage == null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    _paymentStatusSubscription?.cancel();
    _paymentStatusSubscription = null;
    return super.close();
  }
}
