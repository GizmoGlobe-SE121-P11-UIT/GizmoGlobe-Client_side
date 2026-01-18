import 'dart:convert';
import 'ai_nlp_service.dart';

/// AI Question Classifier
///
/// Uses Gemini NLP to automatically classify user questions into specific types
/// and extract relevant entities for targeted handling.
class AIQuestionClassifier {
  final AINLPService _nlpService = AINLPService();

  /// Classify user question and extract entities
  Future<QuestionClassification> classifyQuestion(
    String userMessage,
    bool isVietnamese,
  ) async {
    try {
      final prompt = _createClassificationPrompt(userMessage, isVietnamese);
      final response = await _nlpService.callGeminiAPI(prompt);
      return _parseClassification(response, isVietnamese);
    } catch (e) {
      // Fallback to general question type
      return QuestionClassification(
        type: QuestionType.general,
        confidence: 0.5,
        entities: {},
      );
    }
  }

  String _createClassificationPrompt(String message, bool isVietnamese) {
    return isVietnamese
        ? '''
Phân loại câu hỏi của người dùng vào MỘT trong các loại sau:

LOẠI CÂU HỎI:
1. COMPATIBILITY - Tìm linh kiện tương thích
   Ví dụ: "CPU nào tương thích LGA1200?", "Mainboard nào dùng được với i7-12700K?", "RAM nào cho AM4?"
   
2. PROMOTION - Tìm sản phẩm khuyến mãi
   Ví dụ: "Sản phẩm nào giảm giá >30%?", "Có khuyến mãi gì không?", "Deal tốt nhất hôm nay?"
   
3. BESTSELLER - Sản phẩm bán chạy
   ⚠️ KEYWORDS: "bán chạy", "top", "phổ biến", "nhiều người mua", "bestseller"
   Ví dụ: "GPU nào bán chạy nhất?", "CPU phổ biến nhất?", "Sản phẩm nào nhiều người mua?", "top 5 sản phẩm bán chạy", "top 5 CPU bán chạy nhất", "5 GPU bán chạy nhất"
   
4. BUILD_SUGGESTION - Gợi ý cấu hình hoàn chỉnh
   ⚠️ KEYWORDS: "build", "cấu hình", "xây dựng PC", "gợi ý máy", "lắp ráp"
   ⚠️ PHẢI có yêu cầu VỀ NHIỀU LINH KIỆN hoặc "PC/máy hoàn chỉnh"
   Ví dụ ĐÚNG:
   - "Build PC gaming 20 triệu" ✓ (build PC hoàn chỉnh)
   - "Cấu hình cho đồ họa 3D?" ✓ (cấu hình = nhiều linh kiện)
   - "Gợi ý PC văn phòng 10 triệu" ✓ (PC hoàn chỉnh)
   Ví dụ SAI (đây là PRODUCT_SEARCH):
   - "Tìm CPU dưới 10 triệu" ✗ (chỉ tìm 1 linh kiện)
   - "CPU tiết kiệm điện" ✗ (chỉ CPU, không phải PC)
   - "RAM 16GB giá rẻ" ✗ (chỉ RAM)
   
5. TERMINOLOGY - Giải thích thuật ngữ
   Ví dụ: "Chipset là gì?", "TDP nghĩa là sao?", "Khác biệt DDR4 vs DDR5?"
   
6. COMPARISON - So sánh sản phẩm
   Ví dụ: "RTX 4070 vs RTX 4060?", "i5 hay i7 tốt hơn?", "So sánh 2 CPU này"
   
7. PRODUCT_SEARCH - Tìm kiếm/mua sản phẩm ĐƠN LẺ (KHÔNG hỏi thông số kỹ thuật)
   ⚠️ KEYWORDS: "tìm", "có", "mua", "giá", "trong khoảng"
   ⚠️ CHỈ tìm MỘT LOẠI linh kiện, KHÔNG build PC
   Ví dụ ĐÚNG:
   - "Tìm CPU Intel" ✓ (chỉ tìm CPU)
   - "Có RAM 16GB không?" ✓ (chỉ tìm RAM)
   - "Tìm i7 12700" ✓ (chỉ tìm CPU cụ thể)
   - "CPU dưới 10 triệu, tiết kiệm điện" ✓ (chỉ tìm CPU)
   - "i7 12700 giá bao nhiêu?" ✓ (hỏi giá 1 sản phẩm)
   ⚠️ Chú ý: "Tìm i7 12700" là PRODUCT_SEARCH (muốn TÌM sản phẩm)
   
8. STOCK_PRICE - Kiểm tra giá, tồn kho
   Ví dụ: "RTX 4070 giá bao nhiêu?", "Còn hàng không?", "i7 12700K còn mấy cái?"
   
9. PRODUCT_SPEC - HỎI thông số kỹ thuật CỤ THỂ (KHÔNG phải tìm/mua)
   ⚠️ KEYWORDS: "thuộc", "có bao nhiêu", "sử dụng", "dùng", "là gì", "loại gì"
   ⚠️ PHẢI TRẢ LỜI spec_field: socket/capacity/vram/cores/wattage/clockSpeed/threads/tdp...
   Ví dụ ĐÚNG:
   - "i7 12700 thuộc socket nào?" → spec_field: "socket" ✓
   - "RAM Corsair Dominator bao nhiêu GB?" → spec_field: "capacity" ✓
   - "RTX 4070 có bao nhiêu VRAM?" → spec_field: "vram" ✓
   - "i7 12700 có mấy cores?" → spec_field: "cores" ✓
   - "Ryzen 5 5500 TDP bao nhiêu?" → spec_field: "tdp" ✓
   - "CPU này tiêu thụ điện bao nhiêu W?" → spec_field: "tdp" ✓
   Ví dụ SAI (đây là PRODUCT_SEARCH):
   - "Tìm i7 12700" → KHÔNG có spec_field ✗
   - "i7 12700 giá bao nhiêu?" → đây là STOCK_PRICE ✗
   
10. CART_FAVORITES - Giỏ hàng, yêu thích
    ⚠️ KEYWORDS: "giỏ hàng", "giỏ", "cart", "yêu thích", "favorites", "wishlist", "đã lưu", "đã thêm"
    ⚠️ ENTITIES: Extract "section" = "favorites" or "cart"
    Ví dụ GIỎ HÀNG (section: "cart"):
    - "Trong giỏ hàng tôi có gì?" → section: "cart"
    - "Xem giỏ hàng của tôi" → section: "cart"
    - "Giỏ hàng của tôi có những gì?" → section: "cart"
    - "Hiển thị giỏ hàng" → section: "cart"
    - "Xem giỏ" → section: "cart"
    - "Tôi đã thêm gì vào giỏ?" → section: "cart"
    - "Sản phẩm trong giỏ hàng" → section: "cart"
    - "Show my cart" → section: "cart"
    - "What's in my cart?" → section: "cart"
    
    Ví dụ YÊU THÍCH (section: "favorites"):
    - "Danh sách yêu thích?" → section: "favorites"
    - "Sản phẩm đã lưu?" → section: "favorites"
    - "Tìm các sản phẩm yêu thích của tôi" → section: "favorites"
    - "Xem sản phẩm yêu thích" → section: "favorites"
    - "Tôi đã lưu những gì?" → section: "favorites"
    - "Hiển thị danh sách yêu thích" → section: "favorites"
    - "Sản phẩm tôi thích" → section: "favorites"
    - "Show my favorites" → section: "favorites"
    - "My wishlist" → section: "favorites"
   
11. GENERAL - Câu hỏi chung
     Ví dụ: "Cảm ơn", "Xin chào", "Bạn giúp gì được tôi?"

CÂU HỎI: "$message"

Phân tích và trả lời ĐÚNG định dạng JSON (KHÔNG thêm ```json, KHÔNG thêm giải thích):
{
  "type": "<LOẠI IN HOA>",
  "confidence": <0.0-1.0>,
  "entities": {
    "socket": "<LGA1200|LGA1700|AM4|AM5... nếu có>",
    "category": "<cpu|gpu|ram|mainboard|psu|drive... nếu có>",
    "budget": <số tiền triệu VND nếu có>,
    "discount_threshold": <% giảm giá nếu có>,
    "product_names": ["<tên sản phẩm 1>", "<tên sản phẩm 2>"],
    "brands": ["<Intel|AMD|NVIDIA|...>"],
    "purpose": "<gaming|office|design|rendering... nếu có>",
    "spec_field": "<socket|capacity|vram|cores|wattage|tdp|clockSpeed|threads... nếu có>",
    "max_tdp": <số Watts TDP tối đa nếu có, ví dụ "dưới 35W" -> 35>
  }
}
'''
        : '''
Classify the user's question into ONE of the following types:

QUESTION TYPES:
1. COMPATIBILITY - Find compatible components
   Examples: "Which CPUs work with LGA1200?", "Compatible motherboards for i7-12700K?", "RAM for AM4?"
   
2. PROMOTION - Find products on sale
   Examples: "Products with >30% discount?", "Any promotions?", "Best deals today?"
   
3. BESTSELLER - Best-selling products
   Examples: "Best-selling GPU?", "Most popular CPU?", "What do people buy most?"
   
4. BUILD_SUGGESTION - Complete build recommendations
   ⚠️ KEYWORDS: "build", "configuration", "setup", "complete PC"
   ⚠️ MUST request MULTIPLE COMPONENTS or "complete PC/system"
   Examples CORRECT:
   - "Gaming PC 20 million VND" ✓ (complete PC build)
   - "3D graphics build?" ✓ (configuration = multiple parts)
   - "Office PC 10 million?" ✓ (complete PC)
   Examples WRONG (these are PRODUCT_SEARCH):
   - "Find CPU under 10 million" ✗ (searching for 1 component only)
   - "Power efficient CPU" ✗ (CPU only, not PC)
   - "Cheap 16GB RAM" ✗ (RAM only)
   
5. TERMINOLOGY - Explain technical terms
   Examples: "What is chipset?", "What does TDP mean?", "DDR4 vs DDR5 difference?"
   
6. COMPARISON - Compare products
   Examples: "RTX 4070 vs RTX 4060?", "i5 or i7 better?", "Compare these 2 CPUs"
   
7. PRODUCT_SEARCH - Search for SINGLE product (NOT asking about specs)
   ⚠️ KEYWORDS: "find", "search", "do you have", "price", "within range"
   ⚠️ Searching for ONE type of component only, NOT building PC
   Examples CORRECT:
   - "Find Intel CPU" ✓ (searching for CPU only)
   - "Do you have 16GB RAM?" ✓ (searching for RAM only)
   - "Cheap GPU" ✓ (searching for GPU only)
   - "CPU under 10 million, power efficient" ✓ (searching for CPU only)
   - "CPU around 5 million VND" ✓ (price query for single product)
    
8. STOCK_PRICE - Check price, stock
    Examples: "How much is RTX 4070?", "In stock?", "How many i7 12700K available?"
    
9. PRODUCT_SPEC - Ask about SPECIFIC technical specs of a KNOWN product
    Examples: "What socket does i7 12700 use?", "How much memory does RTX 4070 have?", "What is the capacity of Corsair Dominator RAM?"
    ⚠️ NOTE: Must have SPECIFIC PRODUCT NAME + ASK ABOUT TECH SPEC (socket, GB, cores, wattage...)
    
10. CART_FAVORITES - Cart, favorites
    ⚠️ KEYWORDS: "cart", "shopping cart", "favorites", "wishlist", "saved", "liked"
    ⚠️ ENTITIES: Extract "section" = "favorites" or "cart"
    Examples for CART (section: "cart"):
    - "What's in my cart?" → section: "cart"
    - "Show my cart" → section: "cart"
    - "View my shopping cart" → section: "cart"
    - "Display cart" → section: "cart"
    - "What did I add to cart?" → section: "cart"
    - "Cart items" → section: "cart"
    - "My cart contents" → section: "cart"
    
    Examples for FAVORITES (section: "favorites"):
    - "My favorites?" → section: "favorites"
    - "Saved products?" → section: "favorites"
    - "Show my wishlist" → section: "favorites"
    - "View my favorites" → section: "favorites"
    - "What did I save?" → section: "favorites"
    - "Display favorites" → section: "favorites"
    - "Products I liked" → section: "favorites"
    - "My wishlist items" → section: "favorites"
    
11. GENERAL - General questions
     Examples: "Thank you", "Hello", "How can you help me?"

QUESTION: "$message"

Analyze and respond in EXACT JSON format (NO ```json, NO explanation):
{
  "type": "<TYPE IN CAPS>",
  "confidence": <0.0-1.0>,
  "entities": {
    "socket": "<LGA1200|LGA1700|AM4|AM5... if any>",
    "category": "<cpu|gpu|ram|mainboard|psu|drive... if any>",
    "budget": <amount in million VND if any>,
    "discount_threshold": <discount % if any>,
    "product_names": ["<product name 1>", "<product name 2>"],
    "brands": ["<Intel|AMD|NVIDIA|...>"],
    "purpose": "<gaming|office|design|rendering... if any>",
    "spec_field": "<socket|capacity|vram|cores|wattage... if any>",
    "max_tdp": <maximum TDP in Watts if any, e.g. "under 35W" -> 35>
  }
}
''';
  }

