import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  Future<String> generateResponse(String userMessage, {String? userId}) async {
    try {
      final isVietnamese = _isVietnamese(userMessage);
      final isGreeting = _isGreeting(userMessage);
      final isStoreQuestion = _isStoreQuestion(userMessage);
      final isProductQuestion = _isProductQuestion(userMessage);

      // Xử lý ngữ cảnh nếu có userId
      final processedMessage =
          userId != null ? _processContext(userMessage, userId) : userMessage;

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

  Future<String> _callGeminiAPI(String prompt) async {
    if (kDebugMode) {
      print('Calling Gemini API...');
    }
    final url = Uri.parse(
        '$_baseUrl/$_model:generateContent?key=${dotenv.env['GEMINI_API_KEY']}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (kDebugMode) {
      print('Gemini API response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Gemini API response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final candidates = jsonResponse['candidates'] as List;
      if (candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        if (parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
    }
    throw Exception(
        'API call failed with status code: ${response.statusCode}, body: ${response.body}');
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
3. KHÔNG đề cập đến website hoặc trang web
4. Nhắc đến các ưu đãi trong ứng dụng
5. Khuyến khích người dùng bật thông báo và đăng ký tài khoản
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
3. DO NOT mention website or web pages
4. Mention in-app promotions
5. Encourage users to enable notifications and register for an account
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
}
