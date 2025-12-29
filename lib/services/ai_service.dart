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
import 'ai_services/ai_question_classifier.dart';
import 'compatibility_handler.dart';
import 'enhanced_query_handlers.dart';

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
  late final AIQuestionClassifier _questionClassifier;
  late final CompatibilityHandler _compatibilityHandler;
  late final EnhancedQueryHandlers _enhancedHandlers;

  AIService() : _firestore = FirebaseFirestore.instance {
    // Only require GEMINI_API_KEY on mobile - web uses Cloud Function proxy
    if (!kIsWeb && (dotenv.env['GEMINI_API_KEY']?.isEmpty ?? true)) {
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
    _questionClassifier = AIQuestionClassifier();
    _compatibilityHandler = CompatibilityHandler();
    _enhancedHandlers = EnhancedQueryHandlers();
  }

  Future<String> generateResponse(String userMessage, {String? userId}) async {
    try {
      final isVietnamese = _utils.isVietnamese(userMessage);

      // NEW: Use NLP classifier for intelligent question routing
      QuestionClassification? classification;
      try {
        classification = await _questionClassifier.classifyQuestion(
            userMessage, isVietnamese);
        if (kDebugMode) {
          print(
              'Question classified as: ${classification.type} (confidence: ${classification.confidence})');
          print('Extracted entities: ${classification.entities}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('NLP classification failed, using fallback: $e');
        }
      }

      // Fallback to existing detection methods if NLP fails or low confidence
      final useNLPRouting =
          classification != null && classification.confidence > 0.6;

      final isGreeting = _utils.isGreeting(userMessage);
      final isStoreQuestion = _utils.isStoreQuestion(userMessage);
      final isProductQuestion = _utils.isProductQuestion(userMessage);
      final isFavoriteQuestion = _utils.isFavoriteQuestion(userMessage);
      final isCartQuestion = _utils.isCartQuestion(userMessage);
      final isCartQuantityQuestion = _utils.isCartQuantityQuestion(userMessage);
      final isVoucherQuestion = _utils.isVoucherQuestion(userMessage);
      final isAddToCartRequest = _utils.isAddToCartRequest(userMessage);

      // Process context if userId is provided
      final processedMessage = userId != null
          ? await _conversationService.processContext(userMessage, userId)
          : userMessage;

      // NEW: NLP-based routing (if classification succeeded with high confidence)
      if (useNLPRouting) {
        switch (classification.type) {
          case QuestionType.compatibility:
            return await _handleCompatibilityQuestion(processedMessage,
                classification.entities, userId, isVietnamese);

          case QuestionType.productSpec:
            return await _handleProductSpecQuestion(processedMessage,
                classification.entities, userId, isVietnamese);

          case QuestionType.promotion:
            return await _handleEnhancedQuery('promotion', processedMessage,
                classification.entities, userId, isVietnamese);

          case QuestionType.bestseller:
            return await _handleEnhancedQuery('bestseller', processedMessage,
                classification.entities, userId, isVietnamese);

          case QuestionType.buildSuggestion:
            return await _handleEnhancedQuery('build', processedMessage,
                classification.entities, userId, isVietnamese);

          case QuestionType.cartFavorites:
            // Route to existing cart/favorites handler
            return await _handleUserDataQuestion(
                userMessage,
                userId,
                isVietnamese,
                classification.entities['section'] == 'favorites',
                classification.entities['section'] == 'cart',
                false);

          // Add other NLP routes as needed
          default:
            // Fall through to existing logic
            break;
        }
      }

      // Existing routing logic (fallback)
      // Handle add to cart requests
      if (isAddToCartRequest) {
        return await _handleAddToCartRequest(userMessage, userId, isVietnamese);
      }

      // Handle voucher questions
      if (isVoucherQuestion) {
        final voucherResponse =
            await _handleVoucherQuestion(userMessage, userId, isVietnamese);
        // Attach product cards if products are mentioned
        return await _attachProductCardsToResponse(
          voucherResponse,
          processedMessage,
          isVietnamese,
        );
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
        if (isPronounOrReference) {
          if (kDebugMode) {
            print(
                'Extracted name "$productName" is a pronoun/reference, using context extraction');
          }
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

      // Detect if this is add to favorites vs add to cart
      final isFavorites = _utils.isFavoritesAction(userMessage);

      if (isFavorites) {
        // Add to favorites (no stock check, no quantity)
        final success = await _cartService.addProductToFavorites(
            userId, product['productID']);

        if (success) {
          final response = _cartService.getAddToFavoritesSuccessResponse(
                  product, isVietnamese) +
              contextInfo;
          _conversationService.updateHistory(userId, userMessage, response);
          return response;
        } else {
          final response = isVietnamese
              ? 'Xin lỗi, có lỗi xảy ra khi thêm sản phẩm vào yêu thích. Vui lòng thử lại sau.'
              : 'Sorry, an error occurred while adding the product to favorites. Please try again later.';
          _conversationService.updateHistory(userId, userMessage, response);
          return response;
        }
      } else {
        // Add to cart (with stock check and quantity)
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

    // Extract and attach product cards if products are mentioned
    final responseWithProducts = await _attachProductCardsToResponse(
      response,
      userMessage,
      isVietnamese,
    );

    _conversationService.updateHistory(
        userId, userMessage, responseWithProducts);
    return responseWithProducts;
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

    final productCardFilters = _buildProductCardFilters(
      brand: brand,
      productName: productName,
      synonyms: synonyms,
    );
    final disableCardFallback = brand.trim().isNotEmpty;

    // Detect sorting requirements from user query
    final sortType = _detectSortType(processedMessage, isVietnamese);

    final cardSelection = _prepareProductCardSelection(
      productsSnapshot.docs,
      isVietnamese: isVietnamese,
      keywordFilters: productCardFilters,
      disableFallbackOnEmptyMatch: disableCardFallback,
      limit: 3,
      sortType: sortType,
    );

    final prompt = cardSelection.docs.isNotEmpty
        ? _promptService.createPromptWithProducts(
            processedMessage, cardSelection.docs, isVietnamese)
        : _promptService.createPromptWithoutProducts(
            processedMessage, isVietnamese);
    final response = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));

    final formattedResponse = _formatProductSuggestionResponse(
      response,
      cardSelection.cards,
      isVietnamese,
    );

    // Ensure product cards are attached
    // DON'T pass existingCards - let extraction work from AI response
    // This ensures only products actually mentioned by the AI are shown
    final responseWithProducts = await _attachProductCardsToResponse(
      formattedResponse,
      processedMessage,
      isVietnamese,
    );

    if (userId != null) {
      _conversationService.updateHistory(
          userId, processedMessage, responseWithProducts);
    }

    return responseWithProducts;
  }

  /// Extract product mentions from any response and attach ProductMiniCard widgets
  /// This ensures products are always navigable, not just in product questions
  /// Maximum 3 cards per response, only for products actually mentioned in the response
  Future<String> _attachProductCardsToResponse(
    String response,
    String originalMessage,
    bool isVietnamese, {
    List<Map<String, dynamic>>? existingCards,
    bool skipExtraction = false, // Skip extracting products from response text
  }) async {
    // If cards already exist, limit to max 3
    if (existingCards != null && existingCards.isNotEmpty) {
      final limitedCards = existingCards.take(3).toList();
      final productCardsAttachment =
          '[PRODUCT_CARDS]${jsonEncode(limitedCards)}[/PRODUCT_CARDS]';
      return '$response\n\n$productCardsAttachment';
    }

    // If existingCards was provided but is empty, don't render any cards
    if (existingCards != null && existingCards.isEmpty) {
      return response; // No products to show, skip card rendering
    }

    // Check if response already has product cards
    if (response.contains('[PRODUCT_CARDS]')) {
      return response;
    }

    // Skip extraction if requested (e.g., for spec queries with predefined cards)
    if (skipExtraction) {
      return response;
    }

    // Skip extraction for non-product queries (voucher, account, general questions)
    if (_isNonProductQuery(originalMessage)) {
      if (kDebugMode) {
        print(
            'Skipping product card extraction for non-product query: $originalMessage');
      }
      return response;
    }

    // Extract product names and brands from the response (only products actually mentioned)
    // Use NLP first, fallback to regex if needed
    final extractionResult =
        await _extractProductNamesAndBrandsFromResponse(response, isVietnamese);
    final productNames = extractionResult['product_names'] ?? [];
    final mentionedBrands = extractionResult['brands'] ?? [];

    if (kDebugMode) {
      print('Found product mentions in response: $productNames');
      print('Found brand mentions in response: $mentionedBrands');
    }

    // Filter product names - only keep FULL product names with specs
    // This prevents extracting generic terms like "Core i7" or "Ultra 7"
    final filteredProductNames = productNames.where((name) {
      final lowerName = name.toString().toLowerCase();
      // Must have model number (digits) AND some spec indicators
      final hasModelNumber =
          RegExp(r'\d{4,5}').hasMatch(lowerName); // 12700, 4070, etc.
      final hasSpecs = RegExp(r'(ghz|gb|mb|core|thread|w\b)')
          .hasMatch(lowerName); // GHz, GB, cores, etc.
      return hasModelNumber && hasSpecs;
    }).toList();

    if (kDebugMode && filteredProductNames.length != productNames.length) {
      if (kDebugMode) {
        print(
            'Filtered generic product names. Keeping only specific mentions: $filteredProductNames');
      }
    }

    if (filteredProductNames.isEmpty) {
      return response; // No specific products to attach
    }
    // Search for products - limit to first 3 product names mentioned
    final isConnected = await _productService.checkFirebaseConnection();
    if (!isConnected) {
      return response;
    }

    final List<Map<String, dynamic>> productCards = [];
    final Set<String> addedProductIds = {};
    final List<String> unavailableProducts = [];
    final List<String> suggestionMessages = [];

    // For each mentioned product name, find the best matching product
    for (final productName in filteredProductNames.take(3)) {
      if (productCards.length >= 3) break;

      bool exactMatchFound = false;

      // First try using findProductByName which has better similarity matching
      final foundProduct = await _productService.findProductByName(productName);

      if (foundProduct != null && foundProduct['productID'] != null) {
        final productId = foundProduct['productID'] as String;
        final data = foundProduct;
        final foundProductName =
            (data['productName'] ?? '').toString().toLowerCase();
        final normalizedMention = productName.toLowerCase();

        // Check if this is an exact or very close match (similarity > 0.8)
        bool isExactMatch = false;
        if (foundProductName == normalizedMention) {
          isExactMatch = true;
        } else if (foundProductName.contains(normalizedMention) ||
            normalizedMention.contains(foundProductName)) {
          // Check word overlap for high similarity
          final mentionWords = normalizedMention.split(RegExp(r'[\s\-]+'));
          final foundWords = foundProductName.split(RegExp(r'[\s\-]+'));
          final commonWords =
              mentionWords.where((w) => foundWords.contains(w)).length;
          final similarity =
              commonWords / (mentionWords.isNotEmpty ? mentionWords.length : 1);

          // Require high similarity AND matching specs (capacity, speed, etc.)
          if (similarity >= 0.8) {
            // Extract specs from both mention and found product
            final mentionSpecs = _extractSpecsFromText(productName);
            final foundSpecs = _extractSpecsFromProduct(data);

            // Check if key specs match (capacity, speed, cores, etc.)
            final specsMatch = _doSpecsMatch(mentionSpecs, foundSpecs);

            if (kDebugMode) {
              print(
                  'Mention specs: $mentionSpecs, Found specs: $foundSpecs, Match: $specsMatch');
            }

            isExactMatch = specsMatch;
          }
        }

        if (isExactMatch && !addedProductIds.contains(productId)) {
          // Exact match found - add it
          exactMatchFound = true;

          // Check brand match if brands are mentioned in response
          if (mentionedBrands.isNotEmpty) {
            final productBrand = _extractBrandFromProduct(data);
            final brandMatches = mentionedBrands.any((mentionedBrand) =>
                productBrand
                    .toLowerCase()
                    .contains(mentionedBrand.toLowerCase()) ||
                mentionedBrand
                    .toLowerCase()
                    .contains(productBrand.toLowerCase()));

            if (!brandMatches) {
              if (kDebugMode) {
                print(
                    'Product ${data['productName']} brand mismatch. Product brand: $productBrand, Mentioned brands: $mentionedBrands.');
              }
            }
          }

          final sellingPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
          final discount = (data['discount'] as num?)?.toDouble() ?? 0;
          final discountedPrice =
              (data['discountedPrice'] as num?)?.toDouble() ??
                  sellingPrice * (1 - discount / 100);
          final category = data['category']?.toString() ?? '';

          productCards.add({
            'id': productId,
            'name': data['productName'] ?? '',
            'price': discountedPrice,
            'originalPrice': sellingPrice,
            'discount': discount,
            'stock': data['stock'] ?? 0,
            'imageUrl': data['imageUrl'],
            'category': category,
          });

          addedProductIds.add(productId);
          continue; // Skip to next product name
        }
      }

      // If no exact match found, try fallback search
      if (!exactMatchFound) {
        final productsSnapshot = await _productService.searchProducts(
          keyword: productName,
        );

        QueryDocumentSnapshot? bestMatch;
        double bestScore = 0.0;

        if (productsSnapshot.docs.isNotEmpty) {
          // Find the best match for this product name
          for (final doc in productsSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final docProductName =
                (data['productName'] ?? '').toString().toLowerCase();
            final normalizedMention = productName.toLowerCase();

            // Calculate similarity score
            double score = 0.0;
            if (docProductName == normalizedMention) {
              score = 1.0;
            } else if (docProductName.contains(normalizedMention) ||
                normalizedMention.contains(docProductName)) {
              score = 0.8;
            } else {
              // Calculate word overlap
              final mentionWords = normalizedMention.split(RegExp(r'[\s\-]+'));
              final docWords = docProductName.split(RegExp(r'[\s\-]+'));
              final commonWords =
                  mentionWords.where((w) => docWords.contains(w)).length;
              score = commonWords /
                  (mentionWords.isNotEmpty ? mentionWords.length : 1);
            }

            if (score > bestScore && !addedProductIds.contains(doc.id)) {
              bestScore = score;
              bestMatch = doc;
            }
          }

          // Only consider it an exact match if score is very high (>= 0.8)
          if (bestMatch != null && bestScore >= 0.8) {
            exactMatchFound = true;
            final doc = bestMatch;
            final data = doc.data() as Map<String, dynamic>;

            final sellingPrice =
                (data['sellingPrice'] as num?)?.toDouble() ?? 0;
            final discount = (data['discount'] as num?)?.toDouble() ?? 0;
            final discountedPrice =
                (data['discountedPrice'] as num?)?.toDouble() ??
                    sellingPrice * (1 - discount / 100);
            final category = data['category']?.toString() ?? '';

            productCards.add({
              'id': doc.id,
              'name': data['productName'] ?? '',
              'price': discountedPrice,
              'originalPrice': sellingPrice,
              'discount': discount,
              'stock': data['stock'] ?? 0,
              'imageUrl': data['imageUrl'],
              'category': category,
            });

            addedProductIds.add(doc.id);
            continue; // Skip to next product name
          }
        }

        // No exact match found - mark as unavailable and get suggestions
        if (!exactMatchFound) {
          unavailableProducts.add(productName);

          // Get similar product suggestions
          final suggestions =
              await _productService.getProductSuggestions(productName);

          // Filter suggestions to only include those with reasonable similarity (> 0.3)
          final filteredSuggestions = suggestions.where((suggestion) {
            final similarityScore =
                suggestion['similarityScore'] as double? ?? 0.0;

            // Must have reasonable similarity
            return similarityScore >= 0.3;
          }).toList();

          // Add top suggestions (up to 2 per unavailable product, max 3 total)
          for (final suggestion in filteredSuggestions.take(2)) {
            if (productCards.length >= 3) break;
            if (addedProductIds.contains(suggestion['productID'])) continue;

            final sellingPrice =
                (suggestion['sellingPrice'] as num?)?.toDouble() ?? 0;
            final discount = (suggestion['discount'] as num?)?.toDouble() ?? 0;
            final discountedPrice =
                (suggestion['discountedPrice'] as num?)?.toDouble() ??
                    sellingPrice * (1 - discount / 100);
            final category = suggestion['category']?.toString() ?? '';

            productCards.add({
              'id': suggestion['productID'],
              'name': suggestion['productName'] ?? '',
              'price': discountedPrice,
              'originalPrice': sellingPrice,
              'discount': discount,
              'stock': suggestion['stock'] ?? 0,
              'imageUrl': suggestion['imageUrl'],
              'category': category,
            });

            addedProductIds.add(suggestion['productID'] as String);
          }
        }
      }
    }

    // Add notification messages for unavailable products
    if (unavailableProducts.isNotEmpty) {
      String notificationMessage = '';
      if (isVietnamese) {
        notificationMessage =
            'Rất tiếc, shop hiện không có sản phẩm "${unavailableProducts.join('", "')}". ';
        if (productCards.isNotEmpty) {
          notificationMessage +=
              'Dưới đây là một số sản phẩm tương tự bạn có thể quan tâm:';
        }
      } else {
        notificationMessage =
            'Sorry, we currently don\'t have "${unavailableProducts.join('", "')}" in stock. ';
        if (productCards.isNotEmpty) {
          notificationMessage +=
              'Here are some similar products you might be interested in:';
        }
      }
      suggestionMessages.add(notificationMessage);
    }

    // Add notification messages before product cards if there are unavailable products
    String finalResponse = response;
    if (suggestionMessages.isNotEmpty) {
      finalResponse = '$response\n\n${suggestionMessages.join('\n')}';
    }

    if (productCards.isEmpty) {
      return finalResponse;
    }

    // Create product cards - maximum 3
    final limitedCards = productCards.take(3).toList();
    final productCardsAttachment =
        '[PRODUCT_CARDS]${jsonEncode(limitedCards)}[/PRODUCT_CARDS]';
    return '$finalResponse\n\n$productCardsAttachment';
  }

  /// Extract product names and brands from AI response text using NLP
  /// Only extracts products actually mentioned in the response, not all possible products
  Future<Map<String, List<String>>> _extractProductNamesAndBrandsFromResponse(
      String response, bool isVietnamese) async {
    // Remove product card markup to avoid extracting from card data
    final cleanedResponse = response.replaceAll(
        RegExp(r'\[PRODUCT_CARDS\].*?\[/PRODUCT_CARDS\]', dotAll: true), '');

    // First, try using NLP to extract product names and brands intelligently
    try {
      final nlpResult = await _nlpService.extractProductNamesAndBrands(
          cleanedResponse, isVietnamese);
      if (nlpResult['product_names']!.isNotEmpty ||
          nlpResult['brands']!.isNotEmpty) {
        if (kDebugMode) {
          print('NLP extracted product names: ${nlpResult['product_names']}');
          print('NLP extracted brands: ${nlpResult['brands']}');
        }
        return {
          'product_names': nlpResult['product_names']!.take(3).toList(),
          'brands': nlpResult['brands']!.take(3).toList(),
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('NLP extraction failed, falling back to regex: $e');
      }
    }

    // Fallback to regex patterns if NLP fails
    final productNames = <String>{};
    final brands = <String>{};

    // Extract from [PRODUCT_NAME:...] format (used in prompts)
    final productNamePattern = RegExp(r'\[PRODUCT_NAME:([^\]]+)\]');
    for (final match in productNamePattern.allMatches(cleanedResponse)) {
      final name = match.group(1)?.trim();
      if (name != null && name.isNotEmpty && name.length > 3) {
        productNames.add(name);
        // Extract brand from product name
        final brand = _extractBrandFromProductName(name);
        if (brand.isNotEmpty) {
          brands.add(brand);
        }
      }
    }

    // Extract using regex patterns for product names that appear in the response text
    final productPatterns = [
      // Match full product names like "Intel Core i7-12700K" or "Intel Core i7 12700K" (with or without dash)
      RegExp(
          r'\b(?:CPU\s+)?(?:Intel|AMD|NVIDIA|Samsung|Kingston|Corsair|ASUS|MSI|Gigabyte)\s+(?:Core\s+(?:Ultra\s*[3579]\s*\d+[A-Z]*|i[3579]\s*\d+[A-Z\-]*)|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*|HyperX\s+Fury|DDR\d+)\b',
          caseSensitive: false,
          unicode: true),
      // Match "i7-12700K" or "i7 12700K" format (short form)
      RegExp(r'\b(?:i[3579]|Ryzen\s*[3579]|RTX|GTX)\s*[\-]?\s*\d+[A-Z]*\b',
          caseSensitive: false, unicode: true),
      // Match brand + product combinations
      RegExp(
          r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\s+(?:HyperX\s+)?(?:Fury|Core|Ryzen|RTX|GTX|DDR\d+)\s+(?:\d+[A-Z\-]*|[^\s]+(?:\s+[^\s]+)*)',
          caseSensitive: false,
          unicode: true),
      // Match product model numbers with dashes
      RegExp(
          r'\b(?:Core\s+(?:Ultra\s*[3579]\s*\d+[A-Z]*|i[3579]\s*\d+[A-Z\-]*)|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*)\b',
          caseSensitive: false,
          unicode: true),
    ];

    for (final pattern in productPatterns) {
      for (final match in pattern.allMatches(cleanedResponse)) {
        final name = match.group(0)?.trim();
        if (name != null && name.isNotEmpty && name.length > 3) {
          // Clean the product name
          final cleanedName = _utils.cleanProductName(name);
          if (cleanedName.isNotEmpty) {
            productNames.add(cleanedName);
            // Extract brand from product name
            final brand = _extractBrandFromProductName(cleanedName);
            if (brand.isNotEmpty) {
              brands.add(brand);
            }
          }
        }
      }
    }

    // Also use the existing extraction method as fallback
    final extractedName = _utils.extractProductNameFromText(cleanedResponse);
    if (extractedName != null && extractedName.isNotEmpty) {
      productNames.add(extractedName);
      final brand = _extractBrandFromProductName(extractedName);
      if (brand.isNotEmpty) {
        brands.add(brand);
      }
    }

    // Extract standalone brand mentions
    final brandPattern = RegExp(
        r'\b(Intel|AMD|NVIDIA|Samsung|Kingston|Corsair|ASUS|MSI|Gigabyte)\b',
        caseSensitive: false);
    for (final match in brandPattern.allMatches(cleanedResponse)) {
      final brand = match.group(1);
      if (brand != null && brand.isNotEmpty) {
        brands.add(brand);
      }
    }

    // Return unique product names and brands, limited to first 3 mentioned
    return {
      'product_names': productNames.take(3).toList(),
      'brands': brands.take(3).toList(),
    };
  }

  /// Extract product names from AI response text using NLP (legacy method, kept for compatibility)
  /// Only extracts products actually mentioned in the response, not all possible products
  // Future<List<String>> _extractProductNamesFromResponse(
  //     String response, bool isVietnamese) async {
  //   // Remove product card markup to avoid extracting from card data
  //   final cleanedResponse = response.replaceAll(
  //       RegExp(r'\[PRODUCT_CARDS\].*?\[/PRODUCT_CARDS\]', dotAll: true), '');

  //   // First, try using NLP to extract product names intelligently
  //   try {
  //     final nlpProductNames = await _nlpService.extractProductNamesFromText(
  //         cleanedResponse, isVietnamese);
  //     if (nlpProductNames.isNotEmpty) {
  //       if (kDebugMode) {
  //         print('NLP extracted product names: $nlpProductNames');
  //       }
  //       return nlpProductNames.take(3).toList();
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('NLP extraction failed, falling back to regex: $e');
  //     }
  //   }

  //   // Fallback to regex patterns if NLP fails
  //   final productNames = <String>{};

  //   // Extract from [PRODUCT_NAME:...] format (used in prompts)
  //   final productNamePattern = RegExp(r'\[PRODUCT_NAME:([^\]]+)\]');
  //   for (final match in productNamePattern.allMatches(cleanedResponse)) {
  //     final name = match.group(1)?.trim();
  //     if (name != null && name.isNotEmpty && name.length > 3) {
  //       productNames.add(name);
  //     }
  //   }

  //   // Extract using regex patterns for product names that appear in the response text
  //   final productPatterns = [
  //     // Match full product names like "Intel Core i7-12700K" or "Intel Core i7 12700K" (with or without dash)
  //     RegExp(
  //         r'\b(?:CPU\s+)?(?:Intel|AMD|NVIDIA|Samsung|Kingston|Corsair|ASUS|MSI|Gigabyte)\s+(?:Core\s+(?:Ultra\s*[3579]\s*\d+[A-Z]*|i[3579]\s*\d+[A-Z\-]*)|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*|HyperX\s+Fury|DDR\d+)\b',
  //         caseSensitive: false,
  //         unicode: true),
  //     // Match "i7-12700K" or "i7 12700K" format (short form)
  //     RegExp(r'\b(?:i[3579]|Ryzen\s*[3579]|RTX|GTX)\s*[\-]?\s*\d+[A-Z]*\b',
  //         caseSensitive: false, unicode: true),
  //     // Match brand + product combinations
  //     RegExp(
  //         r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\s+(?:HyperX\s+)?(?:Fury|Core|Ryzen|RTX|GTX|DDR\d+)\s+(?:\d+[A-Z\-]*|[^\s]+(?:\s+[^\s]+)*)',
  //         caseSensitive: false,
  //         unicode: true),
  //     // Match product model numbers with dashes
  //     RegExp(
  //         r'\b(?:Core\s+(?:Ultra\s*[3579]\s*\d+[A-Z]*|i[3579]\s*\d+[A-Z\-]*)|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*)\b',
  //         caseSensitive: false,
  //         unicode: true),
  //   ];

  //   for (final pattern in productPatterns) {
  //     for (final match in pattern.allMatches(cleanedResponse)) {
  //       final name = match.group(0)?.trim();
  //       if (name != null && name.isNotEmpty && name.length > 3) {
  //         // Clean the product name
  //         final cleanedName = _utils.cleanProductName(name);
  //         if (cleanedName.isNotEmpty) {
  //           productNames.add(cleanedName);
  //         }
  //       }
  //     }
  //   }

  //   // Also use the existing extraction method as fallback
  //   final extractedName = _utils.extractProductNameFromText(cleanedResponse);
  //   if (extractedName != null && extractedName.isNotEmpty) {
  //     productNames.add(extractedName);
  //   }

  //   // Return unique product names, limited to first 3 mentioned
  //   return productNames.take(3).toList();
  // }

  Future<String> _handleGeneralQuestion(
      String processedMessage, String? userId, bool isVietnamese) async {
    final prompt = _promptService.createPromptWithoutProducts(
        processedMessage, isVietnamese);
    final response = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));

    // Extract and attach product cards if products are mentioned
    final responseWithProducts = await _attachProductCardsToResponse(
      response,
      processedMessage,
      isVietnamese,
    );

    if (userId != null) {
      _conversationService.updateHistory(
          userId, processedMessage, responseWithProducts);
    }

    return responseWithProducts;
  }

  /// Handle compatibility questions using CompatibilityHandler
  Future<String> _handleCompatibilityQuestion(
    String userMessage,
    Map<String, dynamic> entities,
    String? userId,
    bool isVietnamese,
  ) async {
    final result = await _compatibilityHandler.handleCompatibilityQuestion(
      userMessage,
      entities,
      isVietnamese,
    );

    if (!result['success']) {
      return result['message'];
    }

    // Products are already QueryDocumentSnapshots from Firestore
    final docs = result['products'] as List<QueryDocumentSnapshot>;

    final prompt = _promptService.createPromptWithProducts('''
${result['context']}

YÊU CẦU: $userMessage

⚠️ QUY TẮC:
- CHỈ liệt kê TÊN SẢN PHẨM từ danh sách
- KHÔNG tự tạo tên sản phẩm
- Giữ câu trả lời NGẮN GỌN (2-3 câu)
- Product cards sẽ tự hiển thị details

TRẢ LỜI:
1. Trả lời ngắn gọn về ${result['context']}
2. Liệt kê tên sản phẩm phù hợp
''', docs, isVietnamese);

    final aiResponse = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));

    return await _attachProductCardsToResponse(
        aiResponse, userMessage, isVietnamese,
        existingCards:
            docs.take(5).map((d) => d.data() as Map<String, dynamic>).toList());
  }

  /// Handle product specification questions
  /// e.g., "i7 12700 thuộc socket nào?", "ram corsair dominator bao nhiêu gb?"
  Future<String> _handleProductSpecQuestion(
    String userMessage,
    Map<String, dynamic> entities,
    String? userId,
    bool isVietnamese,
  ) async {
    try {
      // Extract product name from entities
      final productNames = entities['product_names'] as List?;

      if (productNames == null || productNames.isEmpty) {
        return isVietnamese
            ? 'Vui lòng cho tôi biết tên sản phẩm bạn muốn hỏi về thông số kỹ thuật.'
            : 'Please tell me which product you want to know the specifications for.';
      }

      final productName = productNames.first.toString();

      if (kDebugMode) {
        print('🔍 Product Spec Query - Extracted product name: "$productName"');
      }

      // Search for product in Firestore
      final searchQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'active')
          .get();

      // Find best matching product with scoring
      QueryDocumentSnapshot? matchedProduct;
      double bestScore = 0.0;
      String? bestMatchName;

      // Normalize: remove spaces, dashes, and lowercase
      final normalizedQuery =
          productName.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '');

      for (var doc in searchQuery.docs) {
        final data = doc.data();
        final name = data['productName']?.toString().toLowerCase() ?? '';
        final normalizedName = name.replaceAll(RegExp(r'[\s-]+'), '');

        double score = 0.0;

        // Exact match (highest priority)
        if (normalizedName == normalizedQuery) {
          score = 100.0;
        }
        // Query is exact substring of name
        else if (normalizedName.contains(normalizedQuery)) {
          // Check if query matches end of name (before any version suffix)
          final afterQueryFull = normalizedName.substring(
              normalizedName.indexOf(normalizedQuery) + normalizedQuery.length);

          // Extract only alphanumeric characters after the match (ignore /, spaces, etc.)
          final afterQuery =
              afterQueryFull.replaceAll(RegExp(r'[^a-z0-9]'), '');

          if (afterQuery.isEmpty) {
            // Perfect end match: "i712700" in "intelcorei712700" or "intelcorei712700/..."
            score = 95.0;
          }
          // Check if starts with a NUMBER (e.g., "21ghz" from "/2.1GHz")
          // This means we matched the full model number, and what follows is a different spec
          else if (RegExp(r'^[0-9]').hasMatch(afterQuery)) {
            // Perfect match - what follows is clock speed or other spec, not a version suffix
            score = 95.0;
          }
          // Check if starts with version suffix LETTER
          else if (RegExp(r'^[kfx]').hasMatch(afterQuery)) {
            // Starts with single-char version suffix: "i712700" in "intelcorei712700k36ghz..."
            score = 50.0;
          } else if (RegExp(r'^(ti|xt|kf|ks|super)').hasMatch(afterQuery)) {
            // Starts with known multi-char suffix
            score = 50.0;
          } else {
            // Other text after query (different product variant)
            score = 30.0;
          }
        }
        // Fallback: original contains check
        else if (name.contains(productName.toLowerCase())) {
          score = 20.0;
        }

        if (score > bestScore) {
          bestScore = score;
          matchedProduct = doc;
          bestMatchName = data['productName']?.toString();
        }

        // Debug: Show top scoring products
        if (kDebugMode && score > 0) {
          if (kDebugMode) {
            print('  - "${data['productName']}" → score: $score');
          }
        }
      }

      if (kDebugMode) {
        print('🎯 Best match: "$bestMatchName" with score: $bestScore');
      }

      if (matchedProduct == null) {
        if (kDebugMode) {
          print('❌ No product matched for: "$productName"');
        }
        return isVietnamese
            ? 'Không tìm thấy sản phẩm "$productName" trong hệ thống.'
            : 'Product "$productName" not found in the system.';
      }

      if (kDebugMode) {
        print('✅ Product found! ID: ${matchedProduct.id}');
      }

      final productData = matchedProduct.data() as Map<String, dynamic>;
      final fullProductName = productData['productName'] ?? productName;

      if (kDebugMode) {
        print('📦 Full product name: "$fullProductName"');
        print('🔧 Product data keys: ${productData.keys.toList()}');
      }

      // Build context with product info and the spec question

      // Create a very simple, direct prompt to prevent AI from mentioning wrong products
      final String aiPrompt;
      if (isVietnamese) {
        aiPrompt = '''
🚨 CHỈ TRẢ LỜI VỀ SẢN PHẨM NÀY - KHÔNG ĐƯỢC NÓI VỀ SẢN PHẨM KHÁC:

SẢN PHẨM: $fullProductName
CÂU HỎI: $userMessage

⛔ CẤM TUYỆT ĐỐI:
- KHÔNG được đề cập đến bất kỳ sản phẩm nào khác
- KHÔNG được gợi ý sản phẩm khác (i7-14700K, i7-13700K, Ultra 7...)  
- KHÔNG được liệt kê các lựa chọn khác
- KHÔNG được nói "có thể quan tâm" hay "tương tự"
- CHỈ trả lời ĐÚNG về sản phẩm: "$fullProductName"

QUY TẮC:
- Chỉ 1 câu ngắn duy nhất
- Trả lời ĐÚNG thông số được hỏi của SẢN PHẨM NÀY
- Dùng CHÍNH XÁC tên: "$fullProductName"

TRẢ LỜI (1 CÂU):
''';
      } else {
        aiPrompt = '''
🚨 ONLY ANSWER ABOUT THIS PRODUCT - DO NOT MENTION OTHER PRODUCTS:

PRODUCT: $fullProductName  
QUESTION: $userMessage

⛔ ABSOLUTELY FORBIDDEN:
- DO NOT mention any other products
- DO NOT suggest alternatives (i7-14700K, i7-13700K, Ultra 7...)
- DO NOT list other options
- DO NOT say "you might be interested" or "similar"
- ONLY answer about: "$fullProductName"

RULES:
- Only 1 short sentence
- Answer ONLY the asked specification of THIS PRODUCT
- Use EXACT name: "$fullProductName"

ANSWER (1 SENTENCE):
''';
      }

      final aiResponse =
          _utils.sanitizeMarkdown(await _callGeminiAPI(aiPrompt));

      // Format product data for card display
      final sellingPrice =
          (productData['sellingPrice'] as num?)?.toDouble() ?? 0;
      final discount = (productData['discount'] as num?)?.toDouble() ?? 0;
      final discountedPrice =
          (productData['discountedPrice'] as num?)?.toDouble() ??
              sellingPrice * (1 - discount / 100);
      final category = productData['category']?.toString() ?? '';

      final formattedCard = {
        'id': matchedProduct.id,
        'name': fullProductName,
        'price': discountedPrice,
        'originalPrice': sellingPrice,
        'discount': discount,
        'stock': productData['stock'] ?? 0,
        'imageUrl': productData['imageUrl'],
        'category': category,
      };

      // Attach product card (only the queried product, don't extract from response)
      return await _attachProductCardsToResponse(
        aiResponse,
        userMessage,
        isVietnamese,
        existingCards: [formattedCard],
        skipExtraction:
            true, // Don't extract products from AI response for spec queries
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error in _handleProductSpecQuestion: $e');
        print('Stack trace: $stackTrace');
      }
      return isVietnamese
          ? 'Xin lỗi, có lỗi xảy ra khi xử lý câu hỏi của bạn.'
          : 'Sorry, an error occurred while processing your question.';
    }
  }

  /// Handle enhanced queries (promotion, bestseller, build)
  Future<String> _handleEnhancedQuery(
    String queryType,
    String userMessage,
    Map<String, dynamic> entities,
    String? userId,
    bool isVietnamese,
  ) async {
    Map<String, dynamic> result;

    switch (queryType) {
      case 'promotion':
        result = await _enhancedHandlers.handlePromotionQuery(
          userMessage,
          entities,
          isVietnamese,
        );
        break;
      case 'bestseller':
        result = await _enhancedHandlers.handleBestsellerQuery(
          userMessage,
          entities,
          isVietnamese,
        );
        break;
      case 'build':
        result = await _enhancedHandlers.handleBuildSuggestion(
          userMessage,
          entities,
          isVietnamese,
        );
        break;
      default:
        return await _handleGeneralQuestion(userMessage, userId, isVietnamese);
    }

    if (!result['success']) {
      return result['message'];
    }

    final products = result['products'] as List<QueryDocumentSnapshot>;

    // Extract the requested number from user message (e.g., "top 3" → 3)
    // For build suggestions, allow more cards to show all components
    int requestedCount =
        (queryType == 'build') ? 6 : 5; // Build needs 6 cards (1 per component)
    int maxLimit = (queryType == 'build') ? 6 : 5; // Different limits
    bool countExceedsLimit = false;

    final topMatch =
        RegExp(r'top\s*(\d+)', caseSensitive: false).firstMatch(userMessage);
    if (topMatch != null) {
      final parsedCount = int.tryParse(topMatch.group(1)!) ?? requestedCount;
      if (parsedCount > maxLimit) {
        countExceedsLimit = true;
        requestedCount = maxLimit; // Cap at limit
      } else {
        requestedCount = parsedCount;
      }
    }

    // Add warning if user requested more than limit
    String warningMessage = '';
    if (countExceedsLimit) {
      warningMessage = isVietnamese
          ? '\n\n⚠️ *Lưu ý: Hiện tại hệ thống chỉ hỗ trợ hiển thị tối đa $maxLimit sản phẩm. Dưới đây là top $maxLimit sản phẩm phù hợp nhất.*\n'
          : '\n\n⚠️ *Note: The system currently supports displaying a maximum of $maxLimit products. Below are the top $maxLimit best matches.*\n';
    }

    // Create a simpler prompt for bestseller/promotion queries
    String promptInstructions = '';
    if (queryType == 'promotion') {
      promptInstructions = '''
${result['context']}

YÊU CẦU: $userMessage

⚠️ QUY TẮC:
- CHỈ liệt kê danh sách NGẮN GỌN
- Format: "- [Tên sản phẩm]: [Giá] (Giảm [discount]%)"
- KHÔNG phân tích, KHÔNG so sánh, KHÔNG giải thích
- Product cards sẽ tự hiển thị chi tiết

NHIỆM VỤ:
Liệt kê $requestedCount sản phẩm khuyến mãi từ danh sách dưới đây:
''';
    } else if (queryType == 'bestseller') {
      promptInstructions = '''
${result['context']}

YÊU CẦU: $userMessage

⚠️ QUY TẮC:
- CHỈ liệt kê danh sách NGẮN GỌN
- Format: "- [Tên sản phẩm]: [Giá] ([sales] lượt bán)"
- KHÔNG phân tích, KHÔNG so sánh, KHÔNG giải thích
- Product cards sẽ tự hiển thị chi tiết

NHIỆM VỤ:
Liệt kê top $requestedCount sản phẩm bán chạy từ danh sách dưới đây:
''';
    } else {
      // Build suggestion - MUST list all 6 components
      promptInstructions = '''
${result['context']}

YÊU CẦU: $userMessage

⚠️ QUY TẮC QUAN TRỌNG:
- PHẢI liệt kê ĐẦY ĐỦ 6 linh kiện:
  1. CPU
  2. GPU
  3. RAM
  4. Mainboard
  5. Drive (SSD/HDD)
  6. PSU (Nguồn)
- Format NGẮN GỌN (CHỈ tên và giá):
  - CPU: [Tên] - [Giá]
  - Mainboard: [Tên] - [Giá]
  - RAM: [Tên] - [Giá]
  - GPU: [Tên] - [Giá]
  - Drive: [Tên] - [Giá]
  - PSU: [Tên] - [Giá]
  
  Tổng: [Tổng giá]
- CHỈ recommend sản phẩm TỪ DANH SÁCH bên dưới
- KHÔNG bỏ qua bất kỳ linh kiện nào
- TẤT CẢ 6 linh kiện đều tương thích với nhau

NHIỆM VỤ:
List ĐẦY ĐỦ 6 linh kiện từ danh sách dưới đây:
''';
    }

    final prompt = _promptService.createPromptWithProducts(
        promptInstructions, products, isVietnamese);

    final aiResponse = _utils.sanitizeMarkdown(await _callGeminiAPI(prompt));

    // Prepend warning if user requested more than limit
    final finalResponse = warningMessage + aiResponse;

    // Convert QueryDocumentSnapshots to card format (limit to requested count)
    final productCards = products.take(requestedCount).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final sellingPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
      final discount = (data['discount'] as num?)?.toDouble() ?? 0;
      final discountedPrice = (data['discountedPrice'] as num?)?.toDouble() ??
          sellingPrice * (1 - discount / 100);
      final category = data['category']?.toString() ?? '';

      return {
        'id': doc.id,
        'name': data['productName'] ?? '',
        'price': discountedPrice,
        'originalPrice': sellingPrice,
        'discount': discount,
        'stock': data['stock'] ?? 0,
        'imageUrl': data['imageUrl'],
        'category': category,
      };
    }).toList();

    return await _attachProductCardsToResponse(
      finalResponse,
      userMessage,
      isVietnamese,
      existingCards: productCards,
    );
  }

  Future<String> _callGeminiAPI(String prompt) async {
    // On web, use Cloud Function proxy to keep API key secure
    if (kIsWeb) {
      return await _callGeminiViaProxy(prompt);
    }

    // On mobile, use direct API call
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

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            final candidates = responseData['candidates'] as List;
            if (candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              final parts = content['parts'] as List;
              if (parts.isNotEmpty) {
                if (useFallback) {
                  if (kDebugMode) {
                    print('Successfully used fallback model: $model');
                  }
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

  /// Call Gemini API via Cloud Function proxy (for web platform)
  Future<String> _callGeminiViaProxy(String prompt) async {
    const proxyUrl =
        'https://us-central1-se121p11-gizmoglobe.cloudfunctions.net/geminiProxy';
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse(proxyUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            return responseData['response'] as String? ?? '';
          } else {
            throw Exception('Gemini Proxy error: ${responseData['error']}');
          }
        } else {
          throw Exception('Gemini Proxy failed: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Failed to get response from Gemini Proxy');
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

  /// Extract specifications from text (capacity, speed, cores, etc.)
  Map<String, String> _extractSpecsFromText(String text) {
    final specs = <String, String>{};
    final lowerText = text.toLowerCase();

    // Extract capacity (GB, TB, MB)
    final capacityPattern = RegExp(r'(\d+)\s*(gb|tb|mb)', caseSensitive: false);
    final capacityMatch = capacityPattern.firstMatch(lowerText);
    if (capacityMatch != null) {
      specs['capacity'] =
          '${capacityMatch.group(1)}${capacityMatch.group(2)}'.toLowerCase();
    }

    // Extract speed (MHz, GHz)
    final speedPattern = RegExp(r'(\d+)\s*(mhz|ghz)', caseSensitive: false);
    final speedMatch = speedPattern.firstMatch(lowerText);
    if (speedMatch != null) {
      specs['speed'] =
          '${speedMatch.group(1)}${speedMatch.group(2)}'.toLowerCase();
    }

    // Extract cores
    final coresPattern = RegExp(r'(\d+)\s*cores?', caseSensitive: false);
    final coresMatch = coresPattern.firstMatch(lowerText);
    if (coresMatch != null) {
      specs['cores'] = coresMatch.group(1)!;
    }

    // Extract TDP
    final tdpPattern = RegExp(r'(\d+)\s*w\b', caseSensitive: false);
    final tdpMatch = tdpPattern.firstMatch(lowerText);
    if (tdpMatch != null) {
      specs['tdp'] = tdpMatch.group(1)!;
    }

    return specs;
  }

  /// Extract specifications from product data
  Map<String, String> _extractSpecsFromProduct(Map<String, dynamic> data) {
    final specs = <String, String>{};
    final attrs = data['attributes'] as Map<String, dynamic>?;

    // Capacity (for RAM, GPU, Drive)
    final capacity = data['capacity'] ?? attrs?['memory'] ?? attrs?['memoryGb'];
    if (capacity != null) {
      // Normalize to format like "16gb", "1tb"
      final capacityStr = capacity.toString().toLowerCase().replaceAll(' ', '');
      specs['capacity'] = capacityStr;
    }

    // Speed/Bus (for RAM)
    final bus = data['bus'] ?? attrs?['bus'];
    if (bus != null) {
      specs['speed'] = '${bus}mhz';
    }

    // Cores (for CPU)
    final cores = data['core'] ?? attrs?['core'];
    if (cores != null) {
      specs['cores'] = cores.toString();
    }

    // TDP (for CPU/GPU)
    final tdp = attrs?['tdp'];
    if (tdp != null) {
      specs['tdp'] = tdp.toString();
    }

    return specs;
  }

  /// Check if specs match between mentioned product and found product
  bool _doSpecsMatch(
      Map<String, String> mentionSpecs, Map<String, String> foundSpecs) {
    // If no specs were extracted from mention, allow match (backward compatibility)
    if (mentionSpecs.isEmpty) {
      return true;
    }

    // Check all specs extracted from mention
    for (final entry in mentionSpecs.entries) {
      final key = entry.key;
      final mentionValue = entry.value;
      final foundValue = foundSpecs[key];

      // If the found product doesn't have this spec, it's not a match
      if (foundValue == null) {
        return false;
      }

      // Normalize and compare (handle variations like "16gb" vs "16 GB")
      final normalizedMention = mentionValue.toLowerCase().replaceAll(' ', '');
      final normalizedFound = foundValue.toLowerCase().replaceAll(' ', '');

      if (normalizedMention != normalizedFound) {
        return false;
      }
    }

    return true; // All specs match
  }

  /// Check if query is not about products (voucher, account, general questions)
  bool _isNonProductQuery(String message) {
    final lowerMessage = message.toLowerCase();

    // Voucher-related keywords
    final voucherKeywords = [
      'voucher',
      'mã giảm giá',
      'khuyến mãi của tôi',
      'ưu đãi của tôi',
      'coupon',
      'discount code',
    ];

    // Account/Personal info keywords
    final accountKeywords = [
      'tài khoản',
      'thông tin cá nhân',
      'account',
      'profile',
      'my info',
      'my account',
    ];

    // General/Help keywords (not product-specific)
    final generalKeywords = [
      'hướng dẫn',
      'cách',
      'làm sao',
      'help',
      'how to',
      'guide',
      'tutorial',
    ];

    // Check if message matches any non-product patterns
    for (final keyword in [
      ...voucherKeywords,
      ...accountKeywords,
      ...generalKeywords
    ]) {
      if (lowerMessage.contains(keyword)) {
        return true;
      }
    }

    return false;
  }
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

class _ProductCardSelection {
  final List<QueryDocumentSnapshot> docs;
  final List<Map<String, dynamic>> cards;

  const _ProductCardSelection({required this.docs, required this.cards});
}

enum _ProductSortType {
  none,
  priceLowest,
  priceHighest,
  salesHighest,
}

_ProductCardSelection _prepareProductCardSelection(
  List<QueryDocumentSnapshot> originalDocs, {
  required bool isVietnamese,
  int limit = 3,
  List<String>? keywordFilters,
  bool disableFallbackOnEmptyMatch = false,
  _ProductSortType sortType = _ProductSortType.none,
}) {
  if (originalDocs.isEmpty) {
    return const _ProductCardSelection(docs: [], cards: []);
  }

  final normalizedFilters = (keywordFilters ?? [])
      .map((token) => token.trim().toLowerCase())
      .where((token) => token.isNotEmpty)
      .toList();

  List<QueryDocumentSnapshot> docs =
      List<QueryDocumentSnapshot>.from(originalDocs);

  if (normalizedFilters.isNotEmpty) {
    final filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final manufacturer = _extractManufacturerName(data).toLowerCase();
      final tags = (data['tags']?.toString() ?? '').toLowerCase();
      final searchText = '$name $manufacturer $tags';
      return normalizedFilters.every((token) => searchText.contains(token));
    }).toList();

    if (filteredDocs.isNotEmpty) {
      docs = filteredDocs;
    } else if (disableFallbackOnEmptyMatch) {
      docs = <QueryDocumentSnapshot>[];
    }
  }

  // Sort products based on sortType
  if (sortType != _ProductSortType.none) {
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      switch (sortType) {
        case _ProductSortType.priceLowest:
          final priceA = (dataA['discountedPrice'] as num?)?.toDouble() ??
              ((dataA['sellingPrice'] as num?)?.toDouble() ?? 0) *
                  (1 - ((dataA['discount'] as num?)?.toDouble() ?? 0) / 100);
          final priceB = (dataB['discountedPrice'] as num?)?.toDouble() ??
              ((dataB['sellingPrice'] as num?)?.toDouble() ?? 0) *
                  (1 - ((dataB['discount'] as num?)?.toDouble() ?? 0) / 100);
          return priceA.compareTo(priceB);
        case _ProductSortType.priceHighest:
          final priceA = (dataA['discountedPrice'] as num?)?.toDouble() ??
              ((dataA['sellingPrice'] as num?)?.toDouble() ?? 0) *
                  (1 - ((dataA['discount'] as num?)?.toDouble() ?? 0) / 100);
          final priceB = (dataB['discountedPrice'] as num?)?.toDouble() ??
              ((dataB['sellingPrice'] as num?)?.toDouble() ?? 0) *
                  (1 - ((dataB['discount'] as num?)?.toDouble() ?? 0) / 100);
          return priceB.compareTo(priceA);
        case _ProductSortType.salesHighest:
          final salesA = (dataA['sales'] as num?)?.toInt() ?? 0;
          final salesB = (dataB['sales'] as num?)?.toInt() ?? 0;
          return salesB.compareTo(salesA);
        case _ProductSortType.none:
          return 0;
      }
    });
  }

  final limitedDocs = docs.take(limit).toList();

  final cards = limitedDocs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final sellingPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
    final discount = (data['discount'] as num?)?.toDouble() ?? 0;
    final discountedPrice = (data['discountedPrice'] as num?)?.toDouble() ??
        sellingPrice * (1 - discount / 100);
    final category = data['category']?.toString() ?? '';

    return {
      'id': doc.id,
      'name': data['productName'] ?? '',
      'price': discountedPrice,
      'originalPrice': sellingPrice,
      'discount': discount,
      'stock': data['stock'] ?? 0,
      'imageUrl': data['imageUrl'],
      'category': category,
    };
  }).toList();

  return _ProductCardSelection(docs: limitedDocs, cards: cards);
}

