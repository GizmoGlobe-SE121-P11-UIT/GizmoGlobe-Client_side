import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import the new service classes
import 'ai_services/ai_conversation_service.dart';
import 'ai_services/ai_product_service.dart';
import 'ai_services/ai_cart_service.dart';
import 'ai_services/ai_user_data_service.dart';
import 'ai_services/ai_prompt_service.dart';
import 'ai_services/ai_utils.dart';
import 'ai_services/ai_nlp_service.dart';

class AIService {
  final FirebaseFirestore _firestore;

  // Service instances
  late final AIConversationService _conversationService;
  late final AIProductService _productService;
  late final AICartService _cartService;
  late final AIUserDataService _userDataService;
  late final AIPromptService _promptService;
  late final AIUtils _utils;
  late final AINLPService _nlpService;

  AIService() : _firestore = FirebaseFirestore.instance {
    if (dotenv.env['GEMINI_API_KEY']?.isEmpty ?? true) {
      if (kDebugMode) {
        print('GEMINI_API_KEY is not configured in .env file');
      }
      throw Exception('GEMINI_API_KEY is not configured in .env file');
    }

    // Initialize service instances
    _conversationService = AIConversationService(_firestore);
    _productService = AIProductService(_firestore);
    _cartService = AICartService(_firestore);
    _userDataService = AIUserDataService(_firestore);
    _promptService = AIPromptService();
    _utils = AIUtils();
    _nlpService = AINLPService();
  }

  Future<String> generateResponse(String userMessage, {String? userId}) async {
    try {
      final isVietnamese = _utils.isVietnamese(userMessage);
      final isGreeting = _utils.isGreeting(userMessage);
      final isStoreQuestion = _utils.isStoreQuestion(userMessage);
      final isProductQuestion = _utils.isProductQuestion(userMessage);
      final isFavoriteQuestion = _utils.isFavoriteQuestion(userMessage);
      final isCartQuestion = _utils.isCartQuestion(userMessage);
      final isCartQuantityQuestion = _utils.isCartQuantityQuestion(userMessage);
      // final isInvoiceQuestion = _utils.isInvoiceQuestion(userMessage);
      final isVoucherQuestion = _utils.isVoucherQuestion(userMessage);
      final isAddToCartRequest = _utils.isAddToCartRequest(userMessage);

      // Process context if userId is provided
      final processedMessage = userId != null
          ? await _conversationService.processContext(userMessage, userId)
          : userMessage;

      // Handle add to cart requests
      if (isAddToCartRequest) {
        return await _handleAddToCartRequest(userMessage, userId, isVietnamese);
      }

      // Handle voucher questions
      if (isVoucherQuestion) {
        return await _handleVoucherQuestion(userMessage, userId, isVietnamese);
      }

      // Handle favorite or cart questions
      if (isFavoriteQuestion || isCartQuestion) {
        return await _handleUserDataQuestion(userMessage, userId, isVietnamese,
            isFavoriteQuestion, isCartQuestion, isCartQuantityQuestion);
      }

      // Handle product questions
      if (isProductQuestion) {
        return await _handleProductQuestion(
            processedMessage, userId, isVietnamese);
      }

      // Handle greetings or store questions
      if (isGreeting || isStoreQuestion) {
        return await _handleGeneralQuestion(
            processedMessage, userId, isVietnamese);
      }

      // Handle other general questions
      return await _handleGeneralQuestion(
          processedMessage, userId, isVietnamese);
    } catch (e) {
      if (kDebugMode) {
        print('Error in generateResponse: $e');
      }
      return _utils.isVietnamese(userMessage)
          ? 'Xin lỗi, hiện tại tôi không thể xử lý yêu cầu của bạn. Vui lòng thử lại sau.'
          : 'Sorry, I cannot process your request at the moment. Please try again later.';
    }
  }

