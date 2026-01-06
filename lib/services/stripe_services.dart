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

  /// Get the Stripe proxy base URL
  String _getProxyBaseUrl() {
    return 'https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/stripeProxy';
  }

  /// Check if using proxy (Cloud Function) - always use proxy on web
  bool _isUsingProxy() {
    return kIsWeb;
  }

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
      rethrow;
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      // For VND: database stores scaled values (e.g., 1000 = 1,000,000 VND)
      // Multiply by 1000 to convert to actual VND amount for Stripe
      final amountVND = _calculateAmountVND(amount);

      Response response;

      if (_isUsingProxy()) {
        // Use Cloud Function proxy (for web to keep secret key secure)
        response = await dio.post(
          _getProxyBaseUrl(),
          data: {
            'action': 'createPaymentIntent',
            'amount': int.parse(amountVND),
            'currency': currency.toLowerCase(),
          },
          options: Options(
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
            followRedirects: false,
          ),
        );

        if (response.statusCode == 200 && response.data is Map) {
          final proxyResponse = response.data as Map<String, dynamic>;
          if (proxyResponse['success'] == true &&
              proxyResponse['paymentIntent'] != null) {
            final paymentIntent =
                proxyResponse['paymentIntent'] as Map<String, dynamic>;
            return paymentIntent['clientSecret'] as String?;
          } else {
            final error =
                proxyResponse['error'] ?? 'Failed to create payment intent';
            throw Exception(error);
          }
        } else {
          throw Exception(
              'Proxy request failed with status ${response.statusCode}');
        }
      } else {
        // Direct API call (for mobile)
        // Check if Stripe secret key is available
        final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
        if (secretKey == null || secretKey.isEmpty) {
          throw Exception(
              'Stripe secret key not configured. Please check your .env file.');
        }

        Map<String, dynamic> data = {
          "amount": amountVND,
          "currency": currency,
        };

        response = await dio.post(
          "https://api.stripe.com/v1/payment_intents",
          data: data,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: {
              "Authorization": "Bearer $secretKey",
              "Content-Type": 'application/x-www-form-urlencoded',
            },
            // Do not throw on 4xx; let us surface Stripe's error message
            validateStatus: (status) => status != null && status < 500,
          ),
        );
      }

      // Handle direct API response (mobile only)
      if (!_isUsingProxy() && response.data != null) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data['client_secret'];
        } else {
          // Handle 401 Unauthorized specifically
          if (response.statusCode == 401) {
            final errorMessage =
                'Stripe authentication failed. Please check your API key configuration.';
            throw Exception(errorMessage);
          }

          // Extract Stripe error for clarity
          final stripeError = response.data is Map
              ? (response.data['error'] ?? response.data)
              : response.data;
          final message = stripeError is Map
              ? (stripeError['message'] ?? stripeError.toString())
              : '$stripeError';
          throw Exception(message);
        }
      }
      return null;
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
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

      final unitAmount = _calculateAmountVND(amount);

      Response response;

      if (_isUsingProxy()) {
        // Use Cloud Function proxy (for web to keep secret key secure)
        final lineItems = {
          "line_items[0][price_data][currency]": "vnd",
          "line_items[0][price_data][product_data][name]": "Order Payment",
          "line_items[0][price_data][unit_amount]": unitAmount,
          "line_items[0][quantity]": "1",
        };

        response = await dio.post(
          _getProxyBaseUrl(),
          data: {
            'action': 'createCheckoutSession',
            'successUrl': successUrl,
            'cancelUrl': cancelUrl,
            'lineItems': lineItems,
          },
          options: Options(
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
            followRedirects: false,
          ),
        );

        // Handle both 200 (success) and 400/500 (errors wrapped in 200 response)
        if (response.statusCode == 200 && response.data is Map) {
          final proxyResponse = response.data as Map<String, dynamic>;
          if (proxyResponse['success'] == true &&
              proxyResponse['session'] != null) {
            final session = proxyResponse['session'] as Map<String, dynamic>;
            return session['id'] as String?;
          } else {
            // Proxy returned error (wrapped in 200 response)
            final error =
                proxyResponse['error'] ?? 'Failed to create checkout session';
            throw Exception(error);
          }
        } else {
          // HTTP error (not 200)
          final errorMessage = response.data is Map
              ? (response.data['error'] ?? 'Proxy request failed')
              : 'Proxy request failed with status ${response.statusCode}';
          throw Exception(errorMessage);
        }
      } else {
        // Direct API call (for mobile)
        // Check if Stripe secret key is available
        final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
        if (secretKey == null || secretKey.isEmpty) {
          throw Exception(
              'Stripe secret key not configured. Please check your .env file.');
        }

        Map<String, dynamic> data = {
          "payment_method_types[]": "card",
          "line_items[0][price_data][currency]": "vnd",
          "line_items[0][price_data][product_data][name]": "Order Payment",
          "line_items[0][price_data][unit_amount]": unitAmount,
          "line_items[0][quantity]": "1",
          "mode": "payment",
          "success_url": successUrl,
          "cancel_url": cancelUrl,
        };

        response = await dio.post(
          "https://api.stripe.com/v1/checkout/sessions",
          data: data,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: {
              "Authorization": "Bearer $secretKey",
              "Content-Type": 'application/x-www-form-urlencoded',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );
      }

      // Handle direct API response (mobile only)
      if (!_isUsingProxy() && response.data != null) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data['id'];
        } else {
          // Handle 401 Unauthorized specifically
          if (response.statusCode == 401) {
            final errorMessage =
                'Stripe authentication failed. Please check your API key configuration.';
            throw Exception(errorMessage);
          }

          final stripeError = response.data is Map
              ? (response.data['error'] ?? response.data)
              : response.data;
          final message = stripeError is Map
              ? (stripeError['message'] ?? stripeError.toString())
              : '$stripeError';
          throw Exception(message);
        }
      }
      return null;
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create checkout session');
    }
  }

  Future<String?> _getCheckoutSessionUrl(String sessionId) async {
    try {
      final Dio dio = Dio();

      Response response;

      if (_isUsingProxy()) {
        // Use Cloud Function proxy (for web)
        response = await dio.post(
          _getProxyBaseUrl(),
          data: {
            'action': 'getCheckoutSession',
            'sessionId': sessionId,
          },
          options: Options(
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
            followRedirects: false,
          ),
        );

        if (response.statusCode == 200 && response.data is Map) {
          final proxyResponse = response.data as Map<String, dynamic>;
          if (proxyResponse['success'] == true &&
              proxyResponse['session'] != null) {
            final session = proxyResponse['session'] as Map<String, dynamic>;
            return session['url'] as String?;
          } else {
            final error =
                proxyResponse['error'] ?? 'Failed to get checkout session';
            throw Exception(error);
          }
        } else {
          throw Exception(
              'Proxy request failed with status ${response.statusCode}');
        }
      } else {
        // Direct API call (for mobile)
        // Check if Stripe secret key is available
        final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
        if (secretKey == null || secretKey.isEmpty) {
          throw Exception(
              'Stripe secret key not configured. Please check your .env file.');
        }

        response = await dio.get(
          "https://api.stripe.com/v1/checkout/sessions/$sessionId",
          options: Options(
            headers: {
              "Authorization": "Bearer $secretKey",
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        // Handle 401 Unauthorized
        if (response.statusCode == 401) {
          throw Exception(
              'Stripe authentication failed. Please check your API key configuration.');
        }

        if (response.data != null) {
          return response.data['url'];
        }
      }
      return null;
    } catch (e) {
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
      Response response;

      if (_isUsingProxy()) {
        // Use Cloud Function proxy (for web)
        response = await dio.post(
          _getProxyBaseUrl(),
          data: {
            'action': 'getCheckoutSession',
            'sessionId': actualSessionId,
          },
          options: Options(
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
            followRedirects: false,
          ),
        );

        if (response.statusCode == 200 && response.data is Map) {
          final proxyResponse = response.data as Map<String, dynamic>;
          if (proxyResponse['success'] == true &&
              proxyResponse['session'] != null) {
            final session = proxyResponse['session'] as Map<String, dynamic>;
            final paymentStatus = session['payment_status'];
            final paymentIntentId = session['payment_intent'];

            // Clear session storage
            StripeWebHelper.removeSessionStorage('stripe_checkout_session_id');
            StripeWebHelper.removeSessionStorage('stripe_checkout_metadata');

            if (paymentStatus == 'paid' && paymentIntentId != null) {
              return paymentIntentId as String;
            }
          }
        }
        return null;
      } else {
        // Direct API call (for mobile)
        // Check if Stripe secret key is available
        final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
        if (secretKey == null || secretKey.isEmpty) {
          return null;
        }

        response = await dio.get(
          "https://api.stripe.com/v1/checkout/sessions/$actualSessionId",
          options: Options(
            headers: {
              "Authorization": "Bearer $secretKey",
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        // Handle 401 Unauthorized
        if (response.statusCode == 401) {
          return null; // Return null instead of throwing to avoid breaking the flow
        }

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
      }
    } catch (e) {
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
      amountVND = 1000;
    }
    return amountVND.toString();
  }
}
