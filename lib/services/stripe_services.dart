import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeServices {
  StripeServices._();

  static final StripeServices instance = StripeServices._();

  Future<String?> makePayment(double amount) async {
    try {
      String? paymentIntentClientSecret =
          await _createPaymentMethod(amount, "usd");
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
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      throw Exception('Payment failed'); //Thanh toán thất bại.
    }
    return null;
  }

  Future<String?> _createPaymentMethod(double amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
      };

      var response = await dio.post("https://api.stripe.com/v1/payment_intents",
          data: data,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: {
              "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']}",
              "Content-Type": 'application/x-www-form-urlencoded',
            },
          ));

      if (response.data != null) {
        if (kDebugMode) {
          print(response.data);
        }
        return response.data['client_secret'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      throw Exception(
          'Payment method creation failed'); //Khởi tạo phương thức thanh toán thất bại
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

  String _calculateAmount(double amount) {
    final int amountInCents = (amount * 100).toInt();
    return amountInCents.toString();
  }
}