  Future<String> _handleAddToCartRequest(
      String userMessage, String? userId, bool isVietnamese) async {
    if (userId == null) {
      return isVietnamese
          ? 'Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng.'
          : 'Please log in to add products to your cart.';
    }

    try {
      String? productName;
      String contextInfo = '';

      // First, try NLP-based extraction (more intelligent and flexible)
      if (kDebugMode) {
        print('Trying NLP-based extraction first...');
      }
      try {
        productName = await _nlpService.extractProductNameWithNLP(
            userMessage, isVietnamese);
        if (productName != null && productName.isNotEmpty) {
          if (kDebugMode) {
            print('NLP extracted product name: "$productName"');
          }
          contextInfo = isVietnamese
              ? ' (Đã xác định bằng NLP: $productName)'
              : ' (Identified via NLP: $productName)';
        }
      } catch (e) {
        if (kDebugMode) {
          print('NLP extraction failed: $e');
        }
      }

      // If NLP failed, try regex extraction as fallback
      if (productName == null || productName.isEmpty) {
        if (kDebugMode) {
          print('NLP extraction failed, trying regex extraction...');
        }
        productName = _utils.extractProductNameFromRequest(userMessage);
        if (productName != null && productName.isNotEmpty) {
          if (kDebugMode) {
            print('Regex extracted product name: "$productName"');
          }
          contextInfo = isVietnamese
              ? ' (Đã xác định bằng regex: $productName)'
              : ' (Identified via regex: $productName)';
        }
      }

      // Check if extracted name is a pronoun/reference word (like "nó", "it", "this", "that")
      final isPronounOrReference =
          productName != null && _utils.isPronounOrReference(productName);

      // If no product name found OR if it's just a pronoun/reference, try context extraction
      if (productName == null || productName.isEmpty || isPronounOrReference) {
        if (kDebugMode && isPronounOrReference) {
          print(
              'Extracted name "$productName" is a pronoun/reference, using context extraction');
        }
        productName = await _conversationService.extractProductNameFromContext(
            userId, userMessage);

        if (productName != null) {
          contextInfo = isVietnamese
              ? ' (Đã xác định từ ngữ cảnh: $productName)'
              : ' (Identified from context: $productName)';
        }
      }

      // Use NLP to enhance product name understanding
      if (productName != null && productName.isNotEmpty) {
        final nlpAnalysis =
            await _nlpService.analyzeProductQuery(productName, isVietnamese);
        final enhancedProductName =
            nlpAnalysis['product_name'] as String? ?? productName;
        final synonyms =
            (nlpAnalysis['synonyms'] as List?)?.cast<String>() ?? [];

        if (kDebugMode) {
          print(
              'NLP Enhanced Product Name: $enhancedProductName (original: $productName)');
          print('Synonyms: $synonyms');
        }

        // Try to find the product with enhanced name first
        var foundProduct =
            await _productService.findProductByName(enhancedProductName);

        // If not found, try with synonyms
        if (foundProduct == null && synonyms.isNotEmpty) {
          for (final synonym in synonyms) {
            foundProduct = await _productService.findProductByName(synonym);
            if (foundProduct != null) {
              if (kDebugMode) {
                print('Found product using synonym: $synonym');
              }
              break;
            }
          }
        }

        // If still not found, try with original name
        foundProduct ??= await _productService.findProductByName(productName);

        if (foundProduct != null) {
          productName =
              foundProduct['productName'] as String? ?? enhancedProductName;
        } else {
          productName = enhancedProductName;
        }
      }

      if (productName == null || productName.isEmpty) {
        final response = _utils.getProductNotFoundResponse(isVietnamese);
        _conversationService.updateHistory(userId, userMessage, response);
        return response;
      }

      final quantity = _utils.extractQuantityFromRequest(userMessage);
      final product = await _productService.findProductByName(productName);

      if (product == null) {
        final response = await _productService.getProductNotFoundResponse(
            productName, isVietnamese);
        _conversationService.updateHistory(userId, userMessage, response);
        return response;
      }

      // Check stock availability
      final stock = product['stock'] ?? 0;
      if (stock < quantity) {
        final response = isVietnamese
            ? 'Xin lỗi, chỉ còn $stock sản phẩm trong kho. Vui lòng giảm số lượng hoặc chọn sản phẩm khác.'
            : 'Sorry, only $stock items available in stock. Please reduce the quantity or choose a different product.';
        _conversationService.updateHistory(userId, userMessage, response);
        return response;
      }

      final success = await _cartService.addProductToCart(
          userId, product['productID'], quantity);

      if (success) {
        final response = _cartService.getAddToCartSuccessResponse(
                product, quantity, isVietnamese) +
            contextInfo;
        _conversationService.updateHistory(userId, userMessage, response);
        return response;
      } else {
        final response = isVietnamese
            ? 'Xin lỗi, có lỗi xảy ra khi thêm sản phẩm vào giỏ hàng. Vui lòng thử lại sau.'
            : 'Sorry, an error occurred while adding the product to cart. Please try again later.';
        _conversationService.updateHistory(userId, userMessage, response);
        return response;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling add to cart request: $e');
      }
      final response = isVietnamese
          ? 'Xin lỗi, có lỗi xảy ra khi xử lý yêu cầu thêm vào giỏ hàng. Vui lòng thử lại sau.'
          : 'Sorry, an error occurred while processing your add to cart request. Please try again later.';
      _conversationService.updateHistory(userId, userMessage, response);
      return response;
    }
  }

