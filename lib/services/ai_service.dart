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
      String? productName = _utils.extractProductNameFromRequest(userMessage);
      String contextInfo = '';

      // If no product name found, try to extract from context
      if (productName == null || productName.isEmpty) {
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

    if (userId != null) {
      _conversationService.updateHistory(userId, processedMessage, response);
    }

    return response;
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

  Future<String> _callGeminiAPI(String prompt, {int maxRetries = 3}) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        if (kDebugMode) {
          print(
              'Calling Gemini API... (Attempt ${retryCount + 1}/$maxRetries)');
        }
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
              return parts[0]['text'] as String;
            }
          }
          throw Exception('No valid response from Gemini API');
        } else if (response.statusCode == 503) {
          retryCount++;
          if (retryCount < maxRetries) {
            if (kDebugMode) {
              print(
                  'Model overloaded, retrying in ${retryCount * 2} seconds...');
            }
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          }
        }
        throw Exception(
            'API call failed with status code: ${response.statusCode}, body: ${response.body}');
      } catch (e) {
        if (kDebugMode) {
          print('Error calling Gemini API: $e');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          if (kDebugMode) {
            print('Retrying in ${retryCount * 2} seconds...');
          }
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        rethrow;
      }
    }
    throw Exception(
        'Failed to get response from Gemini API after $maxRetries attempts');
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
