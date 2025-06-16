import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class AIService {
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  final String _model = 'gemini-2.0-flash';
  final FirebaseFirestore _firestore;

  // Định nghĩa các hằng số cho category
  static const Map<String, String> CATEGORY_MAPPING = {
    'cpu': 'cpu',
    'gpu': 'gpu',
    'ram': 'ram',
    'psu': 'psu',
    'drive': 'drive',
    'mainboard': 'mainboard'
  };

  // Lưu trữ lịch sử câu hỏi và câu trả lời
  final Map<String, Map<String, dynamic>> _conversationHistory = {};
  static const Duration _historyExpiration = Duration(days: 1);

  AIService() : _firestore = FirebaseFirestore.instance {
    if (dotenv.env['GEMINI_API_KEY']?.isEmpty ?? true) {
      if (kDebugMode) {
        print('GEMINI_API_KEY is not configured in .env file');
      }
      throw Exception('GEMINI_API_KEY is not configured in .env file');
    }
  }

  // Thêm phương thức để xử lý ngữ cảnh
  String _processContext(String userMessage, String userId) {
    final now = DateTime.now();
    final history = _conversationHistory[userId];

    // Xóa lịch sử cũ nếu có
    if (history != null) {
      final lastInteraction = history['timestamp'] as DateTime;
      if (now.difference(lastInteraction) > _historyExpiration) {
        _conversationHistory.remove(userId);
        return userMessage;
      }

      final lastQuestion = history['question'] as String;
      final lastAnswer = history['answer'] as String;
      return '''
Previous question: $lastQuestion
Previous answer: $lastAnswer
Current question: $userMessage
''';
    }

    return userMessage;
  }

  // Cập nhật lịch sử
  void _updateHistory(String userId, String question, String answer) {
    _conversationHistory[userId] = {
      'question': question,
      'answer': answer,
      'timestamp': DateTime.now(),
    };
  }

  Future<QuerySnapshot> searchProducts(
      {String? category, String? keyword}) async {
    try {
      if (kDebugMode) {
        print(
            'Original search params - category: $category, keyword: $keyword');
      }

      // Chuẩn hóa keyword nếu có
      if (keyword != null) {
        keyword = _normalizeProductName(keyword);
        if (kDebugMode) {
          print('Normalized keyword: $keyword');
        }
      }

      final CollectionReference<Map<String, dynamic>> productsRef =
          _firestore.collection('products');
      var query = productsRef.where('status', isEqualTo: 'active');

      if (category != null) {
        final standardCategory =
            CATEGORY_MAPPING[category.toLowerCase()] ?? category.toLowerCase();
        if (kDebugMode) {
          print('Searching with standardized category: $standardCategory');
        }
        query = query.where('category', isEqualTo: standardCategory);
      }

      if (keyword != null) {
        // Tách từ khóa thành các phần
        final parts = _extractProductParts(keyword);
        if (kDebugMode) {
          print('Extracted product parts: $parts');
        }

        if (parts.isNotEmpty) {
          // Tìm kiếm theo tên sản phẩm chuẩn hóa
          query = query.where('normalizedName', isEqualTo: parts.join(' '));
        } else {
          // Fallback về tìm kiếm cơ bản nếu không tách được
          final lowerKeyword = keyword.toLowerCase();
          query = query
              .where('productName', isGreaterThanOrEqualTo: lowerKeyword)
              .where('productName', isLessThan: '${lowerKeyword}z');
        }
      }

      final result = await query.get();
      if (kDebugMode) {
        print('Found ${result.docs.length} products');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error in searchProducts: $e');
      }
      rethrow;
    }
  }

  String _normalizeProductName(String input) {
    // Loại bỏ các ký tự đặc biệt và khoảng trắng thừa
    var normalized = input.replaceAll(RegExp(r'[^\w\s-]'), ' ').trim();

    final patterns = {
      RegExp(r'(?i)intel\s+'): '',
      RegExp(r'(?i)amd\s+'): '',
      RegExp(r'(?i)cpu\s+'): '',
      RegExp(r'(?i)processor\s+'): '',
      RegExp(r'(?i)core\s+'): '',
      RegExp(r'(?i)ryzen\s+'): 'ryzen-'
    };

    patterns.forEach((pattern, replacement) {
      normalized = normalized.replaceAll(pattern, replacement);
    });

    final iSeriesPattern = RegExp(r'(?i)i([3579])\s*-?\s*(\d+)');
    var matches = iSeriesPattern.allMatches(normalized);
    for (var match in matches) {
      var series = match.group(1);
      var number = match.group(2);
      normalized = normalized.replaceAll(match.group(0)!, 'i$series-$number');
    }

    final rSeriesPattern = RegExp(r'(?i)r([3579])\s+(\d+)');
    matches = rSeriesPattern.allMatches(normalized);
    for (var match in matches) {
      var series = match.group(1);
      var number = match.group(2);
      normalized =
          normalized.replaceAll(match.group(0)!, 'ryzen-$series-$number');
    }

    return normalized.trim().toLowerCase();
  }

  List<String> _extractProductParts(String input) {
    final parts = <String>[];

    // Tách và chuẩn hóa từng phần của tên sản phẩm
    final regex = RegExp(r'(?i)(i[3579]|ryzen\s*[3579]|[0-9]+[a-z]*|[a-z]+)');
    final matches = regex.allMatches(input);

    for (var match in matches) {
      var part = match.group(0)!.toLowerCase();

      // Chuẩn hóa các phần
      if (part.startsWith('i')) {
        parts.add(part); // Giữ nguyên i3/i5/i7/i9
      } else if (part.contains('ryzen')) {
        parts.add('ryzen');
        if (part.contains(RegExp(r'[3579]'))) {
          parts.add(part.replaceAll(RegExp(r'[^3579]'), ''));
        }
      } else if (part.contains(RegExp(r'[0-9]'))) {
        parts.add(part); // Giữ nguyên số model
      }
    }

    return parts;
  }

  bool _isVietnamese(String text) {
    // Danh sách các ký tự đặc trưng của tiếng Việt
    final vietnameseChars = RegExp(
        r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]');
    return vietnameseChars.hasMatch(text.toLowerCase());
  }

  Future<bool> checkFirebaseConnection() async {
    try {
      // Thử kết nối đến Firestore
      await _firestore.collection('products').limit(1).get();
      if (kDebugMode) {
        print('Firebase connection successful');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase connection failed: $e');
      }
      return false;
    }
  }

  bool _isFavoriteQuestion(String message) {
    final favoriteKeywords = {
      'en': ['favorite', 'favourite', 'like', 'save', 'bookmark', 'wishlist'],
      'vi': ['yêu thích', 'thích', 'lưu', 'đánh dấu', 'wishlist']
    };

    final isVietnamese = _isVietnamese(message);
    final keywords = favoriteKeywords[isVietnamese ? 'vi' : 'en']!;
    return keywords.any(
        (keyword) => message.toLowerCase().contains(keyword.toLowerCase()));
  }

  Future<List<Map<String, dynamic>>> _getUserFavorites(String userId) async {
    try {
      final favoriteSnapshot = await _firestore
          .collection('customers')
          .doc(userId)
          .collection('favorites')
          .get();

      final favoriteProductIDs =
          favoriteSnapshot.docs.map((doc) => doc.id).toList();

      if (favoriteProductIDs.isEmpty) {
        return [];
      }

      final productSnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: favoriteProductIDs)
          .get();

      return productSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'productID': doc.id,
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user favorites: $e');
      }
      return [];
    }
  }

  String _formatFavoritesList(
      List<Map<String, dynamic>> favorites, bool isVietnamese) {
    if (favorites.isEmpty) {
      return isVietnamese
          ? 'Bạn chưa có sản phẩm yêu thích nào.'
          : 'You have no favorite products yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln(
        isVietnamese ? '📋 DANH SÁCH YÊU THÍCH:' : '📋 FAVORITE LIST:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    for (var i = 0; i < favorites.length; i++) {
      final product = favorites[i];
      buffer.writeln('\n${i + 1}. ${product['productName']}');
      buffer.writeln(
          '   💰 ${_formatPriceWithDiscount(product['sellingPrice'], product['discount'])}');
      buffer.writeln('   📦 ${_formatValue(product['stock'], 'stock')}');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    return buffer.toString();
  }

  bool _isCartQuestion(String message) {
    final cartKeywords = {
      'en': [
        'cart',
        'shopping cart',
        'basket',
        'my cart',
        'what\'s in my cart',
        'show cart',
        'view cart',
        'cart items',
        'items in cart'
      ],
      'vi': [
        'giỏ hàng',
        'giỏ mua hàng',
        'giỏ của tôi',
        'xem giỏ hàng',
        'sản phẩm trong giỏ',
        'giỏ hàng của tôi',
        'hiển thị giỏ hàng',
        'xem giỏ',
        'giỏ'
      ]
    };

    final lowerMessage = message.toLowerCase();
    return cartKeywords['en']!
            .any((keyword) => lowerMessage.contains(keyword)) ||
        cartKeywords['vi']!.any((keyword) => lowerMessage.contains(keyword));
  }

  Future<List<Map<String, dynamic>>> _getUserCart(String userId) async {
    try {
      print('Fetching cart for user: $userId');
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .collection('carts')
          .get();

      print('Cart snapshot size: ${cartSnapshot.docs.length}');
      if (cartSnapshot.docs.isEmpty) {
        print('No cart items found');
        return [];
      }

      final cartItems = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        print('Cart item data: $data');
        return {
          'productID': data['productID'],
          'quantity': data['quantity'],
          'docId': doc.id,
        };
      }).toList();

      print('Processing ${cartItems.length} cart items');
      final products = await Future.wait(
        cartItems.map((item) async {
          final productID = item['productID'];
          print('Fetching product details for ID: $productID');

          // Try both collections
          var productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productID)
              .get();

          if (!productDoc.exists) {
            print(
                'Product not found in products collection, trying items collection');
            productDoc = await FirebaseFirestore.instance
                .collection('items')
                .doc(productID)
                .get();
          }

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            print('Found product data: $productData');
            return {
              ...productData,
              'quantity': item['quantity'],
              'cartDocId': item['docId'],
            };
          }
          print('Product not found in any collection: $productID');
          return null;
        }),
      );

      final validProducts = products.whereType<Map<String, dynamic>>().toList();
      print('Returning ${validProducts.length} valid products');
      return validProducts;
    } catch (e) {
      print('Error getting user cart: $e');
      return [];
    }
  }

  String _formatCartList(
      List<Map<String, dynamic>> cartItems, bool isVietnamese) {
    if (cartItems.isEmpty) {
      return isVietnamese
          ? 'Giỏ hàng của bạn đang trống.'
          : 'Your cart is empty.';
    }

    final buffer = StringBuffer();
    if (isVietnamese) {
      buffer.writeln('Danh sách sản phẩm trong giỏ hàng:');
      buffer.writeln('----------------------------------------');
      for (var item in cartItems) {
        final name = item['productName'] ?? 'Unknown Product';
        final price = item['sellingPrice'] ?? 0.0;
        final quantity = item['quantity'] ?? 0;
        final total = price * quantity;
        final stock = item['stock'] ?? 0;
        final stockStatus = stock > 0 ? '🟢 Còn hàng' : '🔴 Hết hàng';

        buffer.writeln('📦 $name');
        buffer.writeln('💰 Giá: ${_formatPrice(price)}');
        buffer.writeln('🔢 Số lượng: $quantity');
        buffer.writeln('💵 Tổng: ${_formatPrice(total)}');
        buffer.writeln('📊 $stockStatus');
        buffer.writeln('----------------------------------------');
      }
    } else {
      buffer.writeln('Items in your cart:');
      buffer.writeln('----------------------------------------');
      for (var item in cartItems) {
        final name = item['productName'] ?? 'Unknown Product';
        final price = item['sellingPrice'] ?? 0.0;
        final quantity = item['quantity'] ?? 0;
        final total = price * quantity;
        final stock = item['stock'] ?? 0;
        final stockStatus = stock > 0 ? '🟢 In Stock' : '🔴 Out of Stock';

        buffer.writeln('📦 $name');
        buffer.writeln('💰 Price: ${_formatPrice(price)}');
        buffer.writeln('🔢 Quantity: $quantity');
        buffer.writeln('💵 Total: ${_formatPrice(total)}');
        buffer.writeln('📊 $stockStatus');
        buffer.writeln('----------------------------------------');
      }
    }
    return buffer.toString();
  }

  bool _isInvoiceQuestion(String message) {
    final invoiceKeywords = {
      'en': [
        'invoice',
        'order',
        'purchase',
        'my order',
        'my purchase',
        'order status',
        'invoice status',
        'show invoice',
        'view invoice',
        'check order'
      ],
      'vi': [
        'hóa đơn',
        'đơn hàng',
        'mua hàng',
        'đơn hàng của tôi',
        'mua hàng của tôi',
        'trạng thái đơn hàng',
        'trạng thái hóa đơn',
        'xem hóa đơn',
        'kiểm tra đơn hàng',
        'đơn hàng'
      ]
    };

    final lowerMessage = message.toLowerCase();
    return invoiceKeywords['en']!
            .any((keyword) => lowerMessage.contains(keyword)) ||
        invoiceKeywords['vi']!.any((keyword) => lowerMessage.contains(keyword));
  }

  Future<List<Map<String, dynamic>>> _getUserInvoices(String userId) async {
    try {
      print('Fetching invoices for user: $userId');
      final invoiceSnapshot = await FirebaseFirestore.instance
          .collection('sales_invoices')
          .where('customerID', isEqualTo: userId)
          .get();

      print('Invoice snapshot size: ${invoiceSnapshot.docs.length}');
      if (invoiceSnapshot.docs.isEmpty) {
        print('No invoices found');
        return [];
      }

      final invoices = invoiceSnapshot.docs.map((doc) {
        final data = doc.data();
        print('Invoice data: $data');
        return {
          ...data,
          'docId': doc.id,
        };
      }).toList();

      return invoices;
    } catch (e) {
      print('Error getting user invoices: $e');
      return [];
    }
  }

  String _formatInvoiceList(
      List<Map<String, dynamic>> invoices, bool isVietnamese) {
    if (invoices.isEmpty) {
      return isVietnamese
          ? 'Bạn chưa có hóa đơn nào.'
          : 'You have no invoices.';
    }

    final buffer = StringBuffer();
    if (isVietnamese) {
      buffer.writeln('Danh sách hóa đơn:');
      buffer.writeln('----------------------------------------');
      for (var invoice in invoices) {
        final date = (invoice['date'] as Timestamp).toDate();
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
        final totalPrice = invoice['totalPrice'] ?? 0.0;
        final paymentStatus = invoice['paymentStatus'] ?? 'unknown';
        final salesStatus = invoice['salesStatus'] ?? 'unknown';

        buffer.writeln('📄 Mã hóa đơn: ${invoice['salesInvoiceID']}');
        buffer.writeln('📅 Ngày: $formattedDate');
        buffer.writeln('💰 Tổng tiền: ${_formatPrice(totalPrice)}');
        buffer.writeln(
            '💳 Trạng thái thanh toán: ${_formatStatus(paymentStatus, isVietnamese)}');
        buffer.writeln(
            '📦 Trạng thái đơn hàng: ${_formatStatus(salesStatus, isVietnamese)}');
        buffer.writeln('----------------------------------------');
      }
    } else {
      buffer.writeln('Invoice List:');
      buffer.writeln('----------------------------------------');
      for (var invoice in invoices) {
        final date = (invoice['date'] as Timestamp).toDate();
        final formattedDate = DateFormat('MM/dd/yyyy HH:mm').format(date);
        final totalPrice = invoice['totalPrice'] ?? 0.0;
        final paymentStatus = invoice['paymentStatus'] ?? 'unknown';
        final salesStatus = invoice['salesStatus'] ?? 'unknown';

        buffer.writeln('📄 Invoice ID: ${invoice['salesInvoiceID']}');
        buffer.writeln('📅 Date: $formattedDate');
        buffer.writeln('💰 Total: ${_formatPrice(totalPrice)}');
        buffer.writeln(
            '💳 Payment Status: ${_formatStatus(paymentStatus, isVietnamese)}');
        buffer.writeln(
            '📦 Order Status: ${_formatStatus(salesStatus, isVietnamese)}');
        buffer.writeln('----------------------------------------');
      }
    }
    return buffer.toString();
  }

  String _formatStatus(String status, bool isVietnamese) {
    final statusMap = {
      'paid': {'en': 'Paid', 'vi': 'Đã thanh toán'},
      'pending': {'en': 'Pending', 'vi': 'Đang xử lý'},
      'cancelled': {'en': 'Cancelled', 'vi': 'Đã hủy'},
      'shipped': {'en': 'Shipped', 'vi': 'Đã giao hàng'},
      'delivered': {'en': 'Delivered', 'vi': 'Đã nhận hàng'},
      'unknown': {'en': 'Unknown', 'vi': 'Không xác định'},
    };

    return statusMap[status]?[isVietnamese ? 'vi' : 'en'] ?? status;
  }

  bool _isVoucherQuestion(String message) {
    final voucherKeywords = {
      'en': [
        'voucher',
        'coupon',
        'discount',
        'promotion',
        'offer',
        'deal',
        'sale',
        'show voucher',
        'list voucher',
        'available voucher'
      ],
      'vi': [
        'voucher',
        'mã giảm giá',
        'khuyến mãi',
        'ưu đãi',
        'giảm giá',
        'xem voucher',
        'danh sách voucher',
        'voucher có sẵn',
        'mã khuyến mãi',
        'deal'
      ]
    };

    final lowerMessage = message.toLowerCase();
    return voucherKeywords['en']!
            .any((keyword) => lowerMessage.contains(keyword)) ||
        voucherKeywords['vi']!.any((keyword) => lowerMessage.contains(keyword));
  }

  Future<List<Map<String, dynamic>>> _getVouchers() async {
    try {
      print('Fetching available vouchers');
      final voucherSnapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('isEnabled', isEqualTo: true)
          .where('isVisible', isEqualTo: true)
          .get();

      print('Voucher snapshot size: ${voucherSnapshot.docs.length}');
      if (voucherSnapshot.docs.isEmpty) {
        print('No vouchers found');
        return [];
      }

      final vouchers = voucherSnapshot.docs.map((doc) {
        final data = doc.data();
        print('Voucher data: $data');
        return {
          ...data,
          'docId': doc.id,
        };
      }).toList();

      return vouchers;
    } catch (e) {
      print('Error getting vouchers: $e');
      return [];
    }
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    return DateTime.now(); // fallback
  }

  String _formatVoucherList(
      List<Map<String, dynamic>> vouchers, bool isVietnamese) {
    if (vouchers.isEmpty) {
      return isVietnamese
          ? 'Hiện không có voucher nào khả dụng.'
          : 'No vouchers available at the moment.';
    }

    final buffer = StringBuffer();
    if (isVietnamese) {
      buffer.writeln('Danh sách voucher khả dụng:');
      buffer.writeln('----------------------------------------');
      for (var voucher in vouchers) {
        final name = voucher['voucherName'] ?? 'Unknown Voucher';
        final discountValue = voucher['discountValue'] ?? 0;
        final isPercentage = voucher['isPercentage'] ?? false;
        final minPurchase = voucher['minimumPurchase'] ?? 0;
        final maxDiscount = voucher['maximumDiscountValue'] ?? 0;
        final description =
            voucher['description'] ?? voucher['viDescription'] ?? '';
        final startTime = _parseDate(voucher['startTime']);
        final endTime = _parseDate(voucher['endTime']);

        buffer.writeln('🎟️ $name');
        buffer.writeln(
            '💰 Giảm giá: ${isPercentage ? '$discountValue%' : _formatPrice(discountValue)}');
        buffer.writeln(
            '💵 Áp dụng cho đơn hàng từ: ${_formatPrice(minPurchase)}');
        buffer.writeln('🎯 Giảm tối đa: ${_formatPrice(maxDiscount)}');
        buffer.writeln(
            '📅 Thời gian: ${DateFormat('dd/MM/yyyy').format(startTime)} - ${DateFormat('dd/MM/yyyy').format(endTime)}');
        buffer.writeln('📝 $description');
        buffer.writeln('----------------------------------------');
      }
    } else {
      buffer.writeln('Available Vouchers:');
      buffer.writeln('----------------------------------------');
      for (var voucher in vouchers) {
        final name = voucher['voucherName'] ?? 'Unknown Voucher';
        final discountValue = voucher['discountValue'] ?? 0;
        final isPercentage = voucher['isPercentage'] ?? false;
        final minPurchase = voucher['minimumPurchase'] ?? 0;
        final maxDiscount = voucher['maximumDiscountValue'] ?? 0;
        final description =
            voucher['description'] ?? voucher['enDescription'] ?? '';
        final startTime = _parseDate(voucher['startTime']);
        final endTime = _parseDate(voucher['endTime']);

        buffer.writeln('🎟️ $name');
        buffer.writeln(
            '💰 Discount: ${isPercentage ? '$discountValue%' : _formatPrice(discountValue)}');
        buffer
            .writeln('💵 Apply for orders from: ${_formatPrice(minPurchase)}');
        buffer.writeln('🎯 Maximum discount: ${_formatPrice(maxDiscount)}');
        buffer.writeln(
            '📅 Valid: ${DateFormat('MM/dd/yyyy').format(startTime)} - ${DateFormat('MM/dd/yyyy').format(endTime)}');
        buffer.writeln('📝 $description');
        buffer.writeln('----------------------------------------');
      }
    }
    return buffer.toString();
  }

  Future<String> generateResponse(String userMessage, {String? userId}) async {
    try {
      final isVietnamese = _isVietnamese(userMessage);
      final isGreeting = _isGreeting(userMessage);
      final isStoreQuestion = _isStoreQuestion(userMessage);
      final isProductQuestion = _isProductQuestion(userMessage);
      final isFavoriteQuestion = _isFavoriteQuestion(userMessage);
      final isCartQuestion = _isCartQuestion(userMessage);
      final isInvoiceQuestion = _isInvoiceQuestion(userMessage);
      final isVoucherQuestion = _isVoucherQuestion(userMessage);

      // Xử lý ngữ cảnh nếu có userId
      final processedMessage =
          userId != null ? _processContext(userMessage, userId) : userMessage;

      // Nếu là câu hỏi về voucher
      if (isVoucherQuestion) {
        try {
          final vouchers = await _getVouchers();
          final formattedVouchers = _formatVoucherList(vouchers, isVietnamese);
          final basePrompt = _createBasePrompt(isVietnamese);

          final prompt = isVietnamese
              ? '''
$basePrompt

VOUCHER:
$formattedVouchers

CÂU HỎI CỦA KHÁCH HÀNG: $userMessage

Trả lời bằng Tiếng Việt:
'''
              : '''
$basePrompt

VOUCHERS:
$formattedVouchers

CUSTOMER QUESTION: $userMessage

Reply in English:
''';

          final response = await _callGeminiAPI(prompt);
          if (userId != null) {
            _updateHistory(userId, userMessage, response);
          }
          return response;
        } catch (e) {
          print('Error handling voucher question: $e');
          return isVietnamese
              ? 'Xin lỗi, có lỗi xảy ra khi xử lý yêu cầu của bạn. Vui lòng thử lại sau.'
              : 'Sorry, an error occurred while processing your request. Please try again later.';
        }
      }

      // Nếu là câu hỏi về sản phẩm yêu thích hoặc giỏ hàng
      if (isFavoriteQuestion || isCartQuestion) {
        if (userId == null) {
          return isVietnamese
              ? 'Vui lòng đăng nhập để xem ${isFavoriteQuestion ? "danh sách sản phẩm yêu thích" : "giỏ hàng"} của bạn.'
              : 'Please log in to view your ${isFavoriteQuestion ? "favorite products" : "cart"}.';
        }

        final basePrompt = _createBasePrompt(isVietnamese);
        String content = '';
        String sectionTitle = '';

        if (isFavoriteQuestion) {
          final favorites = await _getUserFavorites(userId);
          content = _formatFavoritesList(favorites, isVietnamese);
          sectionTitle = isVietnamese
              ? 'DANH SÁCH SẢN PHẨM YÊU THÍCH'
              : 'FAVORITE PRODUCTS';
        }

        if (isCartQuestion) {
          final cartItems = await _getUserCart(userId);
          content = _formatCartList(cartItems, isVietnamese);
          sectionTitle = isVietnamese ? 'GIỎ HÀNG' : 'CART CONTENTS';
        }

        final prompt = isVietnamese
            ? '''
$basePrompt

$sectionTitle:
$content

CÂU HỎI CỦA KHÁCH HÀNG: $userMessage

Trả lời bằng Tiếng Việt:
'''
            : '''
$basePrompt

$sectionTitle:
$content

CUSTOMER QUESTION: $userMessage

Reply in English:
''';

        final response = await _callGeminiAPI(prompt);
        if (userId != null) {
          _updateHistory(userId, userMessage, response);
        }
        return response;
      }

      // Nếu là câu hỏi về sản phẩm, cần kiểm tra kết nối Firebase và sản phẩm
      if (isProductQuestion) {
        final isConnected = await checkFirebaseConnection();
        if (!isConnected) {
          return isVietnamese
              ? 'Xin lỗi, không thể kết nối đến cơ sở dữ liệu. Vui lòng kiểm tra kết nối mạng và thử lại.'
              : 'Sorry, unable to connect to the database. Please check your network connection and try again.';
        }

        // Tìm kiếm sản phẩm dựa trên phân tích câu hỏi
        final category = _detectProductCategory(processedMessage);
        final keywords = _extractSearchKeywords(processedMessage);
        if (kDebugMode) {
          print('Detected category: $category');
        }
        if (kDebugMode) {
          print('Extracted keywords: $keywords');
        }

        QuerySnapshot? productsSnapshot;
        if (category != null) {
          productsSnapshot = await searchProducts(category: category);
          if (kDebugMode) {
            print(
                'Found ${productsSnapshot.docs.length} products in category $category');
          }
        } else if (keywords.isNotEmpty) {
          // Thử tìm với từ khóa đầu tiên
          productsSnapshot = await searchProducts(keyword: keywords.first);
          if (kDebugMode) {
            print(
                'Found ${productsSnapshot.docs.length} products with keyword ${keywords.first}');
          }
        } else {
          // Nếu không có category và keyword, tìm tất cả sản phẩm available
          productsSnapshot = await searchProducts();
          if (kDebugMode) {
            print(
                'Found ${productsSnapshot.docs.length} total available products');
          }
        }

        if (productsSnapshot.docs.isEmpty) {
          return isVietnamese
              ? 'Xin lỗi, hiện tại chưa có sản phẩm nào phù hợp với yêu cầu của bạn. Tuy nhiên, chúng tôi sẽ sớm cập nhật thêm sản phẩm mới. Bạn có thể để lại thông tin liên hệ để được thông báo khi có sản phẩm mới.'
              : 'Sorry, there are currently no products matching your requirements. However, we will be updating with new products soon. You can leave your contact information to be notified when new products arrive.';
        }

        final prompt = _createPromptWithProducts(
            processedMessage, productsSnapshot, isVietnamese);
        final response = await _callGeminiAPI(prompt);

        // Cập nhật lịch sử nếu có userId
        if (userId != null) {
          _updateHistory(userId, userMessage, response);
        }

        return response;
      }

      // Với câu chào hoặc câu hỏi về cửa hàng
      if (isGreeting || isStoreQuestion) {
        final prompt =
            _createPromptWithoutProducts(processedMessage, isVietnamese);
        final response = await _callGeminiAPI(prompt);

        // Cập nhật lịch sử nếu có userId
        if (userId != null) {
          _updateHistory(userId, userMessage, response);
        }

        return response;
      }

      // Với các câu hỏi chung khác
      final prompt = _createGeneralPrompt(processedMessage, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      // Cập nhật lịch sử nếu có userId
      if (userId != null) {
        _updateHistory(userId, userMessage, response);
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in generateResponse: $e');
      }
      return _isVietnamese(userMessage)
          ? 'Xin lỗi, hiện tại tôi không thể xử lý yêu cầu của bạn. Vui lòng thử lại sau.'
          : 'Sorry, I cannot process your request at the moment. Please try again later.';
    }
  }

  bool _isGreeting(String message) {
    final greetings = {
      'hi',
      'hello',
      'hey',
      'chào',
      'xin chào',
      'alo',
      'good morning',
      'good afternoon',
      'good evening',
      'chào buổi sáng',
      'chào buổi chiều',
      'chào buổi tối'
    };

    return greetings.any((greeting) =>
        message.toLowerCase().trim().contains(greeting.toLowerCase()));
  }

  bool _isStoreQuestion(String message) {
    final storeKeywords = {
      'store',
      'shop',
      'business',
      'company',
      'about',
      'contact',
      'warranty',
      'support',
      'service',
      'location',
      'address',
      'cửa hàng',
      'địa chỉ',
      'liên hệ',
      'bảo hành',
      'hỗ trợ',
      'dịch vụ',
      'về',
      'giới thiệu'
    };

    return storeKeywords.any((keyword) =>
        message.toLowerCase().trim().contains(keyword.toLowerCase()));
  }

  bool _isProductQuestion(String message) {
    final productKeywords = {
      'cpu': ['cpu', 'processor', 'core i', 'ryzen', 'intel', 'amd'],
      'gpu': ['gpu', 'graphics', 'card', 'vga', 'rtx', 'gtx', 'radeon'],
      'ram': ['ram', 'memory', 'ddr', 'dimm', 'kingston', 'corsair'],
      'psu': ['psu', 'power supply', 'nguồn'],
      'drive': ['ssd', 'hdd', 'nvme', 'storage', 'ổ cứng', 'samsung'],
      'mainboard': [
        'mainboard',
        'motherboard',
        'bo mạch',
        'asus',
        'msi',
        'gigabyte'
      ]
    };

    final lowercaseMessage = message.toLowerCase();
    return productKeywords.values.any((keywords) => keywords
        .any((keyword) => lowercaseMessage.contains(keyword.toLowerCase())));
  }

  String _createPromptWithoutProducts(String userMessage, bool isVietnamese) {
    return '${_createBasePrompt(isVietnamese)}\n\nCUSTOMER QUESTION: $userMessage\n\n${isVietnamese ? 'Trả lời bằng Tiếng Việt:' : 'Reply in English:'}';
  }

  String _createGeneralPrompt(String userMessage, bool isVietnamese) {
    return '${_createBasePrompt(isVietnamese)}\n\nCUSTOMER QUESTION: $userMessage\n\n${isVietnamese ? 'Trả lời bằng Tiếng Việt:' : 'Reply in English:'}';
  }

  Future<String> _callGeminiAPI(String prompt, {int maxRetries = 3}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        print('Calling Gemini API... (Attempt ${retryCount + 1}/$maxRetries)');
        final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 1,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            }
          }),
        );

        print('Gemini API response status: ${response.statusCode}');
        print('Gemini API response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final candidates = responseData['candidates'] as List;
          if (candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List;
            if (parts.isNotEmpty) {
              return parts[0]['text'] as String;
            }
          }
          throw Exception('No valid response from Gemini API');
        } else if (response.statusCode == 503) {
          retryCount++;
          if (retryCount < maxRetries) {
            print('Model overloaded, retrying in ${retryCount * 2} seconds...');
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          }
        }
        throw Exception(
            'API call failed with status code: ${response.statusCode}, body: ${response.body}');
      } catch (e) {
        print('Error calling Gemini API: $e');
        retryCount++;
        if (retryCount < maxRetries) {
          print('Retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        rethrow;
      }
    }
    throw Exception(
        'Failed to get response from Gemini API after $maxRetries attempts');
  }

  String _createPromptWithProducts(
      String userMessage, QuerySnapshot productsSnapshot, bool isVietnamese) {
    final formattedProducts =
        _formatProductsInfo(productsSnapshot.docs, isVietnamese);
    final basePrompt = _createBasePrompt(isVietnamese);

    return isVietnamese
        ? '''
$basePrompt

DANH SÁCH SẢN PHẨM:
$formattedProducts

HƯỚNG DẪN TRẢ LỜI:
1. Phân tích yêu cầu của khách hàng
2. Cung cấp thông tin chi tiết về sản phẩm
3. Đề xuất sản phẩm phù hợp
4. Hướng dẫn mua hàng trong ứng dụng
5. LUÔN đề cập đến giá và tình trạng hàng

CÂU HỎI CỦA KHÁCH HÀNG: $userMessage

Trả lời bằng Tiếng Việt:
'''
        : '''
$basePrompt

PRODUCT LIST:
$formattedProducts

RESPONSE GUIDELINES:
1. Analyze customer request
2. Provide detailed product information
3. Suggest suitable products
4. Guide in-app purchase
5. ALWAYS mention price and stock availability

CUSTOMER QUESTION: $userMessage

Reply in English:
''';
  }

  String _createBasePrompt(bool isVietnamese) {
    return isVietnamese
        ? '''
Bạn là trợ lý AI của GizmoGlobe, một ứng dụng di động bán linh kiện máy tính.

THÔNG TIN VỀ GIZMOGLOBE:
- Ứng dụng di động chuyên về linh kiện máy tính
- Cam kết chất lượng và giá cả cạnh tranh
- Đội ngũ tư vấn chuyên nghiệp
- Chính sách bảo hành và hỗ trợ sau bán hàng tốt
- Nhiều ưu đãi và khuyến mãi hấp dẫn

HƯỚNG DẪN TRẢ LỜI:
1. Trả lời thân thiện và chuyên nghiệp
2. Hướng dẫn người dùng sử dụng các tính năng trong ứng dụng
3. Nhắc đến các ưu đãi trong ứng dụng
4. Khuyến khích người dùng bật thông báo và đăng ký tài khoản
5. Tránh nhắc đến các nền tảng khác.
'''
        : '''
I am the AI assistant of GizmoGlobe, a mobile app for computer parts.

ABOUT GIZMOGLOBE:
- Mobile app specializing in computer parts
- Committed to quality and competitive pricing
- Professional consulting team
- Excellent warranty and after-sales support
- Attractive promotions and discounts

RESPONSE GUIDELINES:
1. Respond in a friendly and professional manner
2. Guide users on app features
3. Mention in-app promotions
4. Encourage users to enable notifications and register for an account
5. Avoid mentioning other platforms.
''';
  }

  String? _detectProductCategory(String message) {
    final categoryKeywords = {
      'cpu': ['cpu', 'processor', 'core i', 'ryzen', 'intel', 'amd'],
      'gpu': ['gpu', 'graphics', 'rtx', 'gtx', 'radeon', 'vga'],
      'ram': ['ram', 'memory', 'ddr', 'dimm'],
      'psu': ['psu', 'power', 'nguồn', 'power supply'],
      'drive': ['ssd', 'hdd', 'nvme', 'storage', 'ổ cứng'],
      'mainboard': ['mainboard', 'motherboard', 'bo mạch']
    };

    final lowercaseMessage = message.toLowerCase();
    for (var entry in categoryKeywords.entries) {
      if (entry.value
          .any((keyword) => lowercaseMessage.contains(keyword.toLowerCase()))) {
        if (kDebugMode) {
          print(
              'Detected category: ${entry.key} from keywords: ${entry.value}');
        }
        return entry.key;
      }
    }
    return null;
  }

  List<String> _extractSearchKeywords(String message) {
    final stopWords = {
      'what',
      'is',
      'the',
      'price',
      'of',
      'how',
      'much',
      'can',
      'you',
      'tell',
      'me',
      'about',
      'tôi',
      'muốn',
      'tìm',
      'giá',
      'của',
      'cho',
      'biết',
      'về'
    };

    return message
        .toLowerCase()
        .split(' ')
        .where((word) => !stopWords.contains(word) && word.length > 2)
        .toList();
  }

  String _formatProductsInfo(
      List<QueryDocumentSnapshot> products, bool isVietnamese) {
    final buffer = StringBuffer();
    final Map<String, List<Map<String, dynamic>>> groupedProducts = {};

    for (final doc in products) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category']?.toString() ?? 'unknown';
      if (!groupedProducts.containsKey(category)) {
        groupedProducts[category] = [];
      }
      groupedProducts[category]!.add({...data, 'id': doc.id});
    }

    var productCount = 1;
    groupedProducts.forEach((category, productList) {
      buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln(isVietnamese
          ? '📂 [DANH MỤC: ${category.toUpperCase()}]'
          : '📂 [CATEGORY: ${category.toUpperCase()}]');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      for (final data in productList) {
        final productName = data['productName'] ?? 'Unknown Product';
        buffer.writeln('$productCount. 🏷️ [PRODUCT_NAME:$productName]');
        buffer.writeln(
            '\n   💰 Price: ${_formatPriceWithDiscount(data['sellingPrice'], data['discount'])}');

        // Thông số kỹ thuật theo category
        buffer.writeln('\n   📝 Technical Specifications:');
        switch (category) {
          case 'gpu':
            buffer.writeln(
                '      • Series: ${data['series']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Memory: ${_formatValue(data['capacity'], 'capacity')}');
            buffer.writeln(
                '      • Bus Width: ${_formatValue(data['bus'], 'bus')}');
            buffer.writeln(
                '      • Clock Speed: ${_formatValue(data['clockSpeed'], 'clock')}');
            break;
          case 'cpu':
            buffer.writeln(
                '      • Family: ${data['family']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Cores: ${data['core']?.toString() ?? 'N/A'} cores');
            buffer.writeln(
                '      • Threads: ${data['thread']?.toString() ?? 'N/A'} threads');
            buffer.writeln(
                '      • Clock Speed: ${_formatValue(data['clockSpeed'], 'clock')}');
            break;
          case 'ram':
            buffer.writeln(
                '      • Type: ${data['ramType']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Capacity: ${_formatValue(data['capacity'], 'capacity')}');
            buffer.writeln(
                '      • Speed: ${_formatValue(data['bus'], 'speed')}');
            break;
          case 'psu':
            buffer.writeln(
                '      • Wattage: ${data['wattage'] != null ? '${data['wattage']}W' : 'N/A'}');
            buffer.writeln(
                '      • Efficiency: ${data['efficiency']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Modular: ${_formatValue(data['modular'], 'modular')}');
          case 'drive':
            buffer
                .writeln('      • Type: ${data['type']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Capacity: ${_formatValue(data['capacity'], 'capacity')}');
            break;
          case 'mainboard':
            buffer.writeln(
                '      • Form Factor: ${data['formFactor']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Series: ${data['series']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Compatibility: ${data['compatibility']?.toString() ?? 'N/A'}');
            break;
        }

        buffer.writeln(
            '\n   🏭 Manufacturer: ${data['manufacturerID'] ?? 'N/A'}');
        buffer.writeln('   📦 ${_formatValue(data['stock'], 'stock')}');

        // Thêm mô tả sản phẩm nếu có
        if (data['description'] != null) {
          buffer.writeln('\n   📄 Description: ${data['description']}');
        }
        buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        productCount++;
      }
    });

    if (products.isNotEmpty && products.length > 1) {
      buffer.writeln('\n📊 [SO SÁNH VÀ ĐỀ XUẤT]\n');

      // Phân tích và so sánh các thuộc tính chính
      final firstProduct = products.first.data() as Map<String, dynamic>;
      if (firstProduct['category'] == 'ram') {
        final rams = products.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {...data, 'id': doc.id};
        }).toList();

        // So sánh Type
        buffer.writeln('🔹 Type:');
        for (var i = 0; i < rams.length; i++) {
          final productName = rams[i]['productName'] ?? 'Unknown Product';
          buffer.writeln('${i + 1}. [PRODUCT_NAME:$productName]');
          buffer.writeln(
              '   • ${rams[i]['ramType']?.toString().toUpperCase() ?? 'N/A'}');
        }
        buffer.writeln();

        // So sánh Capacity
        buffer.writeln('🔹 Capacity:');
        for (var i = 0; i < rams.length; i++) {
          final productName = rams[i]['productName'] ?? 'Unknown Product';
          buffer.writeln('${i + 1}. [PRODUCT_NAME:$productName]');
          buffer
              .writeln('   • ${_formatValue(rams[i]['capacity'], 'capacity')}');
        }
        buffer.writeln();

        // So sánh Speed
        buffer.writeln('🔹 Speed:');
        for (var i = 0; i < rams.length; i++) {
          final productName = rams[i]['productName'] ?? 'Unknown Product';
          buffer.writeln('${i + 1}. [PRODUCT_NAME:$productName]');
          buffer.writeln('   • ${_formatValue(rams[i]['bus'], 'speed')}');
        }
        buffer.writeln();

        // So sánh Price
        buffer.writeln('🔹 Price:');
        for (var i = 0; i < rams.length; i++) {
          final productName = rams[i]['productName'] ?? 'Unknown Product';
          buffer.writeln('${i + 1}. [PRODUCT_NAME:$productName]');
          buffer.writeln(
              '   • ${_formatPriceWithDiscount(rams[i]['sellingPrice'], rams[i]['discount'])}');
        }
        buffer.writeln();

        // So sánh Stock
        buffer.writeln('🔹 Stock:');
        for (var i = 0; i < rams.length; i++) {
          final productName = rams[i]['productName'] ?? 'Unknown Product';
          buffer.writeln('${i + 1}. [PRODUCT_NAME:$productName]');
          buffer.writeln('   • ${_formatValue(rams[i]['stock'], 'stock')}');
        }
        buffer.writeln();

        // Thêm ghi chú về đặc điểm của từng sản phẩm
        buffer.writeln('📝 Notes:');
        for (var i = 0; i < rams.length; i++) {
          final productName = rams[i]['productName'] ?? 'Unknown Product';
          buffer.writeln('${i + 1}. [PRODUCT_NAME:$productName]');
          if (rams[i]['capacity'] == 'gb16') {
            buffer.writeln('   • Suitable for basic to mid-range systems.');
          } else if (rams[i]['capacity'] == 'gb32') {
            buffer.writeln(
                '   • Good balance of capacity and speed, ideal for gaming and content creation.');
          } else if (rams[i]['capacity'] == 'gb64') {
            buffer.writeln(
                '   • Best for demanding tasks like video editing and running virtual machines.');
          } else if (rams[i]['capacity'] == 'gb8') {
            buffer.writeln(
                '   • Entry-level option, suitable for basic computing needs.');
          }
        }
        buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }
    }

    return buffer.toString();
  }

  String _formatValue(dynamic value, String type) {
    if (value == null) return 'N/A';

    switch (type) {
      case 'capacity':
        if (value is String) {
          final match = RegExp(r'([a-zA-Z]+)(\d+)').firstMatch(value);
          if (match != null) {
            final unit = match.group(1)!.toUpperCase();
            final number = match.group(2);
            return '$number $unit';
          }
        }
        return value.toString().toUpperCase();
      case 'speed':
        if (value is num) {
          return '${value.toStringAsFixed(0)} MB/s';
        }
        return '${value.toString()} MB/s';
      case 'clock':
        if (value is num) {
          return '${value.toStringAsFixed(1)} GHz';
        }
        if (value is String) {
          final numericValue = double.tryParse(value);
          if (numericValue != null) {
            return '${numericValue.toStringAsFixed(1)} GHz';
          }
        }
        return value.toString();
      case 'price':
        if (value is num) {
          return '\$${value.toStringAsFixed(2)}';
        }
        if (value is String) {
          final match = RegExp(r'\$?(\d+\.?\d*)').firstMatch(value);
          if (match != null) {
            final numericPrice = double.tryParse(match.group(1)!);
            if (numericPrice != null) {
              return numericPrice.toStringAsFixed(2);
            }
          }
        }
        return 'Price not available';
      case 'stock':
        if (value is num) {
          final stock = value as int;
          return stock > 0 ? 'In Stock ($stock units)' : 'Out of Stock';
        }
        return 'Stock status unknown';
      case 'warranty':
        if (value is num) {
          final months = value as int;
          if (months >= 12) {
            final years = months ~/ 12;
            final remainingMonths = months % 12;
            if (remainingMonths == 0) {
              return '$years year${years > 1 ? 's' : ''}';
            }
            return '$years year${years > 1 ? 's' : ''} and $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
          }
          return '$months months';
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  String _formatPriceWithDiscount(dynamic price, dynamic discount) {
    if (price == null) return 'Price not available';
    if (price is! num) return _formatValue(price, 'price');

    if (discount == null || discount == 0) {
      return _formatValue(price, 'price');
    }

    final discountAmount = price * (discount as num);
    final finalPrice = price - discountAmount;

    return '${_formatValue(finalPrice, 'price')} (Original: ${_formatValue(price, 'price')})';
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(price);
  }
}