  Future<String> _handleVoucherQuestion(
      String userMessage, String? userId, bool isVietnamese) async {
    try {
      final vouchers = await _userDataService.getVouchers();
      final formattedVouchers =
          _userDataService.formatVoucherList(vouchers, isVietnamese);
      final basePrompt = _promptService.createBasePrompt(isVietnamese);

      final prompt = _promptService.createVoucherPrompt(
          basePrompt, formattedVouchers, userMessage, isVietnamese);
      final response = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));

      if (userId != null) {
        _conversationService.updateHistory(userId, userMessage, response);
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error handling voucher question: $e');
      }
      return isVietnamese
          ? 'Xin lỗi, có lỗi xảy ra khi xử lý yêu cầu của bạn. Vui lòng thử lại sau.'
          : 'Sorry, an error occurred while processing your request. Please try again later.';
    }
  }

  Future<String> _handleUserDataQuestion(
      String userMessage,
      String? userId,
      bool isVietnamese,
      bool isFavoriteQuestion,
      bool isCartQuestion,
      bool isCartQuantityQuestion) async {
    if (userId == null) {
      return isVietnamese
          ? 'Vui lòng đăng nhập để xem ${isFavoriteQuestion ? "danh sách sản phẩm yêu thích" : "giỏ hàng"} của bạn.'
          : 'Please log in to view your ${isFavoriteQuestion ? "favorite products" : "cart"}.';
    }

    final basePrompt = _promptService.createBasePrompt(isVietnamese);
    String content = '';
    String sectionTitle = '';

    if (isFavoriteQuestion) {
      final favorites = await _userDataService.getUserFavorites(userId);
      content = _userDataService.formatFavoritesList(favorites, isVietnamese);
      sectionTitle =
          isVietnamese ? 'DANH SÁCH SẢN PHẨM YÊU THÍCH' : 'FAVORITE PRODUCTS';
    }

    if (isCartQuestion) {
      final cartItems = await _userDataService.getUserCart(userId);

      // If asking about quantity specifically, provide a focused response
      if (isCartQuantityQuestion) {
        final totalItems = cartItems.fold<int>(
            0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
        final totalProducts = cartItems.length;

        return isVietnamese
            ? '📦 Giỏ hàng của bạn có $totalItems sản phẩm (từ $totalProducts loại sản phẩm khác nhau).'
            : '📦 Your cart contains $totalItems items (from $totalProducts different products).';
      }

      content = _userDataService.formatCartList(cartItems, isVietnamese);
      sectionTitle = isVietnamese ? 'GIỎ HÀNG' : 'CART CONTENTS';
    }

    final prompt = _promptService.createUserDataPrompt(
        basePrompt, sectionTitle, content, userMessage, isVietnamese);
    final response = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));

    _conversationService.updateHistory(userId, userMessage, response);
    return response;
  }

  Future<String> _handleProductQuestion(
      String processedMessage, String? userId, bool isVietnamese) async {
    final isConnected = await _productService.checkFirebaseConnection();
    if (!isConnected) {
      final response = isVietnamese
          ? 'Xin lỗi, không thể kết nối đến cơ sở dữ liệu. Vui lòng kiểm tra kết nối mạng và thử lại.'
          : 'Sorry, unable to connect to the database. Please check your network connection and try again.';
      if (userId != null) {
        _conversationService.updateHistory(userId, processedMessage, response);
      }
      return response;
    }

    // Use NLP to analyze the user query
    final nlpAnalysis =
        await _nlpService.analyzeProductQuery(processedMessage, isVietnamese);

    if (kDebugMode) {
      print('NLP Analysis: $nlpAnalysis');
    }

    // Extract information from NLP analysis
    final productName = nlpAnalysis['product_name'] as String? ?? '';
    final category = nlpAnalysis['category'] as String? ?? '';
    final brand = nlpAnalysis['brand'] as String? ?? '';
    final synonyms = (nlpAnalysis['synonyms'] as List?)?.cast<String>() ?? [];
    final confidence = nlpAnalysis['confidence'] as double? ?? 0.0;

    if (kDebugMode) {
      print(
          'NLP Results - Product: $productName, Category: $category, Synonyms: $synonyms, Confidence: $confidence');
    }

    // Search products using NLP-enhanced approach
    QuerySnapshot? productsSnapshot;

    // Try searching with the exact product name first
    if (productName.isNotEmpty && confidence > 0.7) {
      productsSnapshot = await _productService.searchProductsWithNLP(
          productName: productName,
          category: category,
          synonyms: synonyms,
          isVietnamese: isVietnamese);
    }

    // Fallback to traditional search if NLP search fails
    if (productsSnapshot == null || productsSnapshot.docs.isEmpty) {
      final fallbackCategory = _utils.detectProductCategory(processedMessage);
      final fallbackKeywords = _utils.extractSearchKeywords(processedMessage);

      if (kDebugMode) {
        print(
            'Fallback search - Category: $fallbackCategory, Keywords: $fallbackKeywords');
      }

      if (fallbackCategory != null) {
        productsSnapshot =
            await _productService.searchProducts(category: fallbackCategory);
      } else if (fallbackKeywords.isNotEmpty) {
        productsSnapshot = await _productService.searchProducts(
            keyword: fallbackKeywords.first);
      } else {
        productsSnapshot = await _productService.searchProducts();
      }
    }

    if (productsSnapshot.docs.isEmpty) {
      final response = isVietnamese
          ? 'Xin lỗi, hiện tại chưa có sản phẩm nào phù hợp với yêu cầu của bạn. Tuy nhiên, chúng tôi sẽ sớm cập nhật thêm sản phẩm mới. Bạn có thể để lại thông tin liên hệ để được thông báo khi có sản phẩm mới.'
          : 'Sorry, there are currently no products matching your requirements. However, we will be updating with new products soon. You can leave your contact information to be notified when new products arrive.';
      if (userId != null) {
        _conversationService.updateHistory(userId, processedMessage, response);
      }
      return response;
    }

    final prompt = _promptService.createPromptWithProducts(
        processedMessage, productsSnapshot, isVietnamese);
    final response = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));
    final productCardFilters = _buildProductCardFilters(
      brand: brand,
      productName: productName,
      synonyms: synonyms,
    );
    final disableCardFallback = brand.trim().isNotEmpty;

    if (kDebugMode) {
      print('Product card filters: $productCardFilters');
      print('Brand extracted: "$brand"');
    }

    final productCardsAttachment = _buildProductCardsAttachment(
      productsSnapshot,
      isVietnamese: isVietnamese,
      keywordFilters: productCardFilters,
      disableFallbackOnEmptyMatch: disableCardFallback,
    );

    if (userId != null) {
      _conversationService.updateHistory(userId, processedMessage, response);
    }

    return productCardsAttachment.isEmpty
        ? response
        : '$response\n\n$productCardsAttachment';
  }

  Future<String> _handleGeneralQuestion(
      String processedMessage, String? userId, bool isVietnamese) async {
    final prompt = _promptService.createPromptWithoutProducts(
        processedMessage, isVietnamese);
    final response = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));

    if (userId != null) {
      _conversationService.updateHistory(userId, processedMessage, response);
    }

    return response;
  }

  Future<String> _callGeminiAPI(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Try 2.5-flash max 3 times, then fallback to 2.5-flash-lite
    const maxRetries25Flash = 3;
    final models = [
      {'name': 'gemini-2.5-flash', 'maxRetries': maxRetries25Flash},
      {'name': 'gemini-2.5-flash-lite', 'maxRetries': maxRetries25Flash},
    ];
    bool useFallback = false;

    for (final modelConfig in models) {
      final model = modelConfig['name'] as String;
      final modelMaxRetries = modelConfig['maxRetries'] as int;
      int retryCount = 0;
      while (retryCount < modelMaxRetries) {
        try {
          if (kDebugMode) {
            if (useFallback) {
              print(
                  'Using fallback model: $model (Attempt ${retryCount + 1}/$modelMaxRetries)');
            } else {
              print(
                  'Calling Gemini API with $model... (Attempt ${retryCount + 1}/$modelMaxRetries)');
            }
          }

          final response = await http.post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'),
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
              }
            }),
          );

          if (kDebugMode) {
            print('Gemini API response status: ${response.statusCode}');
          }
          if (kDebugMode) {
            print('Gemini API response body: ${response.body}');
          }

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            final candidates = responseData['candidates'] as List;
            if (candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              final parts = content['parts'] as List;
              if (parts.isNotEmpty) {
                if (useFallback && kDebugMode) {
                  print('Successfully used fallback model: $model');
                }
                return parts[0]['text'] as String;
              }
            }
            throw Exception('No valid response from Gemini API');
          } else if (response.statusCode == 503) {
            // If 2.5-flash is overloaded, switch to fallback immediately
            if (model == 'gemini-2.5-flash' && !useFallback) {
              if (kDebugMode) {
                print(
                    'Model 2.5-flash is overloaded after ${retryCount + 1} attempt(s), switching to 2.5-flash-lite fallback...');
              }
              useFallback = true;
              break; // Break retry loop and try next model
            }

            // If fallback also fails, retry
            retryCount++;
            if (retryCount < modelMaxRetries) {
              if (kDebugMode) {
                print(
                    'Model overloaded, retrying in ${retryCount * 2} seconds...');
              }
              await Future.delayed(Duration(seconds: retryCount * 2));
              continue;
            }
          } else {
            // For other errors, try next model if available
            if (model == 'gemini-2.5-flash' && !useFallback) {
              if (kDebugMode) {
                print(
                    'Model 2.5-flash failed with status ${response.statusCode} after ${retryCount + 1} attempt(s), switching to 2.5-flash-lite fallback...');
              }
              useFallback = true;
              break; // Break retry loop and try next model
            }
            throw Exception(
                'API call failed with status code: ${response.statusCode}, body: ${response.body}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error calling Gemini API with $model: $e');
          }

          // If 2.5-flash fails, try fallback
          if (model == 'gemini-2.5-flash' && !useFallback) {
            if (kDebugMode) {
              print(
                  'Switching to 2.5-flash-lite fallback due to error after ${retryCount + 1} attempt(s)...');
            }
            useFallback = true;
            break; // Break retry loop and try next model
          }

          retryCount++;
          if (retryCount < modelMaxRetries) {
            if (kDebugMode) {
              print('Retrying in ${retryCount * 2} seconds...');
            }
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          }

          // If this is the last model, rethrow
          if (model == models.last['name']) {
            rethrow;
          }
        }
      }
    }

    throw Exception(
        'Failed to get response from Gemini API after trying all models');
  }

  // Public methods for conversation management
  Future<void> clearConversationHistory(String userId) async {
    await _conversationService.clearConversationHistory(userId);
  }

  Future<List<Map<String, dynamic>>> getConversationHistory(
      String userId) async {
    return await _conversationService.getConversationHistory(userId);
  }

  Future<bool> hasRecentHistory(String userId) async {
    return await _conversationService.hasRecentHistory(userId);
  }

  /// Get formatted conversation history for model fine-tuning
  Future<String> getFormattedConversationHistory(String userId) async {
    return await _conversationService.getFormattedConversationHistory(userId);
  }

  /// Export conversation data for analysis and fine-tuning
  Future<Map<String, dynamic>> exportConversationData(String userId) async {
    return await _conversationService.exportConversationData(userId);
  }

  /// Debug method to check conversation context processing
  Future<String> debugContextProcessing(
      String userMessage, String userId) async {
    final processedMessage =
        await _conversationService.processContext(userMessage, userId);
    final isAddToCart = _utils.isAddToCartRequest(userMessage);

    return '''
DEBUG CONTEXT PROCESSING:
Original message: "$userMessage"
Is add to cart request: $isAddToCart
Processed message length: ${processedMessage.length}
Processed message starts with context: ${processedMessage.startsWith('CONVERSATION CONTEXT')}
''';
  }
}

