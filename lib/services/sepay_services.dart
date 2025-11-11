import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// SePay Services - Payment integration via bank transfer
///
/// This service handles SePay API integration for Vietnamese bank transfer payments.
/// SePay allows businesses to accept payments via bank transfers without payment gateway fees.
///
/// Required setup:
/// 1. Register SePay account and create API Token at: Cấu hình Công ty -> API Access
/// 2. Add SEPAY_API_TOKEN to .env file
/// 3. Optionally add SEPAY_API_BASE_URL to .env file (default: https://my.sepay.vn/userapi)
///
/// Documentation: https://docs.sepay.vn/
class SePayServices {
  SePayServices._();

  static final SePayServices instance = SePayServices._();

  /// Get API Token from environment variables
  /// SePay uses Bearer token authentication (API Token)
  String _getApiToken() {
    try {
      // Check if dotenv is loaded by checking if it has any keys
      if (dotenv.env.isEmpty) {
        throw Exception(
            'Environment variables not loaded. Please restart the app (not hot reload) to load .env file.');
      }

      // Try to get the token and trim any whitespace
      final apiTokenRaw = dotenv.env['SEPAY_API_TOKEN'];
      final apiToken = apiTokenRaw?.trim();

      if (apiToken == null || apiToken.isEmpty) {
        // Debug: Check what keys are available (only when error occurs)
        final allKeys = dotenv.env.keys.toList();
        final sepayKeys =
            allKeys.where((k) => k.toUpperCase().contains('SEPAY')).toList();
        final stripeKeyExists = dotenv.env.containsKey('STRIPE_SECRET_KEY');

        // Provide detailed error message with troubleshooting steps
        final errorMessage = StringBuffer();
        errorMessage.writeln('SePay API Token not found in .env file.');
        errorMessage.writeln('');
        errorMessage.writeln('Troubleshooting steps:');
        errorMessage.writeln('1. Verify SEPAY_API_TOKEN exists in .env file');
        errorMessage.writeln('2. Check that .env file is in project root');
        errorMessage.writeln('3. Verify .env is listed in pubspec.yaml assets');
        errorMessage.writeln(
            '4. IMPORTANT: Fully restart the app (stop and start, not hot reload)');
        errorMessage.writeln(
            '   - On web: Stop the dev server and restart with "flutter run -d chrome"');
        errorMessage.writeln('   - Hot reload does NOT reload .env files');
        errorMessage
            .writeln('5. Get your token from: Cấu hình Công ty -> API Access');
        errorMessage.writeln('');
        errorMessage.writeln('Debug info:');
        errorMessage.writeln('- Total .env keys loaded: ${dotenv.env.length}');
        errorMessage
            .writeln('- SePay keys found: ${sepayKeys.length} ($sepayKeys)');
        errorMessage.writeln(
            '- STRIPE_SECRET_KEY exists: $stripeKeyExists (to verify .env loading)');

        throw Exception(errorMessage.toString());
      }
      return apiToken;
    } catch (e) {
      rethrow;
    }
  }

  /// Get base URL for SePay API
  /// On web, uses Cloud Function proxy to bypass CORS
  String _getBaseUrl() {
    // On web, use Cloud Function proxy to bypass CORS
    if (kIsWeb) {
      final proxy = dotenv.env['SEPAY_PROXY_BASE_URL']?.trim();
      if (proxy != null && proxy.isNotEmpty) {
        return proxy;
      }
      // Default Cloud Function proxy URL (if not configured)
      return 'https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/sepayApiProxy';
    }
    return dotenv.env['SEPAY_API_BASE_URL'] ?? 'https://my.sepay.vn/userapi';
  }

  /// Check if using proxy (Cloud Function)
  bool _isUsingProxy() {
    if (kIsWeb) {
      final baseUrl = _getBaseUrl();
      return baseUrl.contains('cloudfunctions.net');
    }
    return false;
  }

  /// Check if we should use .env directly (skip API call)
  /// Set SEPAY_USE_ENV_ONLY=true in .env to use .env configuration directly
  bool _shouldUseEnvOnly() {
    try {
      final useEnvOnly = dotenv.env['SEPAY_USE_ENV_ONLY']?.trim().toLowerCase();
      return useEnvOnly == 'true' || useEnvOnly == '1';
    } catch (e) {
      return false;
    }
  }

