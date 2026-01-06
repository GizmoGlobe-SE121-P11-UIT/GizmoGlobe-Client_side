import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/invoice_related/payment_status.dart';

/// SePay Payment Listener Service
///
/// This service listens to Firestore for real-time payment status updates.
/// When webhooks are set up, they will update Firestore, and this listener
/// will immediately notify the app of payment status changes.
///
/// Flow:
/// 1. Invoice is created with paymentStatus = unpaid
/// 2. SePay webhook receives payment notification
/// 3. Webhook updates invoice paymentStatus = paid in Firestore
/// 4. This listener detects the change and notifies the app
/// 5. App updates UI and completes checkout
class SePayPaymentListener {
  SePayPaymentListener._();

  static final SePayPaymentListener instance = SePayPaymentListener._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _subscription;

  /// Listen to payment status changes for a specific invoice
  ///
  /// [invoiceId] - Sales invoice ID to listen to
  /// [onPaymentStatusChanged] - Callback when payment status changes
  ///
  /// Returns a StreamSubscription that can be cancelled
  StreamSubscription<DocumentSnapshot>? listenToPaymentStatus({
    required String invoiceId,
    required void Function(PaymentStatus status) onPaymentStatusChanged,
  }) {
    try {
      final invoiceRef = _firestore.collection('sales_invoices').doc(invoiceId);

      _subscription = invoiceRef.snapshots().listen(
        (snapshot) {
          if (!snapshot.exists) {
            return;
          }

          final data = snapshot.data() as Map<String, dynamic>;
          final paymentStatusStr = data['paymentStatus'] as String?;

          if (paymentStatusStr != null) {
            try {
              final paymentStatus = PaymentStatus.values.firstWhere(
                (e) => e.getName() == paymentStatusStr,
                orElse: () => PaymentStatus.unpaid,
              );

              // Notify listener of status change
              onPaymentStatusChanged(paymentStatus);
            } catch (e) {
              // Error parsing payment status
            }
          }
        },
        onError: (error) {
          // Error listening to payment status
        },
      );

      return _subscription;
    } catch (e) {
      return null;
    }
  }

  /// Stop listening to payment status changes
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}
