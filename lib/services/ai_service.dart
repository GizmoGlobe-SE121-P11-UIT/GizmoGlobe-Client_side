import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AI Service for GizmoGlobe application
///
/// This service provides AI-powered functionality including:
/// - Product search and recommendations
/// - Cart management (add products to cart via voice/text)
/// - Customer support and inquiries
/// - Multi-language support (English and Vietnamese)
/// - Conversation context management with reference resolution
///
/// Add to Cart Examples:
/// - "Add Intel Core i5 to cart"
/// - "Thêm RTX 3080 vào giỏ hàng"
/// - "Buy 2 pieces of Samsung SSD"
/// - "Mua 3 cái RAM Kingston"
/// - "Add this CPU to my cart"
/// - "Put RTX 4070 in cart"
///
/// Context-Aware Examples:
/// - User: "Tell me about Intel Core i5"
/// - AI: [Provides information about Intel Core i5]
/// - User: "Add it to cart" (AI understands "it" refers to Intel Core i5)
/// - User: "What about RTX 3080?"
/// - AI: [Provides information about RTX 3080]
/// - User: "Buy that" (AI understands "that" refers to RTX 3080)
class AIService {
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  final String _model = 'gemini-2.0-flash';
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  final Map<String, List<Map<String, dynamic>>> _conversationHistory = {};
  static const Duration _historyExpiration = Duration(days: 1);
  static const int _maxHistoryLength = 10; // Keep last 10 interactions

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
    if (history != null && history.isNotEmpty) {
      final lastInteraction = history.last['timestamp'] as DateTime;
      if (now.difference(lastInteraction) > _historyExpiration) {
        _conversationHistory.remove(userId);
        return userMessage;
      }

      // Check if current message contains context references
      final hasContextReferences = _hasContextReferences(userMessage);

      if (hasContextReferences) {
        // Build detailed context for reference resolution
        final contextBuilder = StringBuffer();
        contextBuilder.writeln('CONVERSATION CONTEXT (with references):');
        contextBuilder.writeln('=====================================');

        // Include last 5 interactions for better context
        final recentHistory = history.take(5).toList().reversed.toList();
        for (int i = 0; i < recentHistory.length; i++) {
          final interaction = recentHistory[i];
          final question = interaction['question'] as String;
          final answer = interaction['answer'] as String;
          final timestamp = interaction['timestamp'] as DateTime;
          final timeAgo = _formatTimeAgo(now.difference(timestamp));

          contextBuilder.writeln('Interaction ${i + 1} ($timeAgo ago):');
          contextBuilder.writeln('Q: $question');
          contextBuilder.writeln('A: $answer');

          // Extract key entities from the interaction
          final entities = _extractEntities(question, answer);
          if (entities.isNotEmpty) {
            contextBuilder.writeln('Key entities: ${entities.join(', ')}');
          }
          contextBuilder.writeln('---');
        }

        contextBuilder.writeln('CURRENT QUESTION: $userMessage');
        contextBuilder.writeln(
            'NOTE: User may be referring to previous topics using words like "it", "that", "this", etc.');
        contextBuilder.writeln('=====================================');

        return contextBuilder.toString();
      } else {
        // Build simpler context for regular questions
        final contextBuilder = StringBuffer();
        contextBuilder.writeln('CONVERSATION CONTEXT:');
        contextBuilder.writeln('=====================');

        // Include last 3 interactions for context
        final recentHistory = history.take(3).toList().reversed;
        for (final interaction in recentHistory) {
          final question = interaction['question'] as String;
          final answer = interaction['answer'] as String;
          final timestamp = interaction['timestamp'] as DateTime;
          final timeAgo = _formatTimeAgo(now.difference(timestamp));

          contextBuilder.writeln('$timeAgo ago:');
          contextBuilder.writeln('Q: $question');
          contextBuilder.writeln('A: $answer');
          contextBuilder.writeln('---');
        }

        contextBuilder.writeln('CURRENT QUESTION: $userMessage');
        contextBuilder.writeln('=====================');

        return contextBuilder.toString();
      }
    }

