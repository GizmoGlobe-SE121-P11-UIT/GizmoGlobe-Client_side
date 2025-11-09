# SePay Integration Example

This document shows how to integrate SePay into your existing checkout flow.

## 1. Environment Variables Setup

Add to your `.env` file:

```env
# SePay Configuration
SEPAY_CLIENT_ID=your_client_id_here
SEPAY_CLIENT_SECRET=your_client_secret_here
SEPAY_API_BASE_URL=https://api.sepay.vn
```

## 2. Update Checkout Screen Cubit

Here's how to modify `checkout_screen_cubit.dart` to support SePay:

```dart
import '../../../services/sepay_services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // For QR code display

// Add to CheckoutScreenCubit class:

enum PaymentMethod {
  stripe,
  sepay,
}

// Add payment method selection
void selectPaymentMethod(PaymentMethod method) {
  emit(state.copyWith(paymentMethod: method));
}

// Update checkout method
Future<void> checkout() async {
  emit(state.copyWith(processState: ProcessState.loading));
  try {
    if (state.paymentMethod == PaymentMethod.sepay) {
      // SePay payment flow
      await _processSePayPayment();
    } else {
      // Stripe payment flow (existing)
      await _processStripePayment();
    }
  } catch (e) {
    emit(state.copyWith(
      processState: ProcessState.failure,
      message: e.toString(),
    ));
  }
}

Future<void> _processSePayPayment() async {
  try {
    final orderId = state.salesInvoice!.salesInvoiceID.isEmpty
        ? 'order_${DateTime.now().millisecondsSinceEpoch}'
        : state.salesInvoice!.salesInvoiceID;

    // Create Virtual Account
    final result = await SePayServices.instance.makePayment(
      orderId: orderId,
      amount: state.salesInvoice!.totalPrice,
      customerName: Database().userID, // Or get from user profile
      description: 'Order payment - ${state.salesInvoice!.details.length} items',
      waitForPayment: false, // Don't wait, show payment instructions
    );

    if (result.success && result.virtualAccount != null) {
      // Save VA details to state
      emit(state.copyWith(
        sepayVirtualAccount: result.virtualAccount,
        processState: ProcessState.success,
        message: 'Virtual account created. Please complete payment.',
      ));

      // Start polling for payment (in background)
      _pollPaymentStatus(orderId);
    } else {
      throw Exception('Failed to create virtual account');
    }
  } catch (e) {
    throw Exception('SePay payment failed: $e');
  }
}

Future<void> _pollPaymentStatus(String orderId) async {
  // Poll in background
  final transaction = await SePayServices.instance.pollPaymentStatus(
    orderId: orderId,
    pollInterval: 5, // Check every 5 seconds
    maxAttempts: 60, // Total 5 minutes
  );

  if (transaction != null && transaction.status == SePayTransactionStatus.paid) {
    // Payment confirmed
    emit(state.copyWith(
      salesInvoice: state.salesInvoice!.copyWith(
        paymentStatus: PaymentStatus.paid,
      ),
    ));
    await saveSalesInvoice();
    
    // Show success message
    emit(state.copyWith(
      processState: ProcessState.success,
      message: 'Payment confirmed!',
    ));
  } else {
    // Payment timeout or failed
    emit(state.copyWith(
      processState: ProcessState.failure,
      message: 'Payment not confirmed. Please try again.',
    ));
  }
}

Future<void> _processStripePayment() async {
  // Existing Stripe payment logic
  String? result;
  result = await StripeServices.instance.makePayment(
    state.salesInvoice!.totalPrice,
  );

  if (result == null) {
    if (kDebugMode) {
      print('Payment failed');
    }
    emit(state.copyWith(
      processState: ProcessState.failure,
      message: 'Payment failed',
    ));
    return;
  }

  emit(state.copyWith(
    salesInvoice: state.salesInvoice!.copyWith(
      paymentStatus: PaymentStatus.paid,
    ),
  ));
  await saveSalesInvoice();
  emit(state.copyWith(processState: ProcessState.success));
}
```

## 3. Update Checkout Screen View

Add payment method selection and SePay payment UI:

```dart
// Add to checkout_screen_view.dart

// Payment method selector
Row(
  children: [
    Radio<PaymentMethod>(
      value: PaymentMethod.stripe,
      groupValue: state.paymentMethod,
      onChanged: (value) {
        context.read<CheckoutScreenCubit>().selectPaymentMethod(value!);
      },
    ),
    Text('Credit/Debit Card (Stripe)'),
    
    Radio<PaymentMethod>(
      value: PaymentMethod.sepay,
      groupValue: state.paymentMethod,
      onChanged: (value) {
        context.read<CheckoutScreenCubit>().selectPaymentMethod(value!);
      },
    ),
    Text('Bank Transfer (SePay)'),
  ],
),

// SePay payment instructions (show when VA is created)
if (state.sepayVirtualAccount != null)
  Column(
    children: [
      Text('Please transfer to the following account:'),
      Text('Bank: ${state.sepayVirtualAccount!.bankName}'),
      Text('Account Number: ${state.sepayVirtualAccount!.accountNumber}'),
      Text('Amount: ${state.sepayVirtualAccount!.amount.toStringAsFixed(0)} VND'),
      
      // QR Code display
      if (state.sepayVirtualAccount!.qrCode != null)
        QrImageView(
          data: state.sepayVirtualAccount!.qrCode!,
          size: 200,
        ),
      
      Text('Waiting for payment confirmation...'),
      CircularProgressIndicator(),
    ],
  ),
```

## 4. Update State

