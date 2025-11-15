import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/services/stripe_services.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_view.dart';
import '../../../enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/services/stripe_web_helper_stub.dart'
    if (dart.library.html) 'package:gizmoglobe_client/services/stripe_web_helper_web.dart';
import 'checkout_screen_cubit.dart';

/// Web-only screen to handle Stripe Checkout success redirect
class CheckoutSuccessWebView extends StatefulWidget {
  const CheckoutSuccessWebView({super.key});

  @override
  State<CheckoutSuccessWebView> createState() => _CheckoutSuccessWebViewState();
}

class _CheckoutSuccessWebViewState extends State<CheckoutSuccessWebView> {
  bool _isChecking = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkPaymentStatus();
    } else {
      _errorMessage = 'This screen is only available on web';
      _isChecking = false;
    }
  }

  Future<void> _checkPaymentStatus() async {
    try {
      // Get session ID from URL hash fragment if available
      // Stripe redirects to #/checkout-success?session_id=...
      String? sessionId;
      if (kIsWeb) {
        final hash = StripeWebHelper.getHashFragment();
        if (hash != null && hash.contains('?')) {
          // Parse query parameters from hash fragment
          // Hash format: #/checkout-success?session_id=...
          final hashWithoutHash = hash.replaceFirst('#', '');
          final uri = Uri.parse('?${hashWithoutHash.split('?').last}');
          sessionId = uri.queryParameters['session_id'];
        }

        // Also check regular URL query parameters as fallback
        if (sessionId == null) {
          final currentUrl = StripeWebHelper.getCurrentUrl();
          if (currentUrl != null) {
            final uri = Uri.parse(currentUrl);
            sessionId = uri.queryParameters['session_id'];
          }
        }
      }

      // Check payment status from Stripe
      final paymentIntentId =
          await StripeServices.instance.checkPaymentStatus(sessionId);

      if (paymentIntentId != null) {
        // Payment successful - complete the checkout
        try {
          // Create a new cubit instance to complete checkout
          final cubit = CheckoutScreenCubit();
          await cubit.completeCheckoutFromStoredData(paymentIntentId);

          if (mounted) {
            // Navigate to orders page
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => OrderScreen.newInstance(
                  orderOption: OrderOption.toShip,
                ),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          // Payment verification failed - cancel the invoice
          try {
            final checkoutDataJson = StripeWebHelper.getSessionStorage('stripe_checkout_data');
            if (checkoutDataJson != null) {
              final checkoutData = jsonDecode(checkoutDataJson) as Map<String, dynamic>;
              final salesInvoiceID = checkoutData['salesInvoiceID'] as String?;
              if (salesInvoiceID != null && salesInvoiceID.isNotEmpty) {
                final cubit = CheckoutScreenCubit();
                await cubit.cancelInvoiceFromId(salesInvoiceID);
              }
            }
          } catch (cancelError) {
            if (kDebugMode) {
              print('Error cancelling invoice after payment failure: $cancelError');
            }
          }

          if (mounted) {
            setState(() {
              _isChecking = false;
              _errorMessage = 'Error completing order: $e';
            });
          }
        }
      } else {
        // Payment failed or was cancelled - cancel the invoice
        try {
          final checkoutDataJson = StripeWebHelper.getSessionStorage('stripe_checkout_data');
          if (checkoutDataJson != null) {
            final checkoutData = jsonDecode(checkoutDataJson) as Map<String, dynamic>;
            final salesInvoiceID = checkoutData['salesInvoiceID'] as String?;
            if (salesInvoiceID != null && salesInvoiceID.isNotEmpty) {
              final cubit = CheckoutScreenCubit();
              await cubit.cancelInvoiceFromId(salesInvoiceID);
            }
          }
        } catch (cancelError) {
          if (kDebugMode) {
            print('Error cancelling invoice after payment cancellation: $cancelError');
          }
        }

        setState(() {
          _isChecking = false;
          _errorMessage = 'Payment was not completed. Please try again.';
        });
      }
    } catch (e) {
      // Error during payment verification - cancel the invoice
      try {
        final checkoutDataJson = StripeWebHelper.getSessionStorage('stripe_checkout_data');
        if (checkoutDataJson != null) {
          final checkoutData = jsonDecode(checkoutDataJson) as Map<String, dynamic>;
          final salesInvoiceID = checkoutData['salesInvoiceID'] as String?;
          if (salesInvoiceID != null && salesInvoiceID.isNotEmpty) {
            final cubit = CheckoutScreenCubit();
            await cubit.cancelInvoiceFromId(salesInvoiceID);
          }
        }
      } catch (cancelError) {
        if (kDebugMode) {
          print('Error cancelling invoice after verification error: $cancelError');
        }
      }

      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Error verifying payment: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const WebHeader(),
            Expanded(
              child: Center(
                child: _isChecking
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Verifying payment...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      )
                    : _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/cart',
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Return to Cart'),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