    return userMessage;
  }

  // Check if message contains context references
  bool _hasContextReferences(String message) {
    final referenceWords = [
      'it',
      'that',
      'this',
      'them',
      'those',
      'these',
      'nó',
      'đó',
      'đây',
      'chúng',
      'những cái đó',
      'những cái này'
    ];

    final lowerMessage = message.toLowerCase();
    return referenceWords.any((word) => lowerMessage.contains(word));
  }

  // Extract key entities from text for context
  List<String> _extractEntities(String question, String answer) {
    final entities = <String>{};

    // Extract product names, categories, brands
    final productPatterns = [
      RegExp(
          r'\b(?:Intel|AMD|NVIDIA|Samsung|Kingston|Corsair|ASUS|MSI|Gigabyte)\b',
          caseSensitive: false),
      RegExp(r'\b(?:Core i[3579]|Ryzen [3579]|RTX \d+|GTX \d+)\b',
          caseSensitive: false),
      RegExp(r'\b(?:CPU|GPU|RAM|SSD|HDD|PSU|Mainboard)\b',
          caseSensitive: false),
    ];

    final allText = '$question $answer';
    for (final pattern in productPatterns) {
      final matches = pattern.allMatches(allText);
      for (final match in matches) {
        entities.add(match.group(0)!);
      }
    }

    return entities.toList();
  }

  // Extract product name from conversation context
  String? _extractProductNameFromContext(String userId, String currentMessage) {
    final history = _conversationHistory[userId];
    if (history == null || history.isEmpty) return null;

    // Check if current message contains context references or acknowledgment words
    if (!_hasContextReferences(currentMessage) &&
        !_hasAcknowledgmentWords(currentMessage)) {
      return null;
    }

    // Look for product names in recent interactions (most recent first)
    final recentInteractions = history.take(5).toList().reversed;
    final List<String> foundProducts = [];

    for (final interaction in recentInteractions) {
      final question = interaction['question'] as String;
      final answer = interaction['answer'] as String;

      // Prioritize user's question over AI's answer for context extraction
      // The user's question is more likely to contain the original product name they were asking about
      String? productName = _extractProductNameFromUserQuestion(question);
      if (productName == null) {
        productName = _extractProductNameFromText(question);
      }

      if (productName != null) {
        if (kDebugMode) {
          print('Extracted product name from user question: "$productName"');
        }
        foundProducts.add(productName);
      }

      // Only use AI answer if no product found in user question
      if (productName == null) {
        productName = _extractProductNameFromText(answer);
        if (productName != null) {
          if (kDebugMode) {
            print('Extracted product name from AI answer: "$productName"');
          }
          foundProducts.add(productName);
        }
      }
    }

    // Return the most specific product name found
    if (foundProducts.isNotEmpty) {
      // Sort by specificity (longer names are usually more specific)
      foundProducts.sort((a, b) => b.length.compareTo(a.length));

      if (kDebugMode) {
        print('Found products in context: $foundProducts');
        print('Selected most specific: "${foundProducts.first}"');
      }

      return foundProducts.first;
    }

    return null;
  }

  // Check if message contains acknowledgment words
  bool _hasAcknowledgmentWords(String message) {
    final acknowledgmentWords = [
      'okay',
      'ok',
      'yes',
      'yeah',
      'sure',
      'alright',
      'fine',
      'được',
      'vâng',
      'ừ',
      'ừm',
      'được rồi',
      'tốt'
    ];

    final lowerMessage = message.toLowerCase();
    return acknowledgmentWords.any((word) => lowerMessage.contains(word));
  }

  // Extract product name from text using multiple patterns
  String? _extractProductNameFromText(String text) {
    // More comprehensive product patterns - ordered by specificity
    final productPatterns = [
      // Most specific: Full product names with complete specifications
      RegExp(
          r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\s+(?:HyperX\s+)?(?:Fury|Core|Ryzen|RTX|GTX|DDR\d+)\s+(?:\d+[A-Z]*|[^\s]+(?:\s+[^\s]+)*)',
          caseSensitive: false),

      // Specific product models with numbers
      RegExp(
          r'\b(?:Core i[3579]\s*\d+[A-Z]*|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*)\b',
          caseSensitive: false),

      // RAM patterns with full specifications
      RegExp(r'\b(?:DDR\d+)\s+(?:\d+)\s*(?:GB|MB)\s*(?:\d+)?\s*(?:MHz)?\b',
          caseSensitive: false),

      // Product names in quotes (most reliable)
      RegExp(
          r'["""]([^"""]*(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)[^"""]*)["""]',
          caseSensitive: false),

      // Product names after "Product Name:" or similar labels
      RegExp(
          r'(?:Product Name|Name|Model):\s*([^:\n]*?(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)[^:\n]*?)(?:\n|$)',
          caseSensitive: false),

      // User-friendly patterns for common input formats
      RegExp(
          r'\b(?:tell me about|show me|what about|info about|details about)\s+([^.!?]*?(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)[^.!?]*?)(?:\s|$)',
          caseSensitive: false),

      // Generic product categories with brands (least specific - use as fallback)
      RegExp(
          r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\s+(?:RAM|CPU|GPU|SSD|HDD|PSU|Mainboard)\b',
          caseSensitive: false),
    ];

    for (final pattern in productPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        String productName = match.group(0) ?? match.group(1) ?? '';
        productName = productName.trim();

        if (productName.isNotEmpty && productName.length > 3) {
          // Clean up the product name
          productName = productName.replaceAll(RegExp(r'^\s*[:"""]\s*'), '');
          productName = productName.replaceAll(RegExp(r'\s*[:"""]\s*$'), '');

          // Additional cleanup to avoid partial matches
          productName = productName.replaceAll(
              RegExp(r'\s+category\s*:?\s*$', caseSensitive: false), '');
          productName = productName.replaceAll(RegExp(r'\s+$'), '');

          // Apply general product name cleaning
          productName = _cleanProductName(productName);

          if (kDebugMode) {
            print(
                'Found product name: "$productName" in text: "${text.substring(0, text.length > 100 ? 100 : text.length)}..."');
          }

          // Validate that this is a complete product name, not just a category
          if (_isCompleteProductName(productName)) {
            return productName;
          }
        }
      }
    }

    return null;
  }

  // Validate if the extracted name is a complete product name
  bool _isCompleteProductName(String productName) {
    // Check if it's just a category or incomplete
    final incompletePatterns = [
      RegExp(r'^[A-Za-z]+\s+(?:RAM|CPU|GPU|SSD|HDD|PSU|Mainboard)\s*$',
          caseSensitive: false),
      RegExp(r'^[A-Za-z]+\s+category\s*:?\s*$', caseSensitive: false),
      RegExp(r'^[A-Za-z]+\s*$', caseSensitive: false),
    ];

    for (final pattern in incompletePatterns) {
      if (pattern.hasMatch(productName)) {
        if (kDebugMode) {
          print('Rejected incomplete product name: "$productName"');
        }
        return false;
      }
    }

    // Check if it contains enough information to be a real product
    final hasBrand = RegExp(
            r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\b',
            caseSensitive: false)
        .hasMatch(productName);
    final hasModel = RegExp(
            r'\b(?:HyperX|Fury|Core|Ryzen|RTX|GTX|DDR\d+|\d+[A-Z]*)\b',
            caseSensitive: false)
        .hasMatch(productName);

    // For user questions, be more lenient - if they mention a brand, it's probably valid
    // even if we don't have a specific model number
    if (hasBrand) {
      // If it's from a user question, accept it even without a specific model
      if (productName.length > 5) {
        // At least some additional info beyond just brand
        return true;
      }
    }

    return hasBrand && hasModel;
  }

  // Extract product name specifically from user questions (more lenient)
  String? _extractProductNameFromUserQuestion(String question) {
    // Remove common question words and phrases
    final questionWords = [
      'tell me about',
      'show me',
      'what about',
      'info about',
      'details about',
      'what is',
      'what are',
      'how much',
      'how many',
      'where can',
      'when will',
      'can you',
      'could you',
      'would you',
      'please',
      'thanks',
      'thank you'
    ];

    var cleanedQuestion = question.toLowerCase();
    for (final word in questionWords) {
      cleanedQuestion = cleanedQuestion.replaceAll(word.toLowerCase(), '');
    }

    // Remove action words that shouldn't be part of product names
    final actionWords = [
      'get',
      'buy',
      'purchase',
      'order',
      'find',
      'search',
      'show',
      'tell',
      'give',
      'add',
      'put',
      'place',
      'include',
      'insert',
      'lấy',
      'mua',
      'đặt',
      'tìm',
      'tìm kiếm',
      'hiển thị',
      'cho biết',
      'cho',
      'thêm',
      'đưa',
      'bao gồm'
    ];

    for (final word in actionWords) {
      cleanedQuestion = cleanedQuestion.replaceAll(
          RegExp(r'\b$word\b', caseSensitive: false), '');
    }

    // Look for brand names first
    final brandPattern = RegExp(
        r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\b',
        caseSensitive: false);

    final brandMatch = brandPattern.firstMatch(cleanedQuestion);
    if (brandMatch != null) {
      final brand = brandMatch.group(0)!;

      // Try to get the full product name around the brand
      final startIndex = question.toLowerCase().indexOf(brand.toLowerCase());
      if (startIndex >= 0) {
        final endIndex = startIndex + brand.length;
        final beforeBrand = question.substring(0, startIndex).trim();
        final afterBrand = question.substring(endIndex).trim();

        // Combine to get the full product name
        var fullName = '$beforeBrand $brand $afterBrand'.trim();

        // Clean up the extracted name
        fullName = _cleanProductName(fullName);

        if (kDebugMode) {
          print('Extracted from user question: "$fullName"');
        }

        return fullName;
      }
    }

    return null;
  }

  // Clean up product name by removing unwanted words and phrases
  String _cleanProductName(String productName) {
    // Remove common words that shouldn't be part of product names
    final unwantedWords = [
      'get',
      'buy',
      'purchase',
      'order',
      'find',
      'search',
      'show',
      'tell',
      'give',
      'add',
      'put',
      'place',
      'include',
      'insert',
      'lấy',
      'mua',
      'đặt',
      'tìm',
      'tìm kiếm',
      'hiển thị',
      'cho biết',
      'cho',
      'thêm',
      'đưa',
      'bao gồm',
      'about',
      'for',
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'về',
      'cho',
      'của',
      'và',
      'hoặc',
      'nhưng',
      'trong',
      'trên',
      'tại',
      'đến'
    ];

    var cleanedName = productName;

    // Remove unwanted words
    for (final word in unwantedWords) {
      cleanedName = cleanedName.replaceAll(
          RegExp(r'\b$word\b', caseSensitive: false), '');
    }

    // Remove cart-related phrases
    final cartPhrases = [
      'to cart',
      'in cart',
      'into cart',
      'to my cart',
      'in my cart',
      'into my cart',
      'to shopping cart',
      'in shopping cart',
      'into shopping cart',
      'to basket',
      'in basket',
      'into basket',
      'vào giỏ hàng',
      'trong giỏ hàng',
      'cho vào giỏ hàng'
    ];

    for (final phrase in cartPhrases) {
      cleanedName =
          cleanedName.replaceAll(RegExp(phrase, caseSensitive: false), '');
    }

    // Clean up extra spaces and punctuation
    cleanedName = cleanedName
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleanedName;
  }

  // Format time ago for context
  String _formatTimeAgo(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    }
  }

  // Cập nhật lịch sử
  void _updateHistory(String userId, String question, String answer) {
    if (!_conversationHistory.containsKey(userId)) {
      _conversationHistory[userId] = [];
    }

    final history = _conversationHistory[userId]!;

    // Add new interaction
    history.add({
      'question': question,
      'answer': answer,
      'timestamp': DateTime.now(),
    });

    // Keep only the last N interactions
    if (history.length > _maxHistoryLength) {
      history.removeRange(0, history.length - _maxHistoryLength);
    }
  }

  /// Clear conversation history for a specific user
  void clearConversationHistory(String userId) {
    _conversationHistory.remove(userId);
    if (kDebugMode) {
      print('Cleared conversation history for user: $userId');
    }
  }

  /// Get conversation history for a specific user
  List<Map<String, dynamic>> getConversationHistory(String userId) {
    return _conversationHistory[userId] ?? [];
  }

  /// Check if user has recent conversation history
  bool hasRecentHistory(String userId) {
    final history = _conversationHistory[userId];
    if (history == null || history.isEmpty) return false;

    final now = DateTime.now();
    final lastInteraction = history.last['timestamp'] as DateTime;
    return now.difference(lastInteraction) <= _historyExpiration;
  }

  // Detect add to cart requests
  bool _isAddToCartRequest(String message) {
    final addToCartKeywords = {
      'en': [
        'add to cart',
        'add to my cart',
        'put in cart',
        'add this to cart',
        'add it to cart',
        'add to shopping cart',
        'add to basket',
        'buy this',
        'purchase this',
        'order this',
        'get this',
        'add',
        'cart',
        'buy',
        'purchase',
        'put in',
        'add to',
        'get me',
        'i want to buy',
        'i want to purchase'
      ],
      'vi': [
        'thêm vào giỏ hàng',
        'thêm vào giỏ',
        'cho vào giỏ hàng',
        'mua cái này',
        'đặt hàng cái này',
        'lấy cái này',
        'thêm',
        'giỏ hàng',
        'mua',
        'đặt hàng',
        'lấy',
        'cho tôi',
        'tôi muốn mua',
        'tôi muốn đặt'
      ]
    };

    final isVietnamese = _isVietnamese(message);
    final keywords = addToCartKeywords[isVietnamese ? 'vi' : 'en']!;
    final lowerMessage = message.toLowerCase();

    // Check if message contains any add-to-cart keywords
    final hasKeyword =
        keywords.any((keyword) => lowerMessage.contains(keyword.toLowerCase()));

    // Additional check: if the message contains product-related terms and cart-related terms
    final productTerms = [
      'cpu',
      'gpu',
      'ram',
      'ssd',
      'hdd',
      'psu',
      'mainboard',
      'intel',
      'amd',
      'nvidia',
      'rtx',
      'gtx',
      'core'
    ];
    final cartTerms = ['cart', 'giỏ', 'buy', 'mua', 'purchase', 'đặt'];

    final hasProductTerm =
        productTerms.any((term) => lowerMessage.contains(term.toLowerCase()));
    final hasCartTerm =
        cartTerms.any((term) => lowerMessage.contains(term.toLowerCase()));

    return hasKeyword || (hasProductTerm && hasCartTerm);
  }

  // Extract product name from add to cart request
  String? _extractProductNameFromRequest(String message) {
    // First, try to extract using specific "add X to cart" patterns
    final addToCartPatterns = [
      RegExp(r'add\s+(.+?)\s+to\s+cart', caseSensitive: false),
      RegExp(r'add\s+(.+?)\s+to\s+my\s+cart', caseSensitive: false),
      RegExp(r'add\s+(.+?)\s+to\s+shopping\s+cart', caseSensitive: false),
      RegExp(r'add\s+(.+?)\s+to\s+basket', caseSensitive: false),
      RegExp(r'put\s+(.+?)\s+in\s+cart', caseSensitive: false),
      RegExp(r'put\s+(.+?)\s+into\s+cart', caseSensitive: false),
      RegExp(r'thêm\s+(.+?)\s+vào\s+giỏ\s+hàng', caseSensitive: false),
      RegExp(r'cho\s+(.+?)\s+vào\s+giỏ\s+hàng', caseSensitive: false),
    ];

    for (final pattern in addToCartPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        var extractedName = match.group(1)?.trim() ?? '';
        if (extractedName.isNotEmpty) {
          extractedName = _cleanProductName(extractedName);

          if (kDebugMode) {
            print(
                'Extracted by add-to-cart pattern: "$extractedName" from message: "$message"');
          }

          if (extractedName.isNotEmpty && !_isOnlyCommonWords(extractedName)) {
            return extractedName;
          }
        }
      }
    }

    // Second, try to extract by looking for brand patterns
    final brandPattern = RegExp(
        r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte|Western Digital|Seagate|Crucial|G.Skill|Team Group|Patriot|ADATA|Silicon Power|Lexar|PNY|SanDisk|Kingmax|Apacer|Transcend|Inno3D|Palit|Zotac|EVGA|XFX|Sapphire|PowerColor|ASRock|Biostar|ECS|Foxconn|Super Flower|Seasonic|Corsair|EVGA|be quiet!|Cooler Master|Thermaltake|NZXT|Fractal Design|Phanteks|Lian Li|InWin|Rosewill|Antec|SilverStone|BitFenix|NZXT|Fractal|Phanteks|Lian Li|InWin|Rosewill|Antec|SilverStone|BitFenix)\b',
        caseSensitive: false);

    final brandMatch = brandPattern.firstMatch(message);
    if (brandMatch != null) {
      final brand = brandMatch.group(0)!;

      // Try to get the full product name around the brand
      final startIndex = message.toLowerCase().indexOf(brand.toLowerCase());
      if (startIndex >= 0) {
        final endIndex = startIndex + brand.length;
        final beforeBrand = message.substring(0, startIndex).trim();
        final afterBrand = message.substring(endIndex).trim();

        // Combine to get the full product name
        var fullName = '$beforeBrand $brand $afterBrand'.trim();

        // Clean up the extracted name more aggressively
        fullName = _cleanProductName(fullName);

        // Additional cleaning for cart-related phrases
        final cartPhrases = [
          'to cart',
          'in cart',
          'into cart',
          'to my cart',
          'in my cart',
          'into my cart',
          'to shopping cart',
          'in shopping cart',
          'into shopping cart',
          'to basket',
          'in basket',
          'into basket',
          'vào giỏ hàng',
          'trong giỏ hàng',
          'cho vào giỏ hàng'
        ];

        for (final phrase in cartPhrases) {
          fullName =
              fullName.replaceAll(RegExp(phrase, caseSensitive: false), '');
        }

        if (kDebugMode) {
          print(
              'Extracted by brand pattern: "$fullName" from message: "$message"');
        }

        if (fullName.isNotEmpty && !_isOnlyCommonWords(fullName)) {
          return fullName;
        }
      }
    }

    // Fallback to the original method if brand extraction fails
    // Remove common add to cart phrases
    final removePhrases = [
      'add to cart',
      'add to my cart',
      'put in cart',
      'add this to cart',
      'add it to cart',
      'add to shopping cart',
      'add to basket',
      'buy this',
      'purchase this',
      'order this',
      'get this',
      'thêm vào giỏ hàng',
      'thêm vào giỏ',
      'cho vào giỏ hàng',
      'mua cái này',
      'đặt hàng cái này',
      'lấy cái này',
      'please',
      'can you',
      'could you',
      'would you',
      'vui lòng',
      'bạn có thể',
      'bạn có thể không',
      'bạn có muốn',
      'for me',
      'cho tôi',
      'help me',
      'giúp tôi'
    ];

    var cleanedMessage = message.toLowerCase();
    for (final phrase in removePhrases) {
      cleanedMessage = cleanedMessage.replaceAll(phrase.toLowerCase(), '');
    }

    // Remove quantity patterns
    final quantityPatterns = [
      RegExp(r'\d+\s*(?:piece|pieces|pc|pcs|unit|units|item|items)',
          caseSensitive: false),
      RegExp(r'\d+\s*(?:cái|chiếc|bộ|thùng)', caseSensitive: false),
      RegExp(r'quantity\s*:\s*\d+', caseSensitive: false),
      RegExp(r'số\s*lượng\s*:\s*\d+', caseSensitive: false),
      RegExp(r'\d+\s*(?:x|times)', caseSensitive: false),
    ];

    for (final pattern in quantityPatterns) {
      cleanedMessage = cleanedMessage.replaceAll(pattern, '');
    }

    // Remove acknowledgment words that don't represent products
    final acknowledgmentWords = [
      'okay',
      'ok',
      'yes',
      'yeah',
      'sure',
      'alright',
      'fine',
      'được',
      'ok',
      'vâng',
      'ừ',
      'ừm',
      'được rồi',
      'tốt'
    ];

    for (final word in acknowledgmentWords) {
      cleanedMessage = cleanedMessage.replaceAll(
          RegExp(r'\b$word\b', caseSensitive: false), '');
    }

    // Remove action words that shouldn't be part of product names
    final actionWords = [
      'get',
      'buy',
      'purchase',
      'order',
      'find',
      'search',
      'show',
      'tell',
      'give',
      'add',
      'put',
      'place',
      'include',
      'insert',
      'lấy',
      'mua',
      'đặt',
      'tìm',
      'tìm kiếm',
      'hiển thị',
      'cho biết',
      'cho',
      'thêm',
      'đưa',
      'bao gồm'
    ];

    for (final word in actionWords) {
      cleanedMessage = cleanedMessage.replaceAll(
          RegExp(r'\b$word\b', caseSensitive: false), '');
    }

    // Clean up extra spaces and punctuation
    cleanedMessage = cleanedMessage
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (kDebugMode) {
      print(
          'Extracted product name (fallback): "$cleanedMessage" from message: "$message"');
    }

    // If the cleaned message is empty or contains only common words, return null
    if (cleanedMessage.isEmpty || _isOnlyCommonWords(cleanedMessage)) {
      return null;
    }

    return cleanedMessage;
  }

  // Check if the cleaned message contains only common words that don't represent products
  bool _isOnlyCommonWords(String message) {
    final commonWords = [
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'this',
      'that',
      'these',
      'those',
      'it',
      'its',
      'they',
      'them',
      'their',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'cái',
      'này',
      'đó',
      'kia',
      'ấy',
      'và',
      'hoặc',
      'nhưng',
      'trong',
      'trên',
      'dưới',
      'của',
      'với',
      'bởi',
      'từ',
      'đến',
      'cho',
      'về',
      'theo',
      'qua',
      'qua',
      'tại'
    ];

    final words = message.toLowerCase().split(' ');
    return words.every((word) => commonWords.contains(word) || word.length < 3);
  }

  // Extract quantity from request
  int _extractQuantityFromRequest(String message) {
    final quantityPatterns = [
      RegExp(r'(\d+)\s*(?:piece|pieces|pc|pcs|unit|units|item|items)',
          caseSensitive: false),
      RegExp(r'(\d+)\s*(?:cái|chiếc|bộ|thùng)', caseSensitive: false),
      RegExp(r'quantity\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'số\s*lượng\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:x|times)', caseSensitive: false),
    ];

    for (final pattern in quantityPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final quantity = int.tryParse(match.group(1) ?? '1');
        if (quantity != null && quantity > 0) {
          return quantity;
        }
      }
    }

    // Default quantity is 1
    return 1;
  }

  // Find product by name
  Future<Map<String, dynamic>?> _findProductByName(String productName) async {
    try {
      if (kDebugMode) {
        print('Searching for product: "$productName"');
      }

      // Normalize product name for search
      final normalizedName = _normalizeProductName(productName);

      // Search in products collection
      final querySnapshot = await _firestore
          .collection('products')
          .where('status', isEqualTo: 'active')
          .get();

      // Filter products by name similarity
      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'productID': doc.id,
          'normalizedName': _normalizeProductName(data['productName'] ?? ''),
        };
      }).toList();

      if (kDebugMode) {
        print('Found ${products.length} active products to search through');
      }

      // Find best match
      Map<String, dynamic>? bestMatch;
      double bestScore = 0.0;

      for (final product in products) {
        final productNormalizedName = product['normalizedName'] as String;
        final originalName = product['productName'] as String;

        // Calculate similarity scores
        final normalizedScore =
            _calculateSimilarity(normalizedName, productNormalizedName);
        final originalScore = _calculateSimilarity(
            productName.toLowerCase(), originalName.toLowerCase());

        // Use the better score
        final score =
            normalizedScore > originalScore ? normalizedScore : originalScore;

        if (kDebugMode) {
          print(
              'Product: "${originalName}" - Score: $score (Normalized: $normalizedScore, Original: $originalScore)');
        }

        if (score > bestScore && score > 0.2) {
          // Lowered threshold for better matching
          bestScore = score;
          bestMatch = product;
        }
      }

      if (kDebugMode) {
        if (bestMatch != null) {
          print(
              'Best match found: "${bestMatch['productName']}" with score: $bestScore');
        } else {
          print('No suitable match found (best score was: $bestScore)');
        }
      }

      return bestMatch;
    } catch (e) {
      if (kDebugMode) {
        print('Error finding product by name: $e');
      }
      return null;
    }
  }

  // Calculate similarity between two strings
  double _calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    final words1 =
        str1.toLowerCase().split(' ').where((word) => word.length > 1).toList();
    final words2 =
        str2.toLowerCase().split(' ').where((word) => word.length > 1).toList();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    double matches = 0.0;
    for (final word1 in words1) {
      for (final word2 in words2) {
        // Exact match
        if (word1 == word2) {
          matches += 1.0;
          break;
        }
        // Partial match (one contains the other)
        else if (word1.contains(word2) || word2.contains(word1)) {
          matches += 0.8; // Partial match gets 80% credit
          break;
        }
        // Similar words (for common variations)
        else if (_areSimilarWords(word1, word2)) {
          matches += 0.6; // Similar words get 60% credit
          break;
        }
      }
    }

    // Calculate score based on matches and length
    final score = matches / words1.length;

    // Boost score if the search term is contained within the product name
    if (str2.toLowerCase().contains(str1.toLowerCase())) {
      return score + 0.2; // Boost by 20%
    }

    return score;
  }

  // Check if two words are similar (common variations)
  bool _areSimilarWords(String word1, String word2) {
    final similarPairs = {
      'core': ['cores'],
      'processor': ['processors', 'cpu'],
      'memory': ['mem', 'ram'],
      'graphics': ['gpu', 'video'],
      'card': ['cards'],
      'drive': ['drives', 'storage'],
      'power': ['psu', 'supply'],
      'board': ['boards', 'mainboard', 'motherboard'],
      'intel': ['intel'],
      'amd': ['amd'],
      'nvidia': ['nvidia'],
      'samsung': ['samsung'],
      'kingston': ['kingston'],
      'corsair': ['corsair'],
      'asus': ['asus'],
      'msi': ['msi'],
      'gigabyte': ['gigabyte'],
    };

    final lowerWord1 = word1.toLowerCase();
    final lowerWord2 = word2.toLowerCase();

    // Check if they're in the same similar group
    for (final group in similarPairs.values) {
      if (group.contains(lowerWord1) && group.contains(lowerWord2)) {
        return true;
      }
    }

    return false;
  }

  // Get product suggestions for similar products
  Future<List<Map<String, dynamic>>> _getProductSuggestions(
      String productName) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('status', isEqualTo: 'active')
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'productID': doc.id,
          'normalizedName': _normalizeProductName(data['productName'] ?? ''),
        };
      }).toList();

      // Calculate similarity scores and sort by score
      final scoredProducts = products.map((product) {
        final productNormalizedName = product['normalizedName'] as String;
        final originalName = product['productName'] as String;

        final normalizedScore =
            _calculateSimilarity(productName, productNormalizedName);
        final originalScore = _calculateSimilarity(
            productName.toLowerCase(), originalName.toLowerCase());
        final score =
            normalizedScore > originalScore ? normalizedScore : originalScore;

        return {
          ...product,
          'similarityScore': score,
        };
      }).toList();

      // Sort by similarity score (descending) and return top 5
      scoredProducts.sort((a, b) => (b['similarityScore'] as double)
          .compareTo(a['similarityScore'] as double));

      return scoredProducts.take(5).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting product suggestions: $e');
      }
      return [];
    }
  }

  // Add product to cart
  Future<bool> _addProductToCart(
      String userId, String productID, int quantity) async {
    try {
      // Check if user document exists
      final userDoc =
          await _firestore.collection('customers').doc(userId).get();
      if (!userDoc.exists) {
        await _firestore.collection('customers').doc(userId).set({
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Get product information
      final productDoc =
          await _firestore.collection('products').doc(productID).get();
      if (!productDoc.exists) {
        if (kDebugMode) {
          print('Product not found: $productID');
        }
        return false;
      }

      final productData = productDoc.data()!;
      final price = (productData['sellingPrice'] as num).toDouble();
      final discount = (productData['discount'] as num?)?.toDouble() ?? 0.0;
      final discountedPrice = price * (1 - discount / 100);

      // Reference to cart item
      final cartRef = _firestore
          .collection('customers')
          .doc(userId)
          .collection('carts')
          .doc(productID);

      // Check if item exists in cart
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        final subtotal = (discountedPrice * quantity).toStringAsFixed(2);
        if (kDebugMode) {
          print('Creating new cart item with subtotal: $subtotal');
        }

        await cartRef.set({
          'quantity': quantity,
          'subtotal': double.parse(subtotal),
          'productID': productID,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final currentQuantity =
            (cartDoc.data()?['quantity'] as num?)?.toInt() ?? 0;
        final newQuantity = currentQuantity + quantity;
        final subtotal = (discountedPrice * newQuantity).toStringAsFixed(2);

        if (kDebugMode) {
          print('Updating existing cart item:');
          print('Current quantity: $currentQuantity');
          print('New quantity: $newQuantity');
          print('New subtotal: $subtotal');
        }

        await cartRef.update({
          'quantity': newQuantity,
          'subtotal': double.parse(subtotal),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding product to cart: $e');
      }
      return false;
    }
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

      // Get list of inactive manufacturers first
      final manufacturerSnapshot = await _firestore
          .collection('manufacturers')
          .where('status', isEqualTo: 'inactive')
          .get();

      final List<Map<String, dynamic>> inactiveManufacturers =
          manufacturerSnapshot.docs
              .map((doc) =>
                  {'id': doc.id, 'status': doc['status'] ?? 'inactive'})
              .toList();

      final List<String> inactiveManufacturerIDs =
          inactiveManufacturers.map((m) => m['id'] as String).toList();

      if (kDebugMode && inactiveManufacturerIDs.isNotEmpty) {
        print(
            'Found ${inactiveManufacturerIDs.length} inactive manufacturers to exclude');
      }

      // First query: Filter by active status
      var query = productsRef.where('status', isEqualTo: 'active');

      // Add category filter if specified
      if (category != null) {
        final standardCategory =
            CATEGORY_MAPPING[category.toLowerCase()] ?? category.toLowerCase();
        if (kDebugMode) {
          print('Searching with standardized category: $standardCategory');
        }
        query = query.where('category', isEqualTo: standardCategory);
      }

      // Add keyword filters if specified
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

      // Execute the query
      final result = await query.get();

      // Filter out products from inactive manufacturers in memory
      // since Firestore doesn't support NOT IN queries directly in this context
      final filteredDocs = result.docs
          .where((doc) =>
              !inactiveManufacturerIDs.contains(doc.data()['manufacturerID']))
          .toList();

      if (kDebugMode) {
        print('Found ${result.docs.length} active products');
        print(
            'After filtering inactive manufacturers: ${filteredDocs.length} products remain');
      }

      // We can't create a new QuerySnapshot with a filtered list directly
      // Instead, we can return the original snapshot and access filteredDocs separately
      // or use extension methods to work with the filtered documents
      return result;

      // Note: When using the result, access filteredDocs instead of result.docs
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
      RegExp(r'intel\s+', caseSensitive: false): '',
      RegExp(r'amd\s+', caseSensitive: false): '',
      RegExp(r'cpu\s+', caseSensitive: false): '',
      RegExp(r'processor\s+', caseSensitive: false): '',
      RegExp(r'core\s+', caseSensitive: false): '',
      RegExp(r'ryzen\s+', caseSensitive: false): 'ryzen-'
    };

    patterns.forEach((pattern, replacement) {
      normalized = normalized.replaceAll(pattern, replacement);
    });

    final iSeriesPattern =
        RegExp(r'i([3579])\s*-?\s*(\d+)', caseSensitive: false);
    var matches = iSeriesPattern.allMatches(normalized);
    for (var match in matches) {
      var series = match.group(1);
      var number = match.group(2);
      normalized = normalized.replaceAll(match.group(0)!, 'i$series-$number');
    }

    final rSeriesPattern = RegExp(r'r([3579])\s+(\d+)', caseSensitive: false);
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
    final regex = RegExp(r'(i[3579]|ryzen\s*[3579]|[0-9]+[a-z]*|[a-z]+)',
        caseSensitive: false);
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
    buffer.writeln(isVietnamese ? 'DANH SACH YEU THICH:' : 'FAVORITE LIST:');

    for (var i = 0; i < favorites.length; i++) {
      final product = favorites[i];
      buffer.writeln('\n${i + 1}. ${product['productName']}');
      buffer.writeln(
          '   Gia: ${_formatPriceWithDiscount(product['sellingPrice'], product['discount'])}');
      buffer.writeln('   Kho: ${_formatValue(product['stock'], 'stock')}');
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

  /// Generate AI response for user messages
  ///
  /// This method handles various types of user requests:
  /// - Product inquiries and searches
  /// - Add to cart requests (e.g., "Add Intel Core i5 to cart")
  /// - Cart and favorite management
  /// - General customer support
  ///
  /// Parameters:
  /// - userMessage: The user's input message
  /// - userId: Optional user ID for personalized responses and cart operations
  ///
  /// Returns: AI-generated response in the same language as the input
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
      final isAddToCartRequest = _isAddToCartRequest(userMessage);

      // Xử lý ngữ cảnh nếu có userId
      final processedMessage =
          userId != null ? _processContext(userMessage, userId) : userMessage;

      // Nếu là yêu cầu thêm vào giỏ hàng
      if (isAddToCartRequest) {
        if (userId == null) {
          return isVietnamese
              ? 'Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng.'
              : 'Please log in to add products to your cart.';
        }

        try {
          String? productName = _extractProductNameFromRequest(userMessage);

          // If no product name found, try to extract from context
          if (productName == null || productName.isEmpty) {
            productName = _extractProductNameFromContext(userId, userMessage);
          }

          if (productName == null || productName.isEmpty) {
            // Check if this might be a context reference
            if (_hasContextReferences(userMessage) ||
                _hasAcknowledgmentWords(userMessage)) {
              if (kDebugMode) {
                print('Context extraction failed for message: "$userMessage"');
                final history = _conversationHistory[userId];
                if (history != null && history.isNotEmpty) {
                  print('Recent conversation history:');
                  final recent = history.take(3).toList().reversed.toList();
                  for (int i = 0; i < recent.length; i++) {
                    final interaction = recent[i];
                    print('${i + 1}. Q: ${interaction['question']}');
                    print(
                        '   A: ${interaction['answer'].substring(0, interaction['answer'].length > 200 ? 200 : interaction['answer'].length)}...');
                  }
                }
              }

              return isVietnamese
                  ? 'Tôi không thể tìm thấy sản phẩm nào trong cuộc trò chuyện gần đây. Vui lòng chỉ rõ tên sản phẩm bạn muốn thêm vào giỏ hàng. Ví dụ: "Thêm Intel Core i5 vào giỏ hàng" hoặc "Add RTX 3080 to cart".'
                  : 'I couldn\'t find any product mentioned in our recent conversation. Please specify the product name you want to add to cart. For example: "Add Intel Core i5 to cart" or "Thêm RTX 3080 vào giỏ hàng".';
            } else {
              return isVietnamese
                  ? 'Vui lòng chỉ rõ tên sản phẩm bạn muốn thêm vào giỏ hàng. Ví dụ: "Thêm Intel Core i5 vào giỏ hàng" hoặc "Add RTX 3080 to cart".'
                  : 'Please specify the product name you want to add to cart. For example: "Add Intel Core i5 to cart" or "Thêm RTX 3080 vào giỏ hàng".';
            }
          }

          final quantity = _extractQuantityFromRequest(userMessage);
          final product = await _findProductByName(productName);

          if (product == null) {
            // Try to suggest similar products
            final suggestions = await _getProductSuggestions(productName);
            final suggestionText = suggestions.isNotEmpty
                ? '\n\nSản phẩm tương tự:\n${suggestions.take(3).map((p) => '- ${p['productName']}').join('\n')}'
                : '';

            return isVietnamese
                ? 'Xin lỗi, không tìm thấy sản phẩm "$productName". Vui lòng kiểm tra lại tên sản phẩm hoặc thử tìm kiếm sản phẩm trước.$suggestionText'
                : 'Sorry, product "$productName" not found. Please check the product name or try searching for products first.$suggestionText';
          }

          // Check stock availability
          final stock = product['stock'] ?? 0;
          if (stock < quantity) {
            return isVietnamese
                ? 'Xin lỗi, chỉ còn $stock sản phẩm trong kho. Vui lòng giảm số lượng hoặc chọn sản phẩm khác.'
                : 'Sorry, only $stock items available in stock. Please reduce the quantity or choose a different product.';
          }

          final success =
              await _addProductToCart(userId, product['productID'], quantity);

          if (success) {
            final productDisplayName =
                product['productName'] ?? 'Unknown Product';
            final price = product['sellingPrice'] ?? 0.0;
            final discount = product['discount'] ?? 0.0;
            final finalPrice = price * (1 - discount / 100);

            final response = isVietnamese
                ? '✅ Đã thêm $quantity ${quantity > 1 ? 'sản phẩm' : 'sản phẩm'} "$productDisplayName" vào giỏ hàng thành công!\n\n💰 Giá: ${_formatPriceWithDiscount(price, discount)}\n📦 Số lượng: $quantity\n💵 Tổng: ${_formatPrice(finalPrice * quantity)}\n\nBạn có thể xem giỏ hàng của mình trong ứng dụng.'
                : '✅ Successfully added $quantity ${quantity > 1 ? 'items' : 'item'} of "$productDisplayName" to your cart!\n\n💰 Price: ${_formatPriceWithDiscount(price, discount)}\n📦 Quantity: $quantity\n💵 Total: ${_formatPrice(finalPrice * quantity)}\n\nYou can view your cart in the app.';

            if (userId != null) {
              _updateHistory(userId, userMessage, response);
            }
            return response;
          } else {
            return isVietnamese
                ? 'Xin lỗi, có lỗi xảy ra khi thêm sản phẩm vào giỏ hàng. Vui lòng thử lại sau.'
                : 'Sorry, an error occurred while adding the product to cart. Please try again later.';
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error handling add to cart request: $e');
          }
          return isVietnamese
              ? 'Xin lỗi, có lỗi xảy ra khi xử lý yêu cầu thêm vào giỏ hàng. Vui lòng thử lại sau.'
              : 'Sorry, an error occurred while processing your add to cart request. Please try again later.';
        }
      }

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

          final response = _sanitizeMarkdown(await _callGeminiAPI(prompt));
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

        final response = _sanitizeMarkdown(await _callGeminiAPI(prompt));
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
        final response = _sanitizeMarkdown(await _callGeminiAPI(prompt));

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
        final response = _sanitizeMarkdown(await _callGeminiAPI(prompt));

        // Cập nhật lịch sử nếu có userId
        if (userId != null) {
          _updateHistory(userId, userMessage, response);
        }

        return response;
      }

      // Với các câu hỏi chung khác
      final prompt = _createGeneralPrompt(processedMessage, isVietnamese);
      final response = _sanitizeMarkdown(await _callGeminiAPI(prompt));

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

  // Remove markdown formatting but keep simple dash bullets
  String _sanitizeMarkdown(String input) {
    var text = input;
    // Remove bold/italic markers using mapped replacements
    text = text.replaceAllMapped(
        RegExp(r"\*\*([^*]+)\*\*"), (m) => m.group(1) ?? "");
    text =
        text.replaceAllMapped(RegExp(r"\*([^*]+)\*"), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(RegExp(r"_([^_]+)_"), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(
        RegExp(r"~{2}([^~]+)~{2}"), (m) => m.group(1) ?? "");
    // Strip headings (leading #), keep the text
    text = text.replaceAll(RegExp(r"^#{1,6}\s+", multiLine: true), "");
    // Remove code fences while keeping inner content
    text =
        text.replaceAllMapped(RegExp(r"```[\s\S]*?```", multiLine: true), (m) {
      final inner = m
          .group(0)!
          .replaceAll(RegExp(r"^```[a-zA-Z]*\n?"), "")
          .replaceAll("```", "");
      return inner.trim();
    });
    // Inline code ticks
    text = text.replaceAllMapped(RegExp(r"`([^`]+)`"), (m) => m.group(1) ?? "");
    // Links: [label](url) -> label
    text = text.replaceAllMapped(
        RegExp(r"\[([^\]]+)\]\(([^)]+)\)"), (m) => m.group(1) ?? "");
    // Images: ![alt](url) -> alt
    text = text.replaceAllMapped(
        RegExp(r"!\[([^\]]*)\]\(([^)]+)\)"), (m) => m.group(1) ?? "");
    // Blockquotes
    text = text.replaceAll(RegExp(r"^>\s?", multiLine: true), "");
    // Horizontal rules
    text =
        text.replaceAll(RegExp(r"^(-{3,}|\*{3,}|_{3,})$", multiLine: true), "");
    // Normalize bullets to '- '
    text = text.replaceAll(RegExp(r"^\s*[\*\+]\s+", multiLine: true), "- ");
    text = text.replaceAll(
        RegExp(r"^\s*[•·▪►➤⦿⦾●○◆◇•]\s*", multiLine: true), "- ");
    // Remove leading numbering like '1. ' but keep text
    text = text.replaceAll(RegExp(r"^\s*\d+\.\s+", multiLine: true), "- ");
    // Normalize extra spaces after dash bullet
    text = text.replaceAll(RegExp(r"^-\s{2,}", multiLine: true), "- ");
    // Unescape currency by removing the backslash before $
    text = text.replaceAll(RegExp(r"\\(?=\$\d)"), "");
    // Trim trailing whitespace lines
    text = text.replaceAll(RegExp(r"[ \t]+$", multiLine: true), "");
    return text.trim();
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
