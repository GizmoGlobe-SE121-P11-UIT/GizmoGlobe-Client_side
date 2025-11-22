import 'package:cloud_firestore/cloud_firestore.dart';

import '../../functions/helper.dart';

class AIPromptService {
  /// Create base prompt for AI
  String createBasePrompt(bool isVietnamese) {
    return isVietnamese
        ? '''
Bạn là trợ lý AI của GizmoGlobe, một ứng dụng di động bán linh kiện máy tính.

HƯỚNG DẪN TRẢ LỜI:
1. Trả lời thân thiện, ngắn gọn và chuyên nghiệp
2. Tập trung vào thông tin cần thiết, tránh lặp lại thông tin đã có trong product cards
3. KHÔNG thêm các câu khuyến mãi như "that's a fantastic discount", "amazing deal", "incredible saving"
4. KHÔNG nhắc đến việc đăng ký tài khoản, bật thông báo, hoặc các tính năng khác trong ứng dụng
5. KHÔNG lặp lại thông tin giá và stock nếu đã có trong product cards
6. Giữ câu trả lời ngắn gọn, chỉ cung cấp thông tin bổ sung nếu cần
'''
        : '''
I am the AI assistant of GizmoGlobe, a mobile app for computer parts.

RESPONSE GUIDELINES:
1. Respond in a friendly, concise and professional manner
2. Focus on essential information, avoid repeating information already in product cards
3. DO NOT add promotional phrases like "that's a fantastic discount", "amazing deal", "incredible saving"
4. DO NOT mention account registration, notifications, or other app features
5. DO NOT repeat price and stock information if already shown in product cards
6. Keep responses brief, only provide additional information if needed
''';
  }

  /// Create prompt without products
  String createPromptWithoutProducts(String userMessage, bool isVietnamese) {
    // Check if userMessage contains conversation context
    final hasContext = userMessage.contains('CONVERSATION CONTEXT:');

    if (hasContext) {
      // Context is already included in userMessage, use it directly
      return '${createBasePrompt(isVietnamese)}\n\n$userMessage\n\n${isVietnamese ? 'Trả lời bằng Tiếng Việt:' : 'Reply in English:'}';
    }

    return '${createBasePrompt(isVietnamese)}\n\nCUSTOMER QUESTION: $userMessage\n\n${isVietnamese ? 'Trả lời bằng Tiếng Việt:' : 'Reply in English:'}';
  }

  /// Create general prompt
  String createGeneralPrompt(String userMessage, bool isVietnamese) {
    // Check if userMessage contains conversation context
    final hasContext = userMessage.contains('CONVERSATION CONTEXT:');

    if (hasContext) {
      // Context is already included in userMessage, use it directly
      return '${createBasePrompt(isVietnamese)}\n\n$userMessage\n\n${isVietnamese ? 'Trả lời bằng Tiếng Việt:' : 'Reply in English:'}';
    }

    return '${createBasePrompt(isVietnamese)}\n\nCUSTOMER QUESTION: $userMessage\n\n${isVietnamese ? 'Trả lời bằng Tiếng Việt:' : 'Reply in English:'}';
  }

  /// Create prompt with products
  String createPromptWithProducts(String userMessage,
      List<QueryDocumentSnapshot> products, bool isVietnamese) {
    final formattedProducts = formatProductsInfo(products, isVietnamese);
    final basePrompt = createBasePrompt(isVietnamese);

    // Check if userMessage contains conversation context
    final hasContext = userMessage.contains('CONVERSATION CONTEXT:');

    return isVietnamese
        ? '''
$basePrompt

${hasContext ? '' : 'DANH SÁCH SẢN PHẨM:\n$formattedProducts\n\nHƯỚNG DẪN TRẢ LỜI:\n1. Phân tích yêu cầu của khách hàng\n2. Giới thiệu ngắn gọn các sản phẩm phù hợp\n3. KHÔNG lặp lại thông tin giá, stock, hoặc specs đã có trong product cards\n4. KHÔNG thêm câu khuyến mãi hoặc quảng cáo\n5. Chỉ đề cập đến các sản phẩm có trong danh sách\n\n'}$userMessage

${hasContext ? '\nDANH SÁCH SẢN PHẨM:\n$formattedProducts\n\nHƯỚNG DẪN:\n- Sử dụng ngữ cảnh cuộc trò chuyện để hiểu yêu cầu\n- Giới thiệu ngắn gọn các sản phẩm phù hợp\n- KHÔNG lặp lại thông tin đã có trong product cards\n- KHÔNG thêm câu khuyến mãi\n\n' : ''}Trả lời bằng Tiếng Việt:
'''
        : '''
$basePrompt

${hasContext ? '' : 'PRODUCT LIST:\n$formattedProducts\n\nRESPONSE GUIDELINES:\n1. Analyze customer request\n2. Briefly introduce matching products\n3. DO NOT repeat price, stock, or specs already in product cards\n4. DO NOT add promotional phrases or advertisements\n5. Only mention products from the list\n\n'}$userMessage

${hasContext ? '\nPRODUCT LIST:\n$formattedProducts\n\nGUIDELINES:\n- Use conversation context to understand the request\n- Briefly introduce matching products\n- DO NOT repeat information already in product cards\n- DO NOT add promotional phrases\n\n' : ''}Reply in English:
''';
  }