  QuestionClassification _parseClassification(
      String response, bool isVietnamese) {
    try {
      // Clean response - remove markdown code blocks if present
      String cleaned = response.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final Map<String, dynamic> json = jsonDecode(cleaned);

      final typeStr = json['type'] as String;
      final confidence = (json['confidence'] as num).toDouble();
      final entities = Map<String, dynamic>.from(json['entities'] ?? {});

      // Map string to enum
      QuestionType type;
      switch (typeStr.toUpperCase()) {
        case 'COMPATIBILITY':
          type = QuestionType.compatibility;
          break;
        case 'PROMOTION':
          type = QuestionType.promotion;
          break;
        case 'BESTSELLER':
          type = QuestionType.bestseller;
          break;
        case 'BUILD_SUGGESTION':
          type = QuestionType.buildSuggestion;
          break;
        case 'TERMINOLOGY':
          type = QuestionType.terminology;
          break;
        case 'COMPARISON':
          type = QuestionType.comparison;
          break;
        case 'PRODUCT_SEARCH':
          type = QuestionType.productSearch;
          break;
        case 'STOCK_PRICE':
          type = QuestionType.stockPrice;
          break;
        case 'PRODUCT_SPEC':
          type = QuestionType.productSpec;
          break;
        case 'CART_FAVORITES':
          type = QuestionType.cartFavorites;
          break;
        default:
          type = QuestionType.general;
      }

      return QuestionClassification(
        type: type,
        confidence: confidence,
        entities: entities,
      );
    } catch (e) {
      // Fallback: Try to detect basic patterns
      return _fallbackClassification(response, isVietnamese);
    }
  }

