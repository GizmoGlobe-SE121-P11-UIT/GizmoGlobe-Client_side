import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// SePay Services - Payment integration via bank transfer
///
/// This service handles SePay API integration for Vietnamese bank transfer payments.
/// SePay allows businesses to accept payments via bank transfers without payment gateway fees.
///
/// Required setup:
/// 1. Register application with SePay to get client_id and client_secret
/// 2. Add SEPAY_CLIENT_ID and SEPAY_CLIENT_SECRET to .env file
/// 3. Add SEPAY_API_BASE_URL to .env file (e.g., https://api.sepay.vn)
///
/// Documentation: https://docs.sepay.vn/
class SePayServices {
  SePayServices._();

  static final SePayServices instance = SePayServices._();

  // OAuth2 token cache
  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Get OAuth2 access token
  /// SePay uses OAuth2 for API authentication
  Future<String> _getAccessToken() async {
    // Check if token is still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    try {
      final clientId = dotenv.env['SEPAY_CLIENT_ID'];
      final clientSecret = dotenv.env['SEPAY_CLIENT_SECRET'];
      final baseUrl =
          dotenv.env['SEPAY_API_BASE_URL'] ?? 'https://api.sepay.vn';

      if (clientId == null || clientSecret == null) {
        throw Exception(
            'SePay credentials not configured. Please add SEPAY_CLIENT_ID and SEPAY_CLIENT_SECRET to .env file');
      }

      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/oauth2/token',
        data: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        _accessToken = response.data['access_token'];
        final expiresIn = response.data['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(
            Duration(seconds: expiresIn - 60)); // Refresh 1 min before expiry

        if (kDebugMode) {
          print('SePay OAuth2 token obtained successfully');
        }

        return _accessToken!;
      } else {
        throw Exception(
            'Failed to obtain OAuth2 token: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error obtaining SePay OAuth2 token: $e');
      }
      throw Exception('Authentication failed: $e');
    }
  }

  /// Create Virtual Account (VA) for an order
  ///
  /// SePay creates a unique virtual account for each order,
  /// allowing automatic payment verification when customer transfers money.
  ///
  /// [orderId] - Unique order identifier
  /// [amount] - Payment amount in VND
  /// [customerName] - Customer name (optional)
  /// [description] - Order description (optional)
  ///
  /// Returns Virtual Account details including:
  /// - accountNumber: Virtual account number
  /// - bankName: Bank name
  /// - qrCode: QR code data for payment
  /// - expiresAt: VA expiration time
  Future<SePayVirtualAccount> createVirtualAccount({
    required String orderId,
    required double amount,
    String? customerName,
    String? description,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final baseUrl =
          dotenv.env['SEPAY_API_BASE_URL'] ?? 'https://api.sepay.vn';

      final dio = Dio();

      // Convert amount to VND (smallest unit)
      final amountInVND =
          (amount * 1000).toInt(); // Assuming amount is in thousands of VND

      final response = await dio.post(
        '$baseUrl/api/va/create',
        data: {
          'order_id': orderId,
          'amount': amountInVND,
          'customer_name': customerName,
          'description': description ?? 'Order payment',
          'currency': 'VND',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('SePay VA created: ${response.data}');
        }

        return SePayVirtualAccount.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to create VA: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating SePay VA: $e');
      }
      throw Exception('Failed to create virtual account: $e');
    }
  }

  /// Check transaction status by order ID
  ///
  /// [orderId] - Order identifier to check payment status
  ///
  /// Returns transaction status and details
  Future<SePayTransaction> checkTransactionStatus(String orderId) async {
    try {
      final accessToken = await _getAccessToken();
      final baseUrl =
          dotenv.env['SEPAY_API_BASE_URL'] ?? 'https://api.sepay.vn';

      final dio = Dio();

      final response = await dio.get(
        '$baseUrl/api/transactions',
        queryParameters: {
          'order_id': orderId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // SePay may return a list or single transaction
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return SePayTransaction.fromJson(data.first as Map<String, dynamic>);
        } else if (data is Map) {
          return SePayTransaction.fromJson(data as Map<String, dynamic>);
        } else {
          throw Exception('No transaction found for order: $orderId');
        }
      } else {
        throw Exception('Failed to check transaction: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking SePay transaction: $e');
      }
      throw Exception('Failed to check transaction status: $e');
    }
  }

  /// Poll transaction status until payment is confirmed or timeout
  ///
  /// [orderId] - Order identifier
  /// [pollInterval] - Time between polls in seconds (default: 5 seconds)
  /// [maxAttempts] - Maximum number of polling attempts (default: 60 = 5 minutes)
  ///
  /// Returns transaction when paid, or null if timeout
  Future<SePayTransaction?> pollPaymentStatus({
    required String orderId,
    int pollInterval = 5,
    int maxAttempts = 60,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        final transaction = await checkTransactionStatus(orderId);

        if (transaction.status == SePayTransactionStatus.paid) {
          if (kDebugMode) {
            print('Payment confirmed for order: $orderId');
          }
          return transaction;
        }

        // Wait before next poll
        await Future.delayed(Duration(seconds: pollInterval));
        attempts++;

        if (kDebugMode && attempts % 12 == 0) {
          print('Polling payment status... Attempt $attempts/$maxAttempts');
        }
      } catch (e) {
        // If transaction not found yet, continue polling
        if (e.toString().contains('No transaction found')) {
          await Future.delayed(Duration(seconds: pollInterval));
          attempts++;
          continue;
        }
        // For other errors, throw
        rethrow;
      }
    }

    if (kDebugMode) {
      print('Payment polling timeout for order: $orderId');
    }
    return null;
  }

  /// Get list of bank accounts
  ///
  /// Returns list of bank accounts configured in SePay
  Future<List<SePayBankAccount>> getBankAccounts() async {
    try {
      final accessToken = await _getAccessToken();
      final baseUrl =
          dotenv.env['SEPAY_API_BASE_URL'] ?? 'https://api.sepay.vn';

      final dio = Dio();

      final response = await dio.get(
        '$baseUrl/api/bank-accounts',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map((json) =>
                  SePayBankAccount.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (data is Map && data['accounts'] != null) {
          return (data['accounts'] as List)
              .map((json) =>
                  SePayBankAccount.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to get bank accounts: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting SePay bank accounts: $e');
      }
      throw Exception('Failed to get bank accounts: $e');
    }
  }

  /// Main payment method - creates VA and waits for payment
  ///
  /// [orderId] - Unique order identifier
  /// [amount] - Payment amount (in VND, or convert from your currency)
  /// [customerName] - Customer name (optional)
  /// [description] - Order description (optional)
  /// [waitForPayment] - Whether to wait for payment confirmation (default: false)
  ///
  /// Returns transaction ID if payment is confirmed, or VA details if waiting
  Future<SePayPaymentResult> makePayment({
    required String orderId,
    required double amount,
    String? customerName,
    String? description,
    bool waitForPayment = false,
  }) async {
    try {
      // Create Virtual Account
      final va = await createVirtualAccount(
        orderId: orderId,
        amount: amount,
        customerName: customerName,
        description: description,
      );

      if (waitForPayment) {
        // Poll for payment confirmation
        final transaction = await pollPaymentStatus(orderId: orderId);

        if (transaction != null &&
            transaction.status == SePayTransactionStatus.paid) {
          return SePayPaymentResult(
            success: true,
            transactionId: transaction.transactionId,
            virtualAccount: va,
            transaction: transaction,
          );
        } else {
          return SePayPaymentResult(
            success: false,
            virtualAccount: va,
            message: 'Payment timeout or not confirmed',
          );
        }
      } else {
        // Return VA details, payment will be checked separately
        return SePayPaymentResult(
          success: true,
          virtualAccount: va,
          message: 'Virtual account created. Waiting for payment.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('SePay payment error: $e');
      }
      throw Exception('Payment failed: $e');
    }
  }
}

/// Virtual Account model
class SePayVirtualAccount {
  final String accountNumber;
  final String bankName;
  final String bankCode;
  final String? qrCode;
  final double amount;
  final String currency;
  final DateTime expiresAt;
  final String orderId;

  SePayVirtualAccount({
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    this.qrCode,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    required this.orderId,
  });

  factory SePayVirtualAccount.fromJson(Map<String, dynamic> json) {
    return SePayVirtualAccount(
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      bankName: json['bank_name'] ?? json['bankName'] ?? '',
      bankCode: json['bank_code'] ?? json['bankCode'] ?? '',
      qrCode: json['qr_code'] ?? json['qrCode'],
      amount:
          (json['amount'] ?? 0).toDouble() / 1000, // Convert from smallest unit
      currency: json['currency'] ?? 'VND',
      expiresAt: DateTime.parse(json['expires_at'] ??
          json['expiresAt'] ??
          DateTime.now().add(Duration(days: 1)).toIso8601String()),
      orderId: json['order_id'] ?? json['orderId'] ?? '',
    );
  }
}

/// Transaction status enum
enum SePayTransactionStatus {
  pending,
  paid,
  failed,
  expired,
  cancelled,
}

/// Transaction model
class SePayTransaction {
  final String transactionId;
  final String orderId;
  final SePayTransactionStatus status;
  final double amount;
  final String currency;
  final DateTime? paidAt;
  final String? payerName;
  final String? payerAccount;
  final String? description;

  SePayTransaction({
    required this.transactionId,
    required this.orderId,
    required this.status,
    required this.amount,
    required this.currency,
    this.paidAt,
    this.payerName,
    this.payerAccount,
    this.description,
  });

  factory SePayTransaction.fromJson(Map<String, dynamic> json) {
    return SePayTransaction(
      transactionId:
          json['transaction_id'] ?? json['transactionId'] ?? json['id'] ?? '',
      orderId: json['order_id'] ?? json['orderId'] ?? '',
      status: _parseStatus(json['status'] ?? 'pending'),
      amount:
          (json['amount'] ?? 0).toDouble() / 1000, // Convert from smallest unit
      currency: json['currency'] ?? 'VND',
      paidAt: json['paid_at'] != null || json['paidAt'] != null
          ? DateTime.parse(json['paid_at'] ?? json['paidAt'])
          : null,
      payerName: json['payer_name'] ?? json['payerName'],
      payerAccount: json['payer_account'] ?? json['payerAccount'],
      description: json['description'],
    );
  }

  static SePayTransactionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'success':
        return SePayTransactionStatus.paid;
      case 'failed':
      case 'error':
        return SePayTransactionStatus.failed;
      case 'expired':
        return SePayTransactionStatus.expired;
      case 'cancelled':
      case 'canceled':
        return SePayTransactionStatus.cancelled;
      default:
        return SePayTransactionStatus.pending;
    }
  }
}

/// Bank Account model
class SePayBankAccount {
  final String accountId;
  final String accountNumber;
  final String bankName;
  final String bankCode;
  final String accountName;
  final double? balance;

  SePayBankAccount({
    required this.accountId,
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    required this.accountName,
    this.balance,
  });

  factory SePayBankAccount.fromJson(Map<String, dynamic> json) {
    return SePayBankAccount(
      accountId: json['account_id'] ?? json['accountId'] ?? json['id'] ?? '',
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      bankName: json['bank_name'] ?? json['bankName'] ?? '',
      bankCode: json['bank_code'] ?? json['bankCode'] ?? '',
      accountName: json['account_name'] ?? json['accountName'] ?? '',
      balance: json['balance'] != null
          ? (json['balance'] as num).toDouble() / 1000
          : null,
    );
  }
}

/// Payment result model
class SePayPaymentResult {
  final bool success;
  final String? transactionId;
  final SePayVirtualAccount? virtualAccount;
  final SePayTransaction? transaction;
  final String? message;

  SePayPaymentResult({
    required this.success,
    this.transactionId,
    this.virtualAccount,
    this.transaction,
    this.message,
  });
}