  /// Create voucher prompt
  String createVoucherPrompt(String basePrompt, String formattedVouchers,
      String userMessage, bool isVietnamese) {
    // Check if userMessage contains conversation context
    final hasContext = userMessage.contains('CONVERSATION CONTEXT:');

    return isVietnamese
        ? '''
$basePrompt

${hasContext ? '' : 'VOUCHER:\n$formattedVouchers\n\n'}$userMessage

${hasContext ? '\nVOUCHER:\n$formattedVouchers\n\nHƯỚNG DẪN:\n- Sử dụng ngữ cảnh cuộc trò chuyện để hiểu yêu cầu của khách hàng\n- Cung cấp thông tin về voucher từ danh sách trên\n\n' : ''}Trả lời bằng Tiếng Việt:
'''
        : '''
$basePrompt

${hasContext ? '' : 'VOUCHERS:\n$formattedVouchers\n\n'}$userMessage

${hasContext ? '\nVOUCHERS:\n$formattedVouchers\n\nGUIDELINES:\n- Use conversation context to understand customer request\n- Provide information about vouchers from the list above\n\n' : ''}Reply in English:
''';
  }

  /// Create user data prompt (favorites, cart, etc.)
  String createUserDataPrompt(String basePrompt, String sectionTitle,
      String content, String userMessage, bool isVietnamese) {
    // Check if userMessage contains conversation context
    final hasContext = userMessage.contains('CONVERSATION CONTEXT:');

    return isVietnamese
        ? '''
$basePrompt

${hasContext ? '' : '$sectionTitle:\n$content\n\n'}$userMessage

${hasContext ? '\n$sectionTitle:\n$content\n\nHƯỚNG DẪN:\n- Sử dụng ngữ cảnh cuộc trò chuyện để hiểu yêu cầu của khách hàng\n- Cung cấp thông tin từ danh sách trên\n\n' : ''}Trả lời bằng Tiếng Việt:
'''
        : '''
$basePrompt

${hasContext ? '' : '$sectionTitle:\n$content\n\n'}$userMessage

${hasContext ? '\n$sectionTitle:\n$content\n\nGUIDELINES:\n- Use conversation context to understand customer request\n- Provide information from the list above\n\n' : ''}Reply in English:
''';
  }

  /// Format products information for AI prompts
  String formatProductsInfo(
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
            '\n   💰 Price: ${formatPriceWithDiscount(data['sellingPrice'], data['discount'])}');

        // Technical specifications by category
        buffer.writeln('\n   📝 Technical Specifications:');
        switch (category) {
          case 'gpu':
            buffer.writeln(
                '      • Series: ${data['series']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Memory: ${formatValue(data['capacity'], 'capacity')}');
            buffer.writeln(
                '      • Bus Width: ${formatValue(data['bus'], 'bus')}');
            buffer.writeln(
                '      • Clock Speed: ${formatValue(data['clockSpeed'], 'clock')}');
            break;
          case 'cpu':
            buffer.writeln(
                '      • Family: ${data['family']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Cores: ${data['core']?.toString() ?? 'N/A'} cores');
            buffer.writeln(
                '      • Threads: ${data['thread']?.toString() ?? 'N/A'} threads');
            buffer.writeln(
                '      • Clock Speed: ${formatValue(data['clockSpeed'], 'clock')}');
            break;
          case 'ram':
            buffer.writeln(
                '      • Type: ${data['ramType']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Capacity: ${formatValue(data['capacity'], 'capacity')}');
            buffer
                .writeln('      • Speed: ${formatValue(data['bus'], 'speed')}');
            break;
          case 'psu':
            buffer.writeln(
                '      • Wattage: ${data['wattage'] != null ? '${data['wattage']}W' : 'N/A'}');
            buffer.writeln(
                '      • Efficiency: ${data['efficiency']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Modular: ${formatValue(data['modular'], 'modular')}');
            break;
          case 'drive':
            buffer
                .writeln('      • Type: ${data['type']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Capacity: ${formatValue(data['capacity'], 'capacity')}');
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
        buffer.writeln('   📦 ${formatValue(data['stock'], 'stock')}');

        // Add product description if available
        if (data['description'] != null) {
          buffer.writeln('\n   📄 Description: ${data['description']}');
        }
        buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        productCount++;
      }
    });

    return buffer.toString();
  }

  // Private helper methods
  String formatValue(dynamic value, String type) {
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
          return Helper.toCurrencyFormat(value);
        }
        if (value is String) {
          final match = RegExp(r'\?(\d+\.?\d*)₫').firstMatch(value);
          if (match != null) {
            return Helper.toCurrencyFormat((match.group(1)!) as num);
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

  String formatPriceWithDiscount(dynamic price, dynamic discount) {
    if (price == null) return 'Price not available';
    if (price is! num) return formatValue(price, 'price');

    if (discount == null || discount == 0) {
      return formatValue(price, 'price');
    }

    // Discount is stored as percentage (0-100), not multiplier (0-1)
    final discountPercent = (discount as num).toDouble();
    final finalPrice = price * (1 - discountPercent / 100);

    return '${formatValue(finalPrice, 'price')} (Original: ${formatValue(price, 'price')})';
  }
}
