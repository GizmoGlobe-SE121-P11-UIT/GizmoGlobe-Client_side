import 'package:cloud_firestore/cloud_firestore.dart';

import '../../functions/helper.dart';

class AIPromptService {
  /// Create base prompt for AI
  String createBasePrompt(bool isVietnamese) {
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

${hasContext ? '' : 'DANH SÁCH SẢN PHẨM:\n$formattedProducts\n\nHƯỚNG DẪN TRẢ LỜI:\n1. Phân tích yêu cầu của khách hàng\n2. Cung cấp thông tin chi tiết về sản phẩm\n3. Đề xuất sản phẩm phù hợp\n4. Hướng dẫn mua hàng trong ứng dụng\n5. LUÔN đề cập đến giá và tình trạng hàng\n\n'}$userMessage

${hasContext ? '\nDANH SÁCH SẢN PHẨM:\n$formattedProducts\n\nHƯỚNG DẪN:\n- Sử dụng ngữ cảnh cuộc trò chuyện để hiểu yêu cầu của khách hàng\n- Cung cấp thông tin chi tiết về sản phẩm từ danh sách trên\n- LUÔN đề cập đến giá và tình trạng hàng\n\n' : ''}Trả lời bằng Tiếng Việt:
'''
        : '''
$basePrompt

${hasContext ? '' : 'PRODUCT LIST:\n$formattedProducts\n\nRESPONSE GUIDELINES:\n1. Analyze customer request\n2. Provide detailed product information\n3. Suggest suitable products\n4. Guide in-app purchase\n5. ALWAYS mention price and stock availability\n\n'}$userMessage

${hasContext ? '\nPRODUCT LIST:\n$formattedProducts\n\nGUIDELINES:\n- Use conversation context to understand customer request\n- Provide detailed product information from the list above\n- ALWAYS mention price and stock availability\n\n' : ''}Reply in English:
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