String _formatProductSuggestionResponse(
    String aiResponse, List<Map<String, dynamic>> cards, bool isVietnamese) {
  final trimmed = aiResponse.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  return isVietnamese
      ? 'Mình đã tìm được một vài sản phẩm phù hợp. Nếu bạn cần thêm thông tin chi tiết, cứ nói mình nhé!'
      : 'I found a few matching products. Let me know if you want more details!';
}

_ProductSortType _detectSortType(String message, bool isVietnamese) {
  final lowerMessage = message.toLowerCase();

  // Price sorting keywords
  final priceLowestKeywords = isVietnamese
      ? [
          'giá thấp',
          'giá rẻ',
          'rẻ nhất',
          'thấp nhất',
          'giá thấp nhất',
          'rẻ',
          'giá thấp nhất'
        ]
      : [
          'lowest price',
          'cheapest',
          'lowest',
          'cheap',
          'low price',
          'affordable'
        ];

  final priceHighestKeywords = isVietnamese
      ? [
          'giá cao',
          'giá cao nhất',
          'đắt nhất',
          'cao nhất',
          'giá đắt nhất',
          'đắt'
        ]
      : [
          'highest price',
          'most expensive',
          'highest',
          'expensive',
          'high price',
          'premium'
        ];

  // Sales sorting keywords
  final salesHighestKeywords = isVietnamese
      ? ['bán chạy', 'bán chạy nhất', 'phổ biến', 'nổi tiếng', 'được mua nhiều']
      : [
          'best selling',
          'popular',
          'best seller',
          'top selling',
          'most popular',
          'trending'
        ];

  // Check for price lowest
  if (priceLowestKeywords.any((keyword) => lowerMessage.contains(keyword))) {
    return _ProductSortType.priceLowest;
  }

  // Check for price highest
  if (priceHighestKeywords.any((keyword) => lowerMessage.contains(keyword))) {
    return _ProductSortType.priceHighest;
  }

  // Check for sales highest
  if (salesHighestKeywords.any((keyword) => lowerMessage.contains(keyword))) {
    return _ProductSortType.salesHighest;
  }

  return _ProductSortType.none;
}

/// Extract brand name from product data
String _extractBrandFromProduct(Map<String, dynamic> data) {
  // Try manufacturerID first
  final manufacturerId = data['manufacturerID']?.toString() ?? '';
  if (manufacturerId.isNotEmpty) {
    return manufacturerId;
  }

  // Try extracting from product name
  final productName = data['productName']?.toString() ?? '';
  return _extractBrandFromProductName(productName);
}

/// Extract brand name from product name string
String _extractBrandFromProductName(String productName) {
  final brandPattern = RegExp(
      r'\b(Intel|AMD|NVIDIA|Samsung|Kingston|Corsair|ASUS|MSI|Gigabyte)\b',
      caseSensitive: false);
  final match = brandPattern.firstMatch(productName);
  return match?.group(1) ?? '';
}

String _extractManufacturerName(Map<String, dynamic> data) {
  final manufacturer = data['manufacturer'];
  if (manufacturer is Map<String, dynamic>) {
    return manufacturer['name']?.toString() ?? '';
  }
  return manufacturer?.toString() ?? '';
}