  /// Get list of bank accounts
  ///
  /// Returns list of bank accounts configured in SePay
  /// If SEPAY_USE_ENV_ONLY=true is set in .env, uses .env configuration directly
  Future<List<SePayBankAccount>> getBankAccounts() async {
    // Check if we should use .env directly (skip API call)
    if (_shouldUseEnvOnly()) {
      final defaultAccount = _getDefaultBankAccount();
      if (defaultAccount != null) {
        if (kDebugMode) {
          print(
              'SePay: Using .env configuration directly (SEPAY_USE_ENV_ONLY=true)');
        }
        return [defaultAccount];
      }
      // If SEPAY_USE_ENV_ONLY is set but no default account, return empty
      if (kDebugMode) {
        print(
            'Warning: SEPAY_USE_ENV_ONLY is set but no default bank account configured in .env');
      }
      return [];
    }

    try {
      final baseUrl = _getBaseUrl();
      final dio = Dio();

      Response response;

      if (_isUsingProxy()) {
        // Use Cloud Function proxy (for web to bypass CORS)
        response = await dio.post(
          baseUrl,
          data: {
            'endpoint': 'bank-accounts',
            'method': 'GET',
            'data': {},
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
            validateStatus: (status) {
              // Accept 200, 404, and other status codes without throwing
              return status != null && status < 500;
            },
          ),
        );

        // Handle 404 from proxy - endpoint not available
        if (response.statusCode == 404) {
          // Silently return empty list to allow fallback to .env account
          return [];
        }

        // Proxy returns { success: true/false, data: {...}, error: ... }
        if (response.statusCode == 200 && response.data is Map) {
          final proxyResponse = response.data as Map<String, dynamic>;

          // Check if proxy returned an error (including 404 from underlying API)
          if (proxyResponse['success'] == false) {
            // Check if it's a 404 error - handle silently
            final errorData = proxyResponse['error'];
            if (errorData is Map && errorData['statusCode'] == 404) {
              // Silently return empty list for 404 errors
              return [];
            }
            // Return empty list to allow upstream fallback to .env account
            return [];
          }

          if (proxyResponse['success'] == true &&
              proxyResponse['data'] != null) {
            final data = proxyResponse['data'];
            if (data is Map &&
                data['status'] == 200 &&
                data['bank_accounts'] != null) {
              final accounts = data['bank_accounts'] as List;
              return accounts
                  .map((json) =>
                      SePayBankAccount.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else if (data is Map && data['bank_accounts'] != null) {
              // Some APIs return bank_accounts directly without status wrapper
              final accounts = data['bank_accounts'] as List;
              return accounts
                  .map((json) =>
                      SePayBankAccount.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else if (data is List) {
              return data
                  .map((json) =>
                      SePayBankAccount.fromJson(json as Map<String, dynamic>))
                  .toList();
            }
          }
        }
      } else {
        // Direct API call (for mobile)
        final apiToken = _getApiToken();
        if (kDebugMode) {
          print('SePay: Attempting to get bank accounts from API (mobile)');
          print('SePay: Base URL: $baseUrl');
          final tokenDisplay = apiToken.isNotEmpty
              ? "***${apiToken.substring(apiToken.length - 4)}"
              : "MISSING";
          print('SePay: API Token: $tokenDisplay');
        }

        response = await dio.get(
          '$baseUrl/bank-accounts',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) {
              // Accept 200, 404, and other status codes without throwing
              return status != null && status < 500;
            },
          ),
        );

        if (kDebugMode) {
          print(
              'SePay: Bank accounts API response status: ${response.statusCode}');
        }

        // Handle 404 - endpoint not available
        if (response.statusCode == 404) {
          if (kDebugMode) {
            print(
                'SePay: Bank accounts endpoint returned 404, falling back to .env');
          }
          // Silently return empty list to allow fallback to .env account
          return [];
        }

        if (response.statusCode == 200) {
          final data = response.data;
          if (kDebugMode) {
            print(
                'SePay: Bank accounts API response data type: ${data.runtimeType}');
          }

          if (data is Map &&
              data['status'] == 200 &&
              data['bank_accounts'] != null) {
            final accounts = data['bank_accounts'] as List;
            if (kDebugMode) {
              print('SePay: Found ${accounts.length} bank account(s) from API');
            }
            return accounts
                .map((json) =>
                    SePayBankAccount.fromJson(json as Map<String, dynamic>))
                .toList();
          } else if (data is List) {
            if (kDebugMode) {
              print(
                  'SePay: Found ${data.length} bank account(s) from API (direct list)');
            }
            return data
                .map((json) =>
                    SePayBankAccount.fromJson(json as Map<String, dynamic>))
                .toList();
          } else if (kDebugMode) {
            print('SePay: Unexpected response format: $data');
          }
        } else if (kDebugMode) {
          print(
              'SePay: Bank accounts API returned status ${response.statusCode}: ${response.data}');
        }
      }

      return [];
    } on DioException catch (e) {
      // Handle 404 errors silently - this is expected when endpoint is not available
      if (e.response?.statusCode == 404) {
        if (kDebugMode) {
          print(
              'SePay: Bank accounts API returned 404 (DioException), falling back to .env');
        }
        // Silently return empty list to allow fallback to .env account
        return [];
      }
      // Log other DioException errors
      if (kDebugMode) {
        print('SePay: DioException when getting bank accounts:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Status Code: ${e.response?.statusCode}');
        print('  Response Data: ${e.response?.data}');
        print('  Request Path: ${e.requestOptions.path}');
      }
      return [];
    } catch (e, stackTrace) {
      // Log unexpected errors
      if (kDebugMode) {
        print('SePay: Unexpected error when getting bank accounts: $e');
        print('SePay: Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// Create Virtual Account (VA) for an order using bank account
  ///
  /// SePay creates a unique virtual account for each order using the specified bank account,
  /// allowing automatic payment verification when customer transfers money.
  ///
  /// Note: The exact endpoint may vary based on bank. This implementation uses the BIDV endpoint format.
  /// You may need to adjust the endpoint based on your SePay configuration.
  ///
  /// [orderId] - Unique order identifier (invoice ID)
  /// [amount] - Payment amount in VND (database format: thousands of VND, e.g., 5589.6 = 5,589,600 VND)
  /// [bankAccountId] - Bank account ID from getBankAccounts()
  /// [customerName] - Customer name (optional)
  /// [description] - Order description (optional)
  ///
  /// Returns Virtual Account details including:
  /// - accountNumber: Virtual account number
  /// - bankName: Bank name
  /// - qrCodeUrl: QR code URL for payment
  /// - expiresAt: VA expiration time
  Future<SePayVirtualAccount> createVirtualAccount({
    required String orderId,
    required double amount,
    required String bankAccountId,
    String? customerName,
    String? description,
  }) async {
    try {
      final baseUrl = _getBaseUrl();
      final dio = Dio();

      // Get bank account to determine bank code
      List<SePayBankAccount> bankAccounts = [];

      // If using .env only mode, get default account directly
      if (_shouldUseEnvOnly()) {
        final defaultBankAccount = _getDefaultBankAccount();
        if (defaultBankAccount != null) {
          bankAccounts = [defaultBankAccount];
          if (kDebugMode) {
            print(
                'SePay: Using .env configuration directly for virtual account creation');
          }
        } else {
          throw Exception(
              'SEPAY_USE_ENV_ONLY is set but no default bank account configured.\n'
              'Please set these variables in .env:\n'
              'SEPAY_DEFAULT_ACCOUNT_NUMBER=your_account_number\n'
              'SEPAY_DEFAULT_BANK_NAME=Bank Name\n'
              'SEPAY_DEFAULT_BANK_CODE=VCB\n'
              'SEPAY_DEFAULT_ACCOUNT_NAME=Account Name');
        }
      } else {
        // Try to get bank accounts from API first
        bankAccounts = await getBankAccounts();

        // If no bank accounts from API, try to use default from .env
        if (bankAccounts.isEmpty) {
          final defaultBankAccount = _getDefaultBankAccount();
          if (defaultBankAccount != null) {
            bankAccounts = [defaultBankAccount];
            if (kDebugMode) {
              print(
                  'SePay: API returned no bank accounts, using .env fallback');
            }
          } else {
            throw Exception(
                'No bank accounts available. Cannot create virtual account.\n'
                'Please configure SePay bank accounts or set default bank account in .env:\n'
                'SEPAY_DEFAULT_ACCOUNT_NUMBER=your_account_number\n'
                'SEPAY_DEFAULT_BANK_NAME=Bank Name\n'
                'SEPAY_DEFAULT_BANK_CODE=VCB\n'
                'SEPAY_DEFAULT_ACCOUNT_NAME=Account Name\n\n'
                'Or set SEPAY_USE_ENV_ONLY=true to use .env configuration directly.');
          }
        }
      }

      // At this point, bankAccounts should not be empty
      // Safety check: ensure we have at least one bank account before accessing .first
      if (bankAccounts.isEmpty) {
        throw Exception('No bank accounts available to create virtual account');
      }

      final bankAccount = bankAccounts.firstWhere(
        (acc) => acc.accountId == bankAccountId,
        orElse: () => bankAccounts.first,
      );

      // Convert amount to integer (DB uses thousands → convert to VND)
      final amountInVND = (amount * 1000).round();

      // If using .env only mode, skip API call and use bank account directly
      if (_shouldUseEnvOnly()) {
        if (kDebugMode) {
          print(
              'SePay: Using .env mode - skipping VA API call, using bank account directly');
        }
        // Use bank account number directly (fallback mode)
        return SePayVirtualAccount(
          accountNumber: bankAccount.accountNumber,
          bankName: bankAccount.bankName,
          bankCode: bankAccount.bankCode,
          amount: amountInVND.toDouble(),
          currency: 'VND',
          orderId: orderId,
        );
      }

      // Try to create VA - endpoint format may vary: /bidv/{bank_account_id} or /va/create
      // First, try the VA create endpoint with bank account ID
      try {
        Response response;

        if (_isUsingProxy()) {
          // Use Cloud Function proxy (for web to bypass CORS)
          response = await dio.post(
            baseUrl,
            data: {
              'endpoint': 'va/create',
              'method': 'POST',
              'data': {
                'order_id': orderId,
                'amount': amountInVND.toString(),
                'bank_account_id': bankAccountId,
                'customer_name': customerName ?? '',
                'description': description ?? 'Order payment',
              },
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
              },
            ),
          );

          // Proxy returns { success: true, data: {...} }
          if (response.statusCode == 200 && response.data is Map) {
            final proxyResponse = response.data as Map<String, dynamic>;
            if (proxyResponse['success'] == true &&
                proxyResponse['data'] != null) {
              final responseData = proxyResponse['data'] is Map
                  ? proxyResponse['data'] as Map<String, dynamic>
                  : {'data': proxyResponse['data']};

              return SePayVirtualAccount.fromJson(
                responseData,
                orderId: orderId,
                amount: amountInVND.toDouble(),
              );
            }
          }
        } else {
          // Direct API call (for mobile)
          final apiToken = _getApiToken();
          if (kDebugMode) {
            print('SePay: Creating virtual account via API (mobile)');
            print('SePay: Order ID: $orderId');
            print('SePay: Amount: $amountInVND VND');
            print('SePay: Bank Account ID: $bankAccountId');
          }

          response = await dio.post(
            '$baseUrl/va/create',
            data: {
              'order_id': orderId,
              'amount': amountInVND.toString(),
              'bank_account_id': bankAccountId,
              'customer_name': customerName ?? '',
              'description': description ?? 'Order payment',
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiToken',
                'Content-Type': 'application/json',
              },
            ),
          );

          if (kDebugMode) {
            print(
                'SePay: VA creation API response status: ${response.statusCode}');
            print('SePay: VA creation API response data: ${response.data}');
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = response.data is Map
                ? response.data as Map<String, dynamic>
                : {'data': response.data};

            if (kDebugMode) {
              print('SePay: Virtual account created successfully');
            }

            return SePayVirtualAccount.fromJson(
              responseData,
              orderId: orderId,
              amount: amountInVND.toDouble(),
            );
          } else {
            if (kDebugMode) {
              print(
                  'SePay: VA creation failed with status ${response.statusCode}');
            }
          }
        }
      } catch (e, stackTrace) {
        // VA create endpoint failed, will use fallback
        if (kDebugMode) {
          print('SePay: VA creation API call failed: $e');
          print('SePay: Error type: ${e.runtimeType}');
          if (e is DioException) {
            print('SePay: DioException type: ${e.type}');
            print('SePay: DioException message: ${e.message}');
            print('SePay: DioException status: ${e.response?.statusCode}');
            print('SePay: DioException response: ${e.response?.data}');
          }
          print('SePay: Stack trace: $stackTrace');
          print('SePay: Falling back to direct bank account usage');
        }
      }

      // Fallback: Use bank account number directly (if VA creation not available)
      // In this case, we'll use the bank account number and generate QR code
      // This is a workaround if VA creation endpoint is not available
      if (kDebugMode) {
        print('SePay: Using fallback - bank account directly');
        print('SePay: Account: ${bankAccount.accountNumber}');
        print('SePay: Bank: ${bankAccount.bankName} (${bankAccount.bankCode})');
      }

      return SePayVirtualAccount(
        accountNumber: bankAccount.accountNumber,
        bankName: bankAccount.bankName,
        bankCode: bankAccount.bankCode,
        amount: amountInVND.toDouble(),
        currency: 'VND',
        orderId: orderId,
      );
    } catch (e) {
      throw Exception('Failed to create virtual account: $e');
    }
  }

  /// Generate QR code URL for payment
  ///
  /// [accountNumber] - Bank account number or virtual account number
  /// [bankCode] - Bank code (e.g., VCB, TCB, BIDV)
  /// [amount] - Payment amount in VND
  /// [description] - Payment description (optional)
  /// [orderId] - Order ID to include in transaction content (required for webhook matching)
  ///
  /// Returns QR code image URL
  ///
  /// Note: The description will be formatted as "Order {orderId}" to match webhook pattern:
  /// The webhook looks for pattern: /order[\s:-]*([A-Za-z0-9_-]{6,})/i
  /// This ensures automatic payment detection when user scans QR code or makes manual transfer
  String generateQRCodeUrl({
    required String accountNumber,
    required String bankCode,
    required double amount,
    String? description,
    required String orderId,
  }) {
    // Convert amount to integer VND (DB uses thousands → convert to VND)
    final amountInVND = (amount * 1000).round();

    // Ensure description includes order ID for webhook matching
    // Webhook looks for pattern "Order {orderId}" in transaction content
    // Format: "Order {orderId}" - this matches the regex pattern in webhook: /order[\s:-]*([A-Za-z0-9_-]{6,})/i
    String finalDescription;
    if (orderId.isNotEmpty) {
      // Use format "Order {orderId}" which the webhook recognizes
      // The webhook regex matches: "order" (case insensitive) + optional spaces/colons/dashes + order ID (min 6 chars)
      finalDescription = 'Order $orderId';

      // If custom description is provided, append it after order ID for user clarity
      // But keep "Order {orderId}" at the start for webhook matching
      if (description != null &&
          description.isNotEmpty &&
          description != 'Order payment') {
        // Only append if it's different from the default and doesn't already contain order ID
        if (!description.toLowerCase().contains('order') ||
            !description.contains(orderId)) {
          finalDescription = 'Order $orderId - $description';
        } else {
          // Description already contains order ID, use it as-is if it matches pattern
          finalDescription = description;
        }
      }
    } else {
      // Fallback to provided description or default (should not happen in practice)
      finalDescription = description ?? 'Order payment';
    }

    final descriptionParam = Uri.encodeComponent(finalDescription);

    if (kDebugMode) {
      print('SePay: QR code description: $finalDescription');
      print(
          'SePay: QR code will include orderId: $orderId for webhook matching');
    }

    // SePay VietQR expects bank name at `bank` param per docs:
    // https://docs.sepay.vn/tao-qr-code-vietqr-dong.html
    // Use bank name resolved from bank code for better compatibility.
    final bankNameForQr = Uri.encodeComponent(
      _bankNameFromCode(bankCode),
    );

    // QR code URL format: https://qr.sepay.vn/img?acc={account}&bank={bankName}&amount={amount}&des={description}
    return 'https://qr.sepay.vn/img?acc=$accountNumber&bank=$bankNameForQr&amount=$amountInVND&des=$descriptionParam';
  }

  /// Map common bank codes to display names acceptable by qr.sepay.vn
  String _bankNameFromCode(String bankCode) {
    final code = bankCode.trim().toUpperCase();
    switch (code) {
      case 'VCB':
      case 'VIETCOMBANK':
        return 'Vietcombank';
      case 'BIDV':
        return 'BIDV';
      case 'TCB':
      case 'TECHCOMBANK':
        return 'Techcombank';
      case 'VIB':
      case 'VIETINBANK':
        return 'VietinBank';
      case 'ACB':
        return 'ACB';
      default:
        // Fallback to code itself; qr.sepay.vn may still accept it
        return code;
    }
  }

  /// Get transaction details by transaction ID
  ///
  /// [transactionId] - Transaction ID to get details
  ///
  /// Returns transaction details
  Future<SePayTransaction> getTransactionDetails(String transactionId) async {
    try {
      final baseUrl = _getBaseUrl();
      final dio = Dio();

      Response response;

      if (_isUsingProxy()) {
        // Use Cloud Function proxy (for web to bypass CORS)
        response = await dio.post(
          baseUrl,
          data: {
            'endpoint': 'transactions/details/$transactionId',
            'method': 'GET',
            'data': {},
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        // Proxy returns { success: true, data: {...} }
        if (response.statusCode == 200 && response.data is Map) {
          final proxyResponse = response.data as Map<String, dynamic>;
          if (proxyResponse['success'] == true &&
              proxyResponse['data'] != null) {
            final data = proxyResponse['data'];
            if (data is Map &&
                data['status'] == 200 &&
                data['transaction'] != null) {
              return SePayTransaction.fromJson(
                  data['transaction'] as Map<String, dynamic>);
            } else if (data is Map) {
              return SePayTransaction.fromJson(data as Map<String, dynamic>);
            } else {
              throw Exception('Invalid transaction data format');
            }
          }
        }
      } else {
        // Direct API call (for mobile)
        final apiToken = _getApiToken();
        response = await dio.get(
          '$baseUrl/transactions/details/$transactionId',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map &&
              data['status'] == 200 &&
              data['transaction'] != null) {
            return SePayTransaction.fromJson(
                data['transaction'] as Map<String, dynamic>);
          } else if (data is Map) {
            return SePayTransaction.fromJson(data as Map<String, dynamic>);
          } else {
            throw Exception('Invalid transaction data format');
          }
        }
      }

      throw Exception(
          'Failed to get transaction details: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to get transaction details: $e');
    }
  }

  /// Get transactions list with filters
  ///
  /// [referenceNumber] - Reference number (order ID) to filter transactions
  /// [accountNumber] - Bank account number to filter
  /// [amountIn] - Amount in to filter (exact match)
  /// [limit] - Maximum number of transactions to return (default: 100, max: 5000)
  /// [sinceId] - Get transactions from this ID onwards
  ///
  /// Returns list of transactions
  Future<List<SePayTransaction>> getTransactionsList({
    String? referenceNumber,
    String? accountNumber,
    double? amountIn,
    int limit = 100,
    String? sinceId,
  }) async {
    try {
      final baseUrl = _getBaseUrl();
      final dio = Dio();

      final queryParams = <String, dynamic>{
        'limit': limit > 5000 ? 5000 : limit,
      };

      if (referenceNumber != null && referenceNumber.isNotEmpty) {
        queryParams['reference_number'] = referenceNumber;
      }
      if (accountNumber != null && accountNumber.isNotEmpty) {
        queryParams['account_number'] = accountNumber;
      }
      if (amountIn != null) {
        // Convert to VND for API filter
        queryParams['amount_in'] = (amountIn * 1000).round().toString();
      }
      if (sinceId != null && sinceId.isNotEmpty) {
        queryParams['since_id'] = sinceId;
      }

      Response response;

      if (_isUsingProxy()) {
        // Use Cloud Function proxy (for web to bypass CORS)
        response = await dio.post(
          baseUrl,
          data: {
            'endpoint': 'transactions/list',
            'method': 'GET',
            'data': queryParams,
          },
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        // Proxy returns { success: true, data: {...} }
        if (response.statusCode == 200 && response.data is Map) {
          final proxyResponse = response.data as Map<String, dynamic>;
          if (proxyResponse['success'] == true &&
              proxyResponse['data'] != null) {
            final data = proxyResponse['data'];
            if (data is Map &&
                data['status'] == 200 &&
                data['transactions'] != null) {
              final transactions = data['transactions'] as List;
              return transactions
                  .map((json) =>
                      SePayTransaction.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else if (data is List) {
              return data
                  .map((json) =>
                      SePayTransaction.fromJson(json as Map<String, dynamic>))
                  .toList();
            }
          }
        }
      } else {
        // Direct API call (for mobile)
        final apiToken = _getApiToken();
        response = await dio.get(
          '$baseUrl/transactions/list',
          queryParameters: queryParams,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map &&
              data['status'] == 200 &&
              data['transactions'] != null) {
            final transactions = data['transactions'] as List;
            return transactions
                .map((json) =>
                    SePayTransaction.fromJson(json as Map<String, dynamic>))
                .toList();
          } else if (data is List) {
            return data
                .map((json) =>
                    SePayTransaction.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  /// Check if payment was made for an order by reference number
  ///
  /// [orderId] - Order identifier (reference number) to check payment status
  /// [amount] - Expected payment amount in VND
  ///
  /// Returns transaction if payment found and matches amount, null otherwise
  Future<SePayTransaction?> checkPaymentByOrderId({
    required String orderId,
    required double amount,
  }) async {
    try {
      // Convert to VND for comparison (DB uses thousands)
      final amountInVND = (amount * 1000).round();

      // Get transactions filtered by reference number (order ID) and amount
      final transactions = await getTransactionsList(
        referenceNumber: orderId,
        amountIn: amount,
        limit: 10,
      );

      // Find transaction that matches the order ID and amount
      for (var transaction in transactions) {
        // Check if transaction amount matches (within small tolerance for rounding)
        final transactionAmount = (transaction.amount * 1000).round();
        if (transactionAmount == amountInVND &&
            transaction.referenceNumber == orderId) {
          // Check if transaction is a payment (amount_in > 0)
          if (transaction.amountIn > 0) {
            return transaction;
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking payment by order ID: $e');
      }
      return null;
    }
  }

  /// Poll payment status until payment is confirmed or timeout
  ///
  /// [orderId] - Order identifier (reference number)
  /// [amount] - Expected payment amount in VND
  /// [pollInterval] - Time between polls in seconds (default: 5 seconds)
  /// [maxAttempts] - Maximum number of polling attempts (default: 120 = 10 minutes)
  ///
  /// Returns transaction when paid, or null if timeout
  Future<SePayTransaction?> pollPaymentStatus({
    required String orderId,
    required double amount,
    int pollInterval = 5,
    int maxAttempts = 120,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        final transaction = await checkPaymentByOrderId(
          orderId: orderId,
          amount: amount,
        );

        if (transaction != null) {
          return transaction;
        }

        // Wait before next poll
        await Future.delayed(Duration(seconds: pollInterval));
        attempts++;
      } catch (e) {
        // Continue polling on error
        await Future.delayed(Duration(seconds: pollInterval));
        attempts++;
      }
    }

    return null;
  }

  /// Get default bank account from environment variables (for dev/fallback)
  /// Used when API call fails due to CORS or network issues
  SePayBankAccount? _getDefaultBankAccount() {
    try {
      final accountNumber = dotenv.env['SEPAY_DEFAULT_ACCOUNT_NUMBER']?.trim();
      final bankName =
          dotenv.env['SEPAY_DEFAULT_BANK_NAME']?.trim() ?? 'Vietcombank';
      final bankCode = dotenv.env['SEPAY_DEFAULT_BANK_CODE']?.trim() ?? 'VCB';
      final accountName =
          dotenv.env['SEPAY_DEFAULT_ACCOUNT_NAME']?.trim() ?? 'Default Account';

      if (accountNumber != null && accountNumber.isNotEmpty) {
        return SePayBankAccount(
          accountId: 'default',
          accountNumber: accountNumber,
          bankName: bankName,
          bankCode: bankCode,
          accountName: accountName,
        );
      }
    } catch (e) {
      // Ignore errors when getting default bank account
    }
    return null;
  }

  /// Main payment method - creates VA for payment
  ///
  /// [orderId] - Unique order identifier (invoice ID)
  /// [amount] - Payment amount (database format: thousands of VND, e.g., 5589.6 = 5,589,600 VND)
  /// [bankAccountId] - Bank account ID from getBankAccounts(). If not provided, uses first available account.
  /// [customerName] - Customer name (optional)
  /// [description] - Order description (optional)
  ///
  /// Returns Virtual Account details with QR code URL
  Future<SePayPaymentResult> createPayment({
    required String orderId,
    required double amount,
    String? bankAccountId,
    String? customerName,
    String? description,
  }) async {
    if (kDebugMode) {
      print('SePay: ===== createPayment called =====');
      print('SePay: Order ID: $orderId');
      print('SePay: Amount: $amount (${(amount * 1000).round()} VND)');
      print('SePay: Bank Account ID: $bankAccountId');
      print('SePay: Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('SePay: Using .env only: ${_shouldUseEnvOnly()}');
    }

    try {
      // Try to get bank accounts from API
      List<SePayBankAccount> bankAccounts = [];
      SePayBankAccount? defaultBankAccount;

      // If using .env only mode, get default account directly
      if (_shouldUseEnvOnly()) {
        if (kDebugMode) {
          print('SePay: Using .env only mode');
        }
        defaultBankAccount = _getDefaultBankAccount();
        if (defaultBankAccount != null) {
          bankAccounts = [defaultBankAccount];
          if (kDebugMode) {
            print(
                'SePay: Using .env configuration directly for payment creation');
            print('SePay: Bank Account: ${defaultBankAccount.accountNumber}');
            print(
                'SePay: Bank: ${defaultBankAccount.bankName} (${defaultBankAccount.bankCode})');
          }
        } else {
          final errorMsg =
              'SEPAY_USE_ENV_ONLY is set but no default bank account configured.\n'
              'Please set these variables in .env:\n'
              'SEPAY_DEFAULT_ACCOUNT_NUMBER=your_account_number\n'
              'SEPAY_DEFAULT_BANK_NAME=Bank Name\n'
              'SEPAY_DEFAULT_BANK_CODE=VCB\n'
              'SEPAY_DEFAULT_ACCOUNT_NAME=Account Name';
          if (kDebugMode) {
            print('SePay: ERROR: $errorMsg');
          }
          throw Exception(errorMsg);
        }
      } else {
        if (kDebugMode) {
          print('SePay: Attempting to get bank accounts from API');
        }
        // getBankAccounts() returns [] on errors to allow fallback
        bankAccounts = await getBankAccounts();

        if (bankAccounts.isEmpty) {
          if (kDebugMode) {
            print('SePay: API returned no bank accounts, trying .env fallback');
          }
          // Try to use default bank account from .env as last resort (all platforms, all modes)
          defaultBankAccount = _getDefaultBankAccount();
          if (defaultBankAccount != null) {
            bankAccounts = [defaultBankAccount];
            if (kDebugMode) {
              print('SePay: Using .env fallback bank account');
              print('SePay: Bank Account: ${defaultBankAccount.accountNumber}');
              print(
                  'SePay: Bank: ${defaultBankAccount.bankName} (${defaultBankAccount.bankCode})');
            }
          } else {
            final errorMsg =
                'Cannot connect to SePay API and no default bank account configured.\n'
                'Please set these variables in .env:\n'
                'SEPAY_DEFAULT_ACCOUNT_NUMBER=your_account_number\n'
                'SEPAY_DEFAULT_BANK_NAME=Bank Name\n'
                'SEPAY_DEFAULT_BANK_CODE=VCB\n'
                'SEPAY_DEFAULT_ACCOUNT_NAME=Account Name\n\n'
                'Or set SEPAY_USE_ENV_ONLY=true to use .env configuration directly.';
            if (kDebugMode) {
              print('SePay: ERROR: $errorMsg');
            }
            throw Exception(errorMsg);
          }
        } else {
          if (kDebugMode) {
            print(
                'SePay: Successfully retrieved ${bankAccounts.length} bank account(s) from API');
          }
        }
      }

      // Safety check: ensure we have at least one bank account
      if (bankAccounts.isEmpty) {
        final errorMsg = 'No bank accounts available to process payment';
        if (kDebugMode) {
          print('SePay: ERROR: $errorMsg');
        }
        throw Exception(errorMsg);
      }

      // Use provided bank account ID or default to first account
      final selectedBankAccountId =
          bankAccountId ?? bankAccounts.first.accountId;
      final selectedBankAccount = bankAccounts.firstWhere(
        (acc) => acc.accountId == selectedBankAccountId,
        orElse: () => bankAccounts.first,
      );

      if (kDebugMode) {
        print('SePay: Selected bank account:');
        print('  ID: ${selectedBankAccount.accountId}');
        print('  Number: ${selectedBankAccount.accountNumber}');
        print(
            '  Bank: ${selectedBankAccount.bankName} (${selectedBankAccount.bankCode})');
      }

      // Create Virtual Account (or use fallback)
      SePayVirtualAccount va;
      try {
        if (kDebugMode) {
          print('SePay: Creating virtual account...');
        }
        va = await createVirtualAccount(
          orderId: orderId,
          amount: amount,
          bankAccountId: selectedBankAccountId,
          customerName: customerName,
          description: description,
        );
        if (kDebugMode) {
          print('SePay: Virtual account created successfully');
          print('SePay: VA Account: ${va.accountNumber}');
        }
      } catch (e, stackTrace) {
        // If VA creation fails (e.g., API unavailable), use fallback with bank account directly
        // This fallback works on all platforms when API is unavailable
        if (kDebugMode) {
          print('SePay: VA creation failed with exception: $e');
          print('SePay: Exception type: ${e.runtimeType}');
          print('SePay: Stack trace: $stackTrace');
          print('SePay: Using fallback: bank account directly');
          print(
              'SePay: Fallback enabled (env only: ${_shouldUseEnvOnly()}, debug: $kDebugMode)');
        }

        // Always use fallback on mobile or when .env only mode is enabled
        // On web, only use fallback in debug mode to avoid silent failures in production
        final shouldUseFallback = !kIsWeb || _shouldUseEnvOnly() || kDebugMode;

        if (shouldUseFallback) {
          // Use bank account directly to generate QR code
          final amountInVND = (amount * 1000).round();
          if (kDebugMode) {
            print(
                'SePay: Creating fallback virtual account using bank account directly');
          }
          va = SePayVirtualAccount(
            accountNumber: selectedBankAccount.accountNumber,
            bankName: selectedBankAccount.bankName,
            bankCode: selectedBankAccount.bankCode,
            amount: amountInVND.toDouble(),
            currency: 'VND',
            orderId: orderId,
          );
          if (kDebugMode) {
            print('SePay: Fallback VA created: ${va.accountNumber}');
          }
        } else {
          if (kDebugMode) {
            print('SePay: Fallback not enabled, rethrowing exception');
          }
          rethrow;
        }
      }

      // Generate QR code URL
      // IMPORTANT: Pass orderId to ensure it's included in QR code description
      // This allows webhook to automatically detect payments when user scans QR or makes manual transfer
      if (kDebugMode) {
        print('SePay: Generating QR code URL...');
        print('SePay: Order ID for QR code: ${va.orderId}');
      }
      final qrCodeUrl = generateQRCodeUrl(
        accountNumber: va.accountNumber,
        bankCode: va.bankCode,
        amount: amount,
        description: description,
        orderId: va
            .orderId, // Pass orderId to ensure it's included in QR code description
      );

      // Update VA with QR code URL
      final vaWithQR = va.copyWith(qrCode: qrCodeUrl);

      if (kDebugMode) {
        print('SePay: Payment creation successful');
        print('SePay: QR Code URL: $qrCodeUrl');
        print('SePay: ===== createPayment completed =====');
      }

      return SePayPaymentResult(
        success: true,
        virtualAccount: vaWithQR,
        message: 'Virtual account created. Please scan QR code to pay.',
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('SePay: ===== createPayment FAILED =====');
        print('SePay: Error: $e');
        print('SePay: Error type: ${e.runtimeType}');
        print('SePay: Stack trace: $stackTrace');
      }
      throw Exception('Failed to create payment: $e');
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
  final DateTime? expiresAt;
  final String orderId;
  final String? subAccount;

  SePayVirtualAccount({
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    this.qrCode,
    required this.amount,
    this.currency = 'VND',
    this.expiresAt,
    required this.orderId,
    this.subAccount,
  });

  factory SePayVirtualAccount.fromJson(
    Map<String, dynamic> json, {
    required String orderId,
    required double amount,
  }) {
    // Parse account number - could be in various fields
    final accountNumber = json['account_number'] ??
        json['accountNumber'] ??
        json['sub_account'] ??
        json['subAccount'] ??
        '';

    // Parse bank information
    final bankName = json['bank_name'] ??
        json['bankName'] ??
        json['bank_brand_name'] ??
        json['bankBrandName'] ??
        '';

    final bankCode = json['bank_code'] ??
        json['bankCode'] ??
        extractBankCodeFromName(bankName);

    // Parse expiration date if available
    DateTime? expiresAt;
    if (json['expires_at'] != null || json['expiresAt'] != null) {
      try {
        expiresAt = DateTime.parse(json['expires_at'] ?? json['expiresAt']);
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return SePayVirtualAccount(
      accountNumber: accountNumber,
      bankName: bankName,
      bankCode: bankCode,
      qrCode: json['qr_code'] ?? json['qrCode'],
      amount: amount, // Amount is passed as parameter
      currency: json['currency'] ?? 'VND',
      expiresAt: expiresAt,
      orderId: orderId,
      subAccount: json['sub_account'] ?? json['subAccount'],
    );
  }

  SePayVirtualAccount copyWith({
    String? accountNumber,
    String? bankName,
    String? bankCode,
    String? qrCode,
    double? amount,
    String? currency,
    DateTime? expiresAt,
    String? orderId,
    String? subAccount,
  }) {
    return SePayVirtualAccount(
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      qrCode: qrCode ?? this.qrCode,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      expiresAt: expiresAt ?? this.expiresAt,
      orderId: orderId ?? this.orderId,
      subAccount: subAccount ?? this.subAccount,
    );
  }

  static String extractBankCodeFromName(String bankName) {
    // Extract bank code from bank name
    final name = bankName.toLowerCase();
    if (name.contains('vietcombank') || name.contains('vcb')) {
      return 'VCB';
    } else if (name.contains('bidv')) {
      return 'BIDV';
    } else if (name.contains('techcombank') || name.contains('tcb')) {
      return 'TCB';
    } else if (name.contains('vietinbank') || name.contains('vib')) {
      return 'VIB';
    } else if (name.contains('acb')) {
      return 'ACB';
    }
    return 'VCB'; // Default
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
  final String? orderId;
  final SePayTransactionStatus status;
  final double amount; // Total amount (amount_in - amount_out)
  final double amountIn; // Amount received
  final double amountOut; // Amount sent
  final String currency;
  final DateTime transactionDate;
  final String? payerName;
  final String? payerAccount;
  final String? description;
  final String? referenceNumber;
  final String accountNumber;
  final String? subAccount;
  final String bankBrandName;
  final String bankAccountId;
  final String? transactionContent;
  final String? code;
  final double? accumulated;

  SePayTransaction({
    required this.transactionId,
    this.orderId,
    required this.status,
    required this.amount,
    required this.amountIn,
    required this.amountOut,
    this.currency = 'VND',
    required this.transactionDate,
    this.payerName,
    this.payerAccount,
    this.description,
    this.referenceNumber,
    required this.accountNumber,
    this.subAccount,
    required this.bankBrandName,
    required this.bankAccountId,
    this.transactionContent,
    this.code,
    this.accumulated,
  });

  factory SePayTransaction.fromJson(Map<String, dynamic> json) {
    // Parse transaction ID
    final transactionId = json['id']?.toString() ??
        json['transaction_id']?.toString() ??
        json['transactionId']?.toString() ??
        '';

    // Parse amounts - SePay API returns amounts as strings
    final amountInStr = json['amount_in'] ?? json['amountIn'] ?? '0.00';
    final amountOutStr = json['amount_out'] ?? json['amountOut'] ?? '0.00';
    final amountIn = double.tryParse(amountInStr.toString()) ?? 0.0;
    final amountOut = double.tryParse(amountOutStr.toString()) ?? 0.0;
    final amount = amountIn - amountOut;

    // Parse transaction date
    DateTime transactionDate = DateTime.now();
    if (json['transaction_date'] != null || json['transactionDate'] != null) {
      try {
        transactionDate =
            DateTime.parse(json['transaction_date'] ?? json['transactionDate']);
      } catch (e) {
        // Use current date if parsing fails
      }
    }

    // Determine status based on amount_in
    // If amount_in > 0, payment was received (paid)
    final status = amountIn > 0
        ? SePayTransactionStatus.paid
        : SePayTransactionStatus.pending;

    // Parse reference number (order ID)
    final referenceNumber = json['reference_number'] ??
        json['referenceNumber'] ??
        json['order_id'] ??
        json['orderId'];

    // Extract payer name from transaction content
    String? payerName;
    final transactionContent =
        json['transaction_content'] ?? json['transactionContent'] ?? '';
    if (transactionContent is String && transactionContent.isNotEmpty) {
      // Try to extract payer name from transaction content
      // Format is usually: "NGUYEN VAN A chuyen tien..."
      final parts = transactionContent.split(' ');
      if (parts.isNotEmpty) {
        payerName = parts.take(3).join(' '); // Take first 3 words as name
      }
    }

    return SePayTransaction(
      transactionId: transactionId,
      orderId: referenceNumber,
      status: status,
      amount: amount,
      amountIn: amountIn,
      amountOut: amountOut,
      currency: json['currency'] ?? 'VND',
      transactionDate: transactionDate,
      payerName: payerName ?? json['payer_name'] ?? json['payerName'],
      payerAccount: json['payer_account'] ?? json['payerAccount'],
      description: json['description'] ?? transactionContent,
      referenceNumber: referenceNumber,
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      subAccount: json['sub_account'] ?? json['subAccount'],
      bankBrandName: json['bank_brand_name'] ??
          json['bankBrandName'] ??
          json['bank_name'] ??
          json['bankName'] ??
          '',
      bankAccountId: json['bank_account_id']?.toString() ??
          json['bankAccountId']?.toString() ??
          '',
      transactionContent: transactionContent,
      code: json['code'],
      accumulated: json['accumulated'] != null
          ? double.tryParse(json['accumulated'].toString())
          : null,
    );
  }

  bool get isPaid => status == SePayTransactionStatus.paid && amountIn > 0;
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
    // Parse account ID
    final accountId = json['id']?.toString() ??
        json['account_id']?.toString() ??
        json['bank_account_id']?.toString() ??
        json['accountId']?.toString() ??
        '';

    // Parse bank name and code
    final bankName = json['bank_name'] ??
        json['bankName'] ??
        json['bank_brand_name'] ??
        json['bankBrandName'] ??
        '';

    final bankCode = json['bank_code'] ??
        json['bankCode'] ??
        SePayVirtualAccount.extractBankCodeFromName(bankName);

    // Parse balance if available
    double? balance;
    if (json['balance'] != null) {
      balance = double.tryParse(json['balance'].toString());
    }

    return SePayBankAccount(
      accountId: accountId,
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      bankName: bankName,
      bankCode: bankCode,
      accountName:
          json['account_name'] ?? json['accountName'] ?? json['name'] ?? '',
      balance: balance,
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
