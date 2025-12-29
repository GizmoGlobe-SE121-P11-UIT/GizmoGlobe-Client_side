import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gizmoglobe_client/services/stripe_web_helper_stub.dart'
    if (dart.library.html) 'package:gizmoglobe_client/services/stripe_web_helper_web.dart';

class StripeServices {
  StripeServices._();

  static final StripeServices instance = StripeServices._();

  Future<String?> makePayment(int amount,
      {Map<String, dynamic>? metadata}) async {
    try {
      if (kIsWeb) {
        // Use Stripe Checkout for web
        // Store metadata (like invoice data) before redirect if provided
        if (metadata != null && kIsWeb) {
          StripeWebHelper.setSessionStorage('stripe_checkout_metadata',
              metadata.toString()); // Store as string for now
        }
        return await _makePaymentWeb(amount);
      } else {
        // Use Payment Sheet for mobile (iOS/Android)
        return await _makePaymentMobile(amount);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      throw Exception('Payment failed'); //Thanh toán thất bại.
    }
  }

  Future<String?> _makePaymentMobile(int amount) async {
    String? paymentIntentClientSecret =
        await _createPaymentIntent(amount, "vnd");
    if (paymentIntentClientSecret == null) {
      return null;
    }
    await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: paymentIntentClientSecret,
      style: ThemeMode.dark,
      merchantDisplayName: 'Gizmo Globe',
    ));
    String? result = await _processPayment(paymentIntentClientSecret);
    if (result != null) {
      return result;
    }
    return null;
  }

  Future<String?> _makePaymentWeb(int amount) async {
    try {
      // Create a Stripe Checkout Session
      final checkoutSessionId = await _createCheckoutSession(amount);
      if (checkoutSessionId == null) {
        throw Exception('Failed to create checkout session');
      }

      // Redirect to Stripe Checkout
      final checkoutUrl = await _getCheckoutSessionUrl(checkoutSessionId);
      if (checkoutUrl != null) {
        // Store the session ID in sessionStorage to retrieve after redirect
        StripeWebHelper.setSessionStorage(
            'stripe_checkout_session_id', checkoutSessionId);
        // Redirect to Stripe Checkout
        StripeWebHelper.redirectTo(checkoutUrl);
        // Return null here - the payment will be handled after redirect
        // The app should check for payment success on return
        return null;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Web payment error: $e');
      }
      rethrow;
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      // For VND: database stores scaled values (e.g., 1000 = 1,000,000 VND)
      // Multiply by 1000 to convert to actual VND amount for Stripe
      Map<String, dynamic> data = {
        "amount": _calculateAmountVND(amount),
        "currency": currency,
      };

      if (kDebugMode) {
        print('Stripe: Creating PaymentIntent');
        print('  currency=$currency');
        print('  dbAmount=$amount (k VND)');
        print('  amountForStripe=${data["amount"]} VND');
      }

      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']}",
            "Content-Type": 'application/x-www-form-urlencoded',
          },
          // Do not throw on 4xx; let us surface Stripe's error message
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.data != null) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (kDebugMode) {
            print('Stripe: PaymentIntent created');
          }
          return response.data['client_secret'];
        } else {
          // Extract Stripe error for clarity
          final stripeError = response.data is Map
              ? (response.data['error'] ?? response.data)
              : response.data;
          final message = stripeError is Map
              ? (stripeError['message'] ?? stripeError.toString())
              : '$stripeError';
          if (kDebugMode) {
            print(
                'Stripe: PaymentIntent error (${response.statusCode}): $message');
          }
          throw Exception(message);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Stripe: Exception creating PaymentIntent: $e');
      }
      throw Exception(
          'Payment method creation failed'); //Khởi tạo phương thức thanh toán thất bại
    }
  }

  Future<String?> _createCheckoutSession(int amount) async {
    try {
      final Dio dio = Dio();

      // Get current URL for success and cancel URLs
      final baseUrl = StripeWebHelper.getBaseUrl() ?? '';
      final successUrl =
          '$baseUrl#/checkout-success?session_id={CHECKOUT_SESSION_ID}';
      final cancelUrl = '$baseUrl#/cart';

      Map<String, dynamic> data = {
        "payment_method_types[]": "card",
        "line_items[0][price_data][currency]": "vnd",
        "line_items[0][price_data][product_data][name]": "Order Payment",
        "line_items[0][price_data][unit_amount]": _calculateAmountVND(amount),
        "line_items[0][quantity]": "1",
        "mode": "payment",
        "success_url": successUrl,
        "cancel_url": cancelUrl,
      };

      if (kDebugMode) {
        print('Stripe: Creating Checkout Session');
        print('  dbAmount=$amount (k VND)');
        print(
            '  unit_amount=${data["line_items[0][price_data][unit_amount]"]} VND');
      }

      var response = await dio.post(
        "https://api.stripe.com/v1/checkout/sessions",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']}",
            "Content-Type": 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.data != null) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (kDebugMode) {
            print('Stripe: Checkout session created: ${response.data['id']}');
          }
          return response.data['id'];
        } else {
          final stripeError = response.data is Map
              ? (response.data['error'] ?? response.data)
              : response.data;
          final message = stripeError is Map
              ? (stripeError['message'] ?? stripeError.toString())
              : '$stripeError';
          if (kDebugMode) {
            print(
                'Stripe: Checkout session error (${response.statusCode}): $message');
          }
          throw Exception(message);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating checkout session: $e');
      }
      throw Exception('Failed to create checkout session');
    }
  }

  Future<String?> _getCheckoutSessionUrl(String sessionId) async {
    try {
      final Dio dio = Dio();

      var response = await dio.get(
        "https://api.stripe.com/v1/checkout/sessions/$sessionId",
        options: Options(
          headers: {
            "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']}",
          },
        ),
      );

      if (response.data != null) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting checkout session URL: $e');
      }
      return null;
    }
  }

  /// Check if payment was successful after redirect from Stripe Checkout
  /// Call this method when the app returns from Stripe Checkout
  /// Returns the payment intent ID if successful, null otherwise
  Future<String?> checkPaymentStatus([String? sessionId]) async {
    if (!kIsWeb) return null;

    try {
      // Get session ID from parameter, URL, or sessionStorage
      String? actualSessionId = sessionId;

      if (actualSessionId == null) {
        // Try to get from URL query parameters (may be in hash or query)
        final queryParams = StripeWebHelper.getUrlQueryParameters();
        actualSessionId = queryParams['session_id'];

        // Also check hash fragment for session_id
        // Hash format: #/checkout-success?session_id=...
        if (actualSessionId == null) {
          final hash = StripeWebHelper.getHashFragment();
          if (hash != null && hash.contains('session_id=')) {
            // Extract query parameters from hash fragment
            final hashWithoutHash = hash.replaceFirst('#', '');
            if (hashWithoutHash.contains('?')) {
              final queryPart = hashWithoutHash.split('?').last;
              final hashUri = Uri.parse('?$queryPart');
              actualSessionId = hashUri.queryParameters['session_id'];
            }
          }
        }
      }

      // Fallback to sessionStorage
      actualSessionId ??=
          StripeWebHelper.getSessionStorage('stripe_checkout_session_id');

      if (actualSessionId == null) return null;

      final Dio dio = Dio();
      var response = await dio.get(
        "https://api.stripe.com/v1/checkout/sessions/$actualSessionId",
        options: Options(
          headers: {
            "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']}",
          },
        ),
      );

      if (response.data != null) {
        final paymentStatus = response.data['payment_status'];
        final paymentIntentId = response.data['payment_intent'];

        // Clear session storage
        StripeWebHelper.removeSessionStorage('stripe_checkout_session_id');
        StripeWebHelper.removeSessionStorage('stripe_checkout_metadata');

        if (paymentStatus == 'paid' && paymentIntentId != null) {
          return paymentIntentId as String;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking payment status: $e');
      }
      return null;
    }
  }

  Future<String?> _processPayment(String paymentIntentClientSecret) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      final paymentIntent = await Stripe.instance
          .retrievePaymentIntent(paymentIntentClientSecret);
      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        return paymentIntent.id;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      throw Exception(
          'Payment processing failed'); //Quá trình thanh toán thất bại
    }
  }

  /// Calculate amount for VND
  /// Database stores scaled values (e.g., 5589.6 = 5,589,600 VND)
  /// Multiply by 1000 to convert to actual VND amount for Stripe
  /// VND is a zero-decimal currency, so we send the amount directly
  /// Use round() to avoid floating point precision issues
  /// Example: database has 5589.6, multiply by 1000 and round = 5,589,600 VND
  String _calculateAmountVND(int amount) {
    // Round to avoid floating point precision errors
    // e.g., 5589.6 * 1000 might result in 5589599.9999999 instead of 5589600.0
    int amountVND = (amount * 1000).round();
    // Enforce a small minimum to avoid Stripe 400 on tiny amounts (defensive)
    if (amountVND < 1000) {
      if (kDebugMode) {
        print(
            'Stripe: amount below minimum, raising to 1000 VND (was $amountVND)');
      }
      amountVND = 1000;
    }
    return amountVND.toString();
  }
}
