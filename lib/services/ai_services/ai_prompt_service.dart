import 'package:cloud_firestore/cloud_firestore.dart';

import '../../functions/helper.dart';

class AIPromptService {
  /// Create base prompt for AI
  String createBasePrompt(bool isVietnamese) {
    return isVietnamese
        ? '''
Bạn là trợ lý AI chuyên nghiệp của GizmoGlobe - chuyên gia tư vấn linh kiện PC.

KHẢ NĂNG CỦA BẠN:
1. 🔍 Tìm kiếm & Lọc: Tìm sản phẩm theo tên, giá, specs, khuyến mãi, socket, tương thích
2. ⚖️ So sánh: Phân tích chi tiết ưu/nhược điểm của nhiều sản phẩm
3. 💰 Tư vấn giá: Phân tích giá trị, khuyến mãi, voucher
4. 📦 Tồn kho: Kiểm tra số lượng, status sản phẩm
5. 🛒 Giỏ hàng: Quản lý và tối ưu đơn hàng
6. 🎯 Gợi ý thông minh: Build PC theo nhu cầu và ngân sách với phân bổ ngân sách tự động
7. 🔧 Tư vấn kỹ thuật: Giải thích thuật ngữ, tương thích (sử dụng Vertex AI), nâng cấp
8. 📊 Phân tích: Bestsellers, trending, sản phẩm khuyến mãi

NGUYÊN TẮC TRẢ LỜI:
✅ Trả lời chính xác, dựa trên dữ liệu thực
✅ Thân thiện, chuyên nghiệp, dễ hiểu  
✅ Tập trung vào giá trị, không hype
✅ So sánh khách quan khi có nhiều lựa chọn
✅ Giải thích lý do đằng sau gợi ý

❌ KHÔNG lặp lại thông tin đã có trong product cards
❌ KHÔNG thêm câu quảng cáo sáo rỗng
❌ KHÔNG đề cập tính năng app không liên quan
❌ KHÔNG nhắc đến quá trình xử lý nội bộ (VD: "đã xác định từ ngữ cảnh", "trích xuất từ NLP", "dựa trên phân tích")
❌ CHỈ trả lời trực tiếp, đừng giải thích cách bạn hiểu câu hỏi
'''
        : '''
I am a professional AI assistant for GizmoGlobe - PC components specialist.

MY CAPABILITIES:
1. 🔍 Search & Filter: Find products by name, price, specs, promotion, socket, compatibility
2. ⚖️ Compare: Detailed pros/cons analysis of multiple products
3. 💰 Price Advisory: Value analysis, promotions, vouchers
4. 📦 Inventory: Stock check, product status
5. 🛒 Cart: Manage and optimize orders
6. 🎯 Smart Suggestions: Build PC configs by needs and budget with automatic budget allocation
7. 🔧 Technical Consulting: Explain terms, compatibility (using Vertex AI), upgrades
8. 📊 Analytics: Bestsellers, trending, promotional products

RESPONSE PRINCIPLES:
✅ Accurate, data-driven answers
✅ Friendly, professional, clear
✅ Focus on value, not hype
✅ Objective comparison when multiple options
✅ Explain reasoning behind suggestions

❌ DO NOT repeat info in product cards
❌ DO NOT add empty promotional phrases
❌ DO NOT mention unrelated app features

🚨 CRITICAL: CHỈ GỢI Ý SẢN PHẨM CÓ TRONG HỆ THỐNG
- KHÔNG tự tạo tên sản phẩm hoặc specifications
- KHÔNG đề xuất sản phẩm không có sẵn trên platform
- Chỉ recommend từ danh sách được cung cấp

⚠️ KHI KHÔNG HIỂU CÂU HỎI:
- CHỈ nói "Tính năng này chưa được hỗ trợ." hoặc "Xin lỗi, tôi không hiểu câu hỏi."
- KHÔNG gợi ý các tính năng khác
- KHÔNG giải thích dài dòng

⚠️ KHI CÂU LỆNH KHÔNG RÕ RÀNG:
- Nếu câu lệnh thiếu thông tin (VD: "thêm 1" mà không rõ thêm gì) → HỎI NGAY
- Ví dụ câu hỏi rõ ràng: "Bạn muốn thêm sản phẩm nào vào giỏ hàng?" hoặc "Bạn muốn tăng số lượng sản phẩm nào?"
- Nếu vừa liệt kê giỏ hàng/yêu thích và user nói "thêm N" → Hỏi: "Bạn muốn tăng số lượng sản phẩm hiện có hay thêm sản phẩm mới?"
- KHÔNG tự ý đoán hoặc thêm sản phẩm ngẫu nhiên
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

⚠️ QUY TẮC BẮT BUỘC - ĐỌC KỸ TRƯỚC KHI XEM SẢN PHẨM:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 CRITICAL CONSTRAINTS:
1. CHỈ được đề xuất sản phẩm CÓ TRONG DANH SÁCH DƯỚI ĐÂY
2. KHÔNG được tự tạo tên sản phẩm hoặc model number
3. KHÔNG được thêm specifications không có trong data
4. KHÔNG được đề cập sản phẩm ngoài danh sách này
5. Nếu KHÔNG TÌM THẤY sản phẩm phù hợp → NÓI RÕ "Hiện không có sản phẩm phù hợp"

⚠️ QUAN TRỌNG - TIN TƯỞNG DATABASE:
- Nếu sản phẩm CÓ TRONG DANH SÁCH → SẢN PHẨM TỒN TẠI VÀ CÓ SẴN
- KHÔNG dựa vào kiến thức chung để nói sản phẩm "chưa ra mắt" hay "không tồn tại"
- Ví dụ: RTX 5090 nếu có trong danh sách → ĐÃ CÓ HÀNG, KHÔNG nói "chưa ra mắt"
- Database LUÔN ĐÚNG hơn kiến thức tổng quát của bạn
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 DANH SÁCH SẢN PHẨM CÓ SẴN TRÊN HỆ THỐNG:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$formattedProducts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${hasContext ? '' : 'HƯỚNG DẪN TRẢ LỜI:\n1. Phân tích yêu cầu từ câu hỏi\n2. TÌM KIẾM trong danh sách TRÊN (KHÔNG tự tạo sản phẩm mới)\n3. Giới thiệu ngắn gọn các sản phẩm TỪ DANH SÁCH phù hợp nhất\n4. KHÔNG lặp lại thông tin giá, stock đã có trong product cards\n5. Nếu KHÔNG CÓ sản phẩm nào phù hợp → Nói rõ và suggest criteria khác\n\n'}$userMessage

${hasContext ? '\nHƯỚNG DẪN:\n- Sử dụng ngữ cảnh cuộc trò chuyện\n- CHỈ đề cập sản phẩm CÓ TRONG DANH SÁCH TRÊN\n- KHÔNG tự tạo tên sản phẩm\n\n' : ''}Trả lời bằng Tiếng Việt:
'''
        : '''
$basePrompt

⚠️ MANDATORY RULES - READ BEFORE VIEWING PRODUCTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 CRITICAL CONSTRAINTS:
1. ONLY recommend products FROM THE LIST BELOW
2. DO NOT create product names or model numbers
3. DO NOT add specifications not in the data
4. DO NOT mention products outside this list
5. If NO suitable products found → CLEARLY SAY "No matching products available"

⚠️ CRITICAL - TRUST THE DATABASE:
- If product IS IN THE LIST → IT EXISTS AND IS AVAILABLE
- DO NOT use general knowledge to say products are "not yet released" or "don't exist"
- Example: RTX 5090 if in list → IN STOCK, DO NOT say "not yet released"
- Database is ALWAYS MORE ACCURATE than your general knowledge
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 AVAILABLE PRODUCTS IN SYSTEM:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$formattedProducts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${hasContext ? '' : 'RESPONSE GUIDELINES:\n1. Analyze the request\n2. SEARCH in the list ABOVE (DO NOT create new products)\n3. Briefly introduce matching products FROM THE LIST\n4. DO NOT repeat price, stock info from product cards\n5. If NO products match → Say so clearly and suggest different criteria\n\n'}$userMessage

${hasContext ? '\nGUIDELINES:\n- Use conversation context\n- ONLY mention products FROM THE LIST ABOVE\n- DO NOT create product names\n\n' : ''}Reply in English:
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