String _formatSpec(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

List<String> _buildProductCardFilters({
  String? brand,
  String? productName,
  List<String>? synonyms,
}) {
  final Set<String> filters = <String>{};

  void addToken(String? raw) {
    if (raw == null) return;
    final token = raw.trim().toLowerCase();
    if (token.isEmpty) return;
    // Split by whitespace and add individual words
    final parts = token.split(RegExp(r'\s+'));
    for (final part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.isNotEmpty) {
        filters.add(trimmedPart);
      }
    }
  }

  // Only use brand and product name for filtering
  // Synonyms are too broad and may not appear in product data
  addToken(brand);
  addToken(productName);

  return filters.toList();
}

String _buildProductCardsAttachment(
  QuerySnapshot snapshot, {
  bool isVietnamese = true,
  int limit = 4,
  List<String>? keywordFilters,
  bool disableFallbackOnEmptyMatch = false,
}) {
  if (snapshot.docs.isEmpty) return '';

  final normalizedFilters = (keywordFilters ?? [])
      .map((token) => token.trim().toLowerCase())
      .where((token) => token.isNotEmpty)
      .toList();

  List<QueryDocumentSnapshot> docs = snapshot.docs;

  if (normalizedFilters.isNotEmpty) {
    if (kDebugMode) {
      print(
          'Filtering ${docs.length} products with tokens: $normalizedFilters');
    }

    final filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final manufacturer = _extractManufacturerName(data).toLowerCase();
      final tags = (data['tags']?.toString() ?? '').toLowerCase();
      final searchText = '$name $manufacturer $tags';

      // Each filter token must appear in the combined search text
      final matches =
          normalizedFilters.every((token) => searchText.contains(token));

      if (kDebugMode && matches) {
        print('✓ Match: $name | Manufacturer: $manufacturer');
      }

      return matches;
    }).toList();

    if (kDebugMode) {
      print('Filtered to ${filteredDocs.length} products');
    }

    if (filteredDocs.isNotEmpty) {
      docs = filteredDocs;
    } else if (disableFallbackOnEmptyMatch) {
      docs = <QueryDocumentSnapshot>[];
      if (kDebugMode) {
        print('No matches and fallback disabled - returning empty cards');
      }
    }
  }

  final cards = docs.take(limit).map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final sellingPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
    final discount = (data['discount'] as num?)?.toDouble() ?? 0;
    final discountedPrice = (data['discountedPrice'] as num?)?.toDouble() ??
        sellingPrice * (1 - discount / 100);
    final category = data['category']?.toString() ?? '';

    final List<String> quickSpecs = [];
    switch (category.toLowerCase()) {
      case 'cpu':
        quickSpecs.add('${_formatSpec(data['core'])} cores');
        quickSpecs.add('${_formatSpec(data['thread'])} threads');
        quickSpecs.add('Turbo ${_formatSpec(data['turboClock'])}GHz');
        break;
      case 'gpu':
        quickSpecs.add('${_formatSpec(data['memory'])} VRAM');
        quickSpecs.add('Clock ${_formatSpec(data['clockSpeed'])}MHz');
        break;
      case 'ram':
        quickSpecs.add('${_formatSpec(data['capacity'])} Capacity');
        quickSpecs.add('${_formatSpec(data['bus'])} MHz');
        break;
      case 'psu':
        quickSpecs.add('${_formatSpec(data['wattage'])}W');
        quickSpecs.add('Efficiency ${_formatSpec(data['efficiency'])}');
        break;
      case 'drive':
        quickSpecs.add('${_formatSpec(data['capacity'])}');
        quickSpecs.add('${_formatSpec(data['type'])}');
        break;
      case 'mainboard':
        quickSpecs.add('${_formatSpec(data['formFactor'])}');
        quickSpecs.add('Socket ${_formatSpec(data['socket'])}');
        break;
    }

    return {
      'id': doc.id,
      'name': data['productName'] ?? '',
      'price': discountedPrice,
      'originalPrice': sellingPrice,
      'discount': discount,
      'stock': data['stock'] ?? 0,
      'imageUrl': data['imageUrl'],
      'category': category,
      'quickSpecs': quickSpecs.where((s) => s.trim().isNotEmpty).toList(),
      'description': isVietnamese
          ? data['viDescription'] ?? ''
          : data['enDescription'] ?? '',
    };
  }).toList();

  if (cards.isEmpty) return '';

  return '[PRODUCT_CARDS]${jsonEncode(cards)}[/PRODUCT_CARDS]';
}

String _extractManufacturerName(Map<String, dynamic> data) {
  final manufacturer = data['manufacturer'];
  if (manufacturer is Map<String, dynamic>) {
    return manufacturer['name']?.toString() ?? '';
  }
  return manufacturer?.toString() ?? '';
}