  /// Fallback classification using simple pattern matching
  QuestionClassification _fallbackClassification(
      String message, bool isVietnamese) {
    final lower = message.toLowerCase();

    // Compatibility patterns
    if (lower.contains('tương thích') ||
        lower.contains('phù hợp') ||
        lower.contains('compatible') ||
        lower.contains('hợp với') ||
        lower.contains('dùng được') ||
        lower.contains('socket') ||
        lower.contains('lga') ||
        lower.contains('am4') ||
        lower.contains('am5')) {
      return QuestionClassification(
        type: QuestionType.compatibility,
        confidence: 0.7,
        entities: {},
      );
    }

    // Promotion patterns
    if (lower.contains('khuyến mãi') ||
        lower.contains('giảm giá') ||
        lower.contains('promotion') ||
        lower.contains('discount') ||
        lower.contains('sale')) {
      return QuestionClassification(
        type: QuestionType.promotion,
        confidence: 0.7,
        entities: {},
      );
    }

    // Build suggestion patterns
    if ((lower.contains('build') || lower.contains('cấu hình')) &&
        (lower.contains('triệu') || lower.contains('million'))) {
      return QuestionClassification(
        type: QuestionType.buildSuggestion,
        confidence: 0.7,
        entities: {},
      );
    }

    // Cart patterns
    if (lower.contains('giỏ hàng') ||
        lower.contains('giỏ') ||
        lower.contains('cart') ||
        lower.contains('shopping cart')) {
      return QuestionClassification(
        type: QuestionType.cartFavorites,
        confidence: 0.7,
        entities: {'section': 'cart'},
      );
    }

    // Favorites patterns
    if (lower.contains('yêu thích') ||
        lower.contains('đã lưu') ||
        lower.contains('favorites') ||
        lower.contains('wishlist') ||
        lower.contains('saved')) {
      return QuestionClassification(
        type: QuestionType.cartFavorites,
        confidence: 0.7,
        entities: {'section': 'favorites'},
      );
    }

    // Default to general
    return QuestionClassification(
      type: QuestionType.general,
      confidence: 0.5,
      entities: {},
    );
  }
}

/// Classification result
class QuestionClassification {
  final QuestionType type;
  final double confidence;
  final Map<String, dynamic> entities;

  QuestionClassification({
    required this.type,
    required this.confidence,
    required this.entities,
  });

  @override
  String toString() {
    return 'QuestionClassification(type: $type, confidence: $confidence, entities: $entities)';
  }
}

/// Question types
enum QuestionType {
  compatibility,
  promotion,
  bestseller,
  buildSuggestion,
  terminology,
  comparison,
  productSearch,
  stockPrice,
  productSpec,
  cartFavorites,
  general,
}