Add to `checkout_screen_state.dart`:

```dart
final PaymentMethod paymentMethod;
final SePayVirtualAccount? sepayVirtualAccount;

// Update copyWith method
CheckoutScreenState copyWith({
  // ... existing fields
  PaymentMethod? paymentMethod,
  SePayVirtualAccount? sepayVirtualAccount,
}) {
  return CheckoutScreenState(
    // ... existing fields
    paymentMethod: paymentMethod ?? this.paymentMethod,
    sepayVirtualAccount: sepayVirtualAccount ?? this.sepayVirtualAccount,
  );
}
```

## 5. Update Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  qr_flutter: ^4.1.0  # For QR code generation
```

## 6. Currency Conversion

Since SePay uses VND and your app might use USD, you'll need to convert:

```dart
// Example conversion (use actual exchange rate)
double convertToVND(double usdAmount) {
  const exchangeRate = 25000; // 1 USD = 25000 VND (example)
  return usdAmount * exchangeRate;
}

// In checkout
final amountInVND = convertToVND(state.salesInvoice!.totalPrice);
final result = await SePayServices.instance.makePayment(
  orderId: orderId,
  amount: amountInVND,
  // ...
);
```

## 7. Alternative: Separate SePay Checkout Screen

You could also create a dedicated SePay checkout screen:

```dart
// lib/screens/cart/sepay_checkout_screen/sepay_checkout_screen.dart

class SePayCheckoutScreen extends StatelessWidget {
  final SalesInvoice salesInvoice;
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SePayCheckoutCubit()..initialize(salesInvoice),
      child: BlocBuilder<SePayCheckoutCubit, SePayCheckoutState>(
        builder: (context, state) {
          if (state.virtualAccount == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return Scaffold(
            appBar: AppBar(title: Text('SePay Payment')),
            body: Column(
              children: [
                // Payment instructions
                Text('Transfer to:'),
                Text(state.virtualAccount!.bankName),
                Text(state.virtualAccount!.accountNumber),
                Text('${state.virtualAccount!.amount} VND'),
                
                // QR Code
                if (state.virtualAccount!.qrCode != null)
                  QrImageView(
                    data: state.virtualAccount!.qrCode!,
                    size: 250,
                  ),
                
                // Payment status
                if (state.isWaiting)
                  Column(
                    children: [
                      CircularProgressIndicator(),
                      Text('Waiting for payment...'),
                    ],
                  ),
                
                if (state.isPaid)
                  Text('Payment confirmed!'),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## 8. WebHook Integration (Advanced)

For real-time payment notifications, set up Firebase Cloud Functions:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sepayWebhook = functions.https.onRequest(async (req, res) => {
  // Verify WebHook signature (important for security)
  const signature = req.headers['x-sepay-signature'];
  // Verify signature with SePay secret
  
  const { order_id, status, transaction_id } = req.body;
  
  if (status === 'paid') {
    // Update Firestore
    await admin.firestore()
      .collection('orders')
      .doc(order_id)
      .update({
        paymentStatus: 'paid',
        transactionId: transaction_id,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  }
  
  res.status(200).send('OK');
});
```

Then in your Flutter app, listen to Firestore changes:

```dart
StreamSubscription? _paymentSubscription;

void listenToPaymentStatus(String orderId) {
  _paymentSubscription = FirebaseFirestore.instance
    .collection('orders')
    .doc(orderId)
    .snapshots()
    .listen((snapshot) {
      if (snapshot.data()?['paymentStatus'] == 'paid') {
        // Payment confirmed
        emit(state.copyWith(
          salesInvoice: state.salesInvoice!.copyWith(
            paymentStatus: PaymentStatus.paid,
          ),
        ));
        saveSalesInvoice();
      }
    });
}
```

## 9. Testing

1. **Test OAuth2 Flow**
   ```dart
   final token = await SePayServices.instance._getAccessToken();
   print('Token: $token');
   ```

2. **Test VA Creation**
   ```dart
   final va = await SePayServices.instance.createVirtualAccount(
     orderId: 'test_order_123',
     amount: 100000, // 100k VND
   );
   print('VA: ${va.accountNumber}');
   ```

3. **Test Transaction Query**
   ```dart
   final transaction = await SePayServices.instance.checkTransactionStatus(
     'test_order_123',
   );
   print('Status: ${transaction.status}');
   ```

4. **Use SePay Transaction Simulation**
   - SePay provides transaction simulation for testing
   - Use test credentials in development
   - Verify payment flow end-to-end

## 10. Error Handling

Add comprehensive error handling:

```dart
try {
  await SePayServices.instance.makePayment(...);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Authentication error
    showError('Authentication failed. Please check credentials.');
  } else if (e.response?.statusCode == 400) {
    // Bad request
    showError('Invalid request: ${e.response?.data}');
  } else {
    showError('Network error: ${e.message}');
  }
} catch (e) {
  showError('Payment failed: $e');
}
```

## Notes

- **API Endpoints**: The endpoints in the service are examples. Verify actual endpoints from SePay documentation.
- **Currency**: Ensure proper VND conversion and formatting.
- **Security**: Store OAuth2 tokens securely, consider using encrypted storage.
- **User Experience**: Clearly communicate payment instructions and waiting times.
- **Testing**: Use SePay's test environment before production.

---

For more details, refer to:
- SePay Documentation: https://docs.sepay.vn/
- SePay API Documentation: https://docs.sepay.vn/gioi-thieu-api.html
- Integration Analysis: `SEPAY_INTEGRATION_ANALYSIS.md`

