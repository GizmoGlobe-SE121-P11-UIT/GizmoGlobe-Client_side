import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_utils.dart';

class AIConversationService {
  final FirebaseFirestore _firestore;
  final AIUtils _utils = AIUtils();

  // Store conversation history in memory for fast access
  final Map<String, List<Map<String, dynamic>>> _conversationHistory = {};
  static const Duration _historyExpiration = Duration(days: 1);
  static const int _maxHistoryLength = 10;

  // SharedPreferences keys
  static const String _prefKeyPrefix = 'conversation_history_';
  static const String _lastSyncKeyPrefix = 'last_sync_';

  AIConversationService(this._firestore);

  /// Initialize conversation history for a user
  Future<void> initializeUserHistory(String userId) async {
    if (_conversationHistory.containsKey(userId)) {
      return; // Already initialized
    }

    try {
      // First, try to load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_prefKeyPrefix$userId';

      final historyJson = prefs.getString(historyKey);

      if (historyJson != null) {
        final history = _parseHistoryFromJson(historyJson);
        if (history.isNotEmpty) {
          _conversationHistory[userId] = history;
          if (kDebugMode) {
            print(
                'Loaded ${history.length} conversations from SharedPreferences for user: $userId');
          }
          return;
        }
      }

      // If no local data or empty, sync from Firebase
      await _syncFromFirebase(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing user history: $e');
      }
      _conversationHistory[userId] = [];
    }
  }

  /// Sync conversation history from Firebase
  Future<void> _syncFromFirebase(String userId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(userId).get();

      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        final messages = <Map<String, dynamic>>[];

        // Convert Firebase document to conversation format
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final message = value;
            if (message['content'] != null && message['timestamp'] != null) {
              final newMessage = <String, dynamic>{
                'question': message['content'] as String,
                'answer': message['aiResponse'] ?? 'No response available',
                'timestamp': (message['timestamp'] as Timestamp).toDate(),
                'messageId': key,
              };
              messages.add(newMessage);
            }
          }
        });

        // Sort by timestamp
        messages.sort((a, b) =>
            (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

        // Keep only recent messages
        final recentMessages = messages.take(_maxHistoryLength).toList();

        _conversationHistory[userId] = recentMessages;

        // Save to SharedPreferences
        await _saveToSharedPreferences(userId);

        if (kDebugMode) {
          print(
              'Synced ${recentMessages.length} conversations from Firebase for user: $userId');
        }
      } else {
        _conversationHistory[userId] = [];
        await _saveToSharedPreferences(userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing from Firebase: $e');
      }
      _conversationHistory[userId] = [];
    }
  }

  /// Save conversation history to SharedPreferences
  Future<void> _saveToSharedPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_prefKeyPrefix$userId';
      final lastSyncKey = '$_lastSyncKeyPrefix$userId';

      final history = _conversationHistory[userId] ?? [];
      final historyJson = _convertHistoryToJson(history);

      await prefs.setString(historyKey, historyJson);
      await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        print(
            'Saved ${history.length} conversations to SharedPreferences for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving to SharedPreferences: $e');
      }
    }
  }

  /// Save message to Firebase
  Future<void> _saveToFirebase(
      String userId, String question, String answer) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = Timestamp.now();

      final messageData = {
        'content': question,
        'aiResponse': answer,
        'timestamp': timestamp,
        'userId': userId,
        'isAIMode': true,
        'messageId': messageId,
        'receiverId': 'ai',
        'senderId': userId,
      };

      await _firestore.collection('chats').doc(userId).update({
        messageId: messageData,
      });

      if (kDebugMode) {
        print(
            'Saved message to Firebase for user: $userId, messageId: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving to Firebase: $e');
      }
    }
  }

  /// Convert history to JSON string
  String _convertHistoryToJson(List<Map<String, dynamic>> history) {
    final serializableHistory = history
        .map((interaction) => {
              'question': interaction['question'],
              'answer': interaction['answer'],
              'timestamp':
                  (interaction['timestamp'] as DateTime).toIso8601String(),
              'messageId': interaction['messageId'],
            })
        .toList();

    return jsonEncode(serializableHistory);
  }

  /// Parse history from JSON string
  List<Map<String, dynamic>> _parseHistoryFromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => {
                'question': item['question'] as String,
                'answer': item['answer'] as String,
                'timestamp': DateTime.parse(item['timestamp'] as String),
                'messageId': item['messageId'] as String? ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing history from JSON: $e');
      }
      return [];
    }
  }

  /// Process context for user messages
  Future<String> processContext(String userMessage, String userId) async {
    // Ensure user history is initialized
    await initializeUserHistory(userId);

    final now = DateTime.now();
    final history = _conversationHistory[userId];

    // Clear old history if exists
    if (history != null && history.isNotEmpty) {
      final lastInteraction = history.last['timestamp'] as DateTime;
      if (now.difference(lastInteraction) > _historyExpiration) {
        _conversationHistory.remove(userId);
        await _saveToSharedPreferences(userId);
        return userMessage;
      }

      // Check if current message contains context references
      final hasContextReferences = _hasContextReferences(userMessage);
      final isAddToCartRequest = _utils.isAddToCartRequest(userMessage);

      if (hasContextReferences || isAddToCartRequest) {
        // Build detailed context for reference resolution and add-to-cart actions
        final contextBuilder = StringBuffer();
        contextBuilder
            .writeln('CONVERSATION CONTEXT (with product references):');
        contextBuilder
            .writeln('==============================================');

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

          // Extract product information if available
          final productInfo = _extractProductInfo(answer);
          if (productInfo.isNotEmpty) {
            contextBuilder.writeln('Product info: $productInfo');
          }
          contextBuilder.writeln('---');
        }

        contextBuilder.writeln('CURRENT QUESTION: $userMessage');
        if (isAddToCartRequest) {
          contextBuilder.writeln(
              'NOTE: This appears to be an add-to-cart request. Use context to identify the product.');
        } else {
          contextBuilder.writeln(
              'NOTE: User may be referring to previous topics using words like "it", "that", "this", etc.');
        }
        contextBuilder
            .writeln('==============================================');

        return contextBuilder.toString();
      }
    }

    return userMessage;
  }

  /// Extract product name from conversation context
  Future<String?> extractProductNameFromContext(
      String userId, String currentMessage) async {
    // Ensure user history is initialized
    await initializeUserHistory(userId);

    final history = _conversationHistory[userId];
    if (history == null || history.isEmpty) return null;

    // Check if current message contains context references, acknowledgment words, or is an add-to-cart request
    final hasContextRefs = _hasContextReferences(currentMessage);
    final hasAcknowledgment = _hasAcknowledgmentWords(currentMessage);
    final isAddToCart = _utils.isAddToCartRequest(currentMessage);

    if (!hasContextRefs && !hasAcknowledgment && !isAddToCart) {
      return null;
    }

    // Look for product names in recent interactions (most recent first)
    final recentInteractions = history.take(5).toList().reversed;
    final List<String> foundProducts = [];
    final List<String> foundProductDetails = [];

    for (final interaction in recentInteractions) {
      final question = interaction['question'] as String;
      final answer = interaction['answer'] as String;

      // Skip if the question contains context strings (avoid processing processed context)
      if (_isContextString(question)) {
        continue;
      }

      // Prioritize user's question over AI's answer for context extraction
      String? productName = _extractProductNameFromUserQuestion(question);
      if (productName == null) {
        productName = _extractProductNameFromText(question);
      }

      if (productName != null && _isValidProductName(productName)) {
        if (kDebugMode) {
          print('Extracted product name from user question: "$productName"');
        }
        foundProducts.add(productName);

        // Store additional context about this product
        final productDetail = _extractProductDetail(answer, productName);
        if (productDetail.isNotEmpty) {
          foundProductDetails.add('$productName: $productDetail');
        }
      }

      // Only use AI answer if no product found in user question
      if (productName == null) {
        productName = _extractProductNameFromText(answer);
        if (productName != null && _isValidProductName(productName)) {
          if (kDebugMode) {
            print('Extracted product name from AI answer: "$productName"');
          }
          foundProducts.add(productName);

          // Store additional context about this product
          final productDetail = _extractProductDetail(answer, productName);
          if (productDetail.isNotEmpty) {
            foundProductDetails.add('$productName: $productDetail');
          }
        }
      }
    }

    // Return the most specific product name found
    if (foundProducts.isNotEmpty) {
      // Sort by specificity (longer names are usually more specific)
      foundProducts.sort((a, b) => b.length.compareTo(a.length));
      final selectedProduct = foundProducts.first;

      if (kDebugMode) {
        print('Found products in context: $foundProducts');
        print('Product details: $foundProductDetails');
        print('Selected most specific: "$selectedProduct"');
      }

      return selectedProduct;
    }

    return null;
  }

  /// Update conversation history
  Future<void> updateHistory(
      String userId, String question, String answer) async {
    // Ensure user history is initialized
    await initializeUserHistory(userId);

    if (!_conversationHistory.containsKey(userId)) {
      _conversationHistory[userId] = [];
    }

    final history = _conversationHistory[userId]!;
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add new interaction - explicitly cast to Map<String, dynamic>
    final newInteraction = <String, dynamic>{
      'question': question,
      'answer': answer,
      'timestamp': DateTime.now(),
      'messageId': messageId,
    };
    history.add(newInteraction);

    // Keep only the last N interactions
    if (history.length > _maxHistoryLength) {
      history.removeRange(0, history.length - _maxHistoryLength);
    }

    // Save to both SharedPreferences and Firebase
    await Future.wait([
      _saveToSharedPreferences(userId),
      _saveToFirebase(userId, question, answer),
    ]);
  }

  /// Clear conversation history for a specific user
  Future<void> clearConversationHistory(String userId) async {
    _conversationHistory.remove(userId);

    try {
      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyKey = '$_prefKeyPrefix$userId';
      final lastSyncKey = '$_lastSyncKeyPrefix$userId';

      await prefs.remove(historyKey);
      await prefs.remove(lastSyncKey);

      // Clear from Firebase
      await _firestore.collection('chats').doc(userId).delete();

      if (kDebugMode) {
        print('Cleared conversation history for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing conversation history: $e');
      }
    }
  }

  /// Get conversation history for a specific user
  Future<List<Map<String, dynamic>>> getConversationHistory(
      String userId) async {
    // Ensure user history is initialized
    await initializeUserHistory(userId);
    return _conversationHistory[userId] ?? [];
  }

  /// Get formatted conversation history for model fine-tuning
  Future<String> getFormattedConversationHistory(String userId) async {
    final history = await getConversationHistory(userId);
    if (history.isEmpty) {
      return 'No conversation history available.';
    }

    final buffer = StringBuffer();
    buffer.writeln('CONVERSATION HISTORY FOR MODEL FINE-TUNING:');
    buffer.writeln('===========================================');

    for (int i = 0; i < history.length; i++) {
      final interaction = history[i];
      final question = interaction['question'] as String;
      final answer = interaction['answer'] as String;
      final timestamp = interaction['timestamp'] as DateTime;

      buffer.writeln('Interaction ${i + 1} (${timestamp.toIso8601String()}):');
      buffer.writeln('User: $question');
      buffer.writeln('Assistant: $answer');
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Export conversation data for analysis and fine-tuning
  Future<Map<String, dynamic>> exportConversationData(String userId) async {
    final history = await getConversationHistory(userId);
    if (history.isEmpty) {
      return {
        'userId': userId,
        'totalInteractions': 0,
        'conversations': [],
        'productMentions': [],
        'addToCartActions': [],
      };
    }

    final productMentions = <String>[];
    final addToCartActions = <Map<String, dynamic>>[];

    for (final interaction in history) {
      final question = interaction['question'] as String;
      final answer = interaction['answer'] as String;

      // Extract product mentions
      final productName = _extractProductNameFromText(question) ??
          _extractProductNameFromText(answer);
      if (productName != null) {
        productMentions.add(productName);
      }

      // Track add-to-cart actions
      if (_utils.isAddToCartRequest(question)) {
        final addToCartAction = <String, dynamic>{
          'question': question,
          'answer': answer,
          'timestamp': interaction['timestamp'],
          'productName': productName,
        };
        addToCartActions.add(addToCartAction);
      }
    }

    return {
      'userId': userId,
      'totalInteractions': history.length,
      'conversations': history,
      'productMentions': productMentions.toSet().toList(),
      'addToCartActions': addToCartActions,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Check if user has recent conversation history
  Future<bool> hasRecentHistory(String userId) async {
    final history = await getConversationHistory(userId);
    if (history.isEmpty) return false;

    final now = DateTime.now();
    final lastInteraction = history.last['timestamp'] as DateTime;
    return now.difference(lastInteraction) <= _historyExpiration;
  }

  /// Force sync from Firebase (useful for manual refresh)
  Future<void> forceSyncFromFirebase(String userId) async {
    await _syncFromFirebase(userId);
  }

  /// Get conversation statistics
  Future<Map<String, dynamic>> getConversationStats(String userId) async {
    final history = await getConversationHistory(userId);
    final now = DateTime.now();

    final totalMessages = history.length;
    final recentMessages = history.where((msg) {
      final timestamp = msg['timestamp'] as DateTime;
      return now.difference(timestamp) <= const Duration(hours: 24);
    }).length;

    final addToCartRequests = history.where((msg) {
      return _utils.isAddToCartRequest(msg['question'] as String);
    }).length;

    final productQuestions = history.where((msg) {
      return _utils.isProductQuestion(msg['question'] as String);
    }).length;

    return {
      'totalMessages': totalMessages,
      'recentMessages24h': recentMessages,
      'addToCartRequests': addToCartRequests,
      'productQuestions': productQuestions,
      'lastActivity': history.isNotEmpty ? history.last['timestamp'] : null,
    };
  }

  // Private helper methods (keep existing methods)
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

  /// Extract product information from AI response
  String _extractProductInfo(String answer) {
    final productInfo = <String>[];

    // Look for product names in the response
    final productName = _extractProductNameFromText(answer);
    if (productName != null) {
      productInfo.add('Product: $productName');
    }

    // Look for price information
    final pricePattern = RegExp(r'\[\d,]₫+\.?\d*');
    final priceMatches = pricePattern.allMatches(answer);
    if (priceMatches.isNotEmpty) {
      productInfo.add('Price: ${priceMatches.first.group(0)}');
    }

    // Look for stock information
    if (answer.toLowerCase().contains('stock') ||
        answer.toLowerCase().contains('kho')) {
      final stockPattern =
          RegExp(r'(?:stock|kho)\s*:?\s*(\d+)', caseSensitive: false);
      final stockMatch = stockPattern.firstMatch(answer);
      if (stockMatch != null) {
        productInfo.add('Stock: ${stockMatch.group(1)}');
      }
    }

    return productInfo.join(', ');
  }

  /// Extract product detail information from AI response
  String _extractProductDetail(String answer, String productName) {
    final details = <String>[];

    // Look for price information near the product name
    final pricePattern = RegExp(r'\[\d,]₫+\.?\d*');
    final priceMatches = pricePattern.allMatches(answer);
    if (priceMatches.isNotEmpty) {
      details.add('Price: ${priceMatches.first.group(0)}');
    }

    // Look for stock information
    if (answer.toLowerCase().contains('stock') ||
        answer.toLowerCase().contains('kho')) {
      final stockPattern =
          RegExp(r'(?:stock|kho)\s*:?\s*(\d+)', caseSensitive: false);
      final stockMatch = stockPattern.firstMatch(answer);
      if (stockMatch != null) {
        details.add('Stock: ${stockMatch.group(1)}');
      }
    }

    // Look for category information
    final categoryPattern =
        RegExp(r'(?:category|danh mục)\s*:?\s*(\w+)', caseSensitive: false);
    final categoryMatch = categoryPattern.firstMatch(answer);
    if (categoryMatch != null) {
      details.add('Category: ${categoryMatch.group(1)}');
    }

    return details.join(', ');
  }

  /// Check if a string contains context information (to avoid processing processed context)
  bool _isContextString(String text) {
    final contextKeywords = [
      'CONVERSATION CONTEXT',
      'Interaction',
      'ago:',
      'Q:',
      'A:',
      'Key entities:',
      'Product info:',
      'CURRENT QUESTION:',
      'NOTE:',
      '=====================================',
      '====================='
    ];

    return contextKeywords.any((keyword) => text.contains(keyword));
  }

  /// Validate if a product name is reasonable (not too long, contains valid characters)
  bool _isValidProductName(String productName) {
    // Product name should not be too long (likely not a real product name)
    if (productName.length > 100) {
      return false;
    }

    // Product name should not contain context keywords
    if (_isContextString(productName)) {
      return false;
    }

    // Product name should contain at least one letter or number
    if (!RegExp(r'[a-zA-Z0-9]').hasMatch(productName)) {
      return false;
    }

    // Product name should not be just common words
    final commonWords = [
      'sorry',
      'currently',
      'products',
      'matching',
      'requirements',
      'updating',
      'soon',
      'leave',
      'contact',
      'information',
      'notified',
      'arrive',
      'xin lỗi',
      'hiện tại',
      'sản phẩm',
      'phù hợp',
      'yêu cầu',
      'cập nhật',
      'sớm',
      'để lại',
      'thông tin',
      'liên hệ',
      'thông báo',
      'đến'
    ];

    final lowerProductName = productName.toLowerCase();
    if (commonWords.any((word) => lowerProductName.contains(word))) {
      return false;
    }

    return true;
  }

  String? _extractProductNameFromText(String text) {
    return _utils.extractProductNameFromText(text);
  }

  String? _extractProductNameFromUserQuestion(String question) {
    return _utils.extractProductNameFromUserQuestion(question);
  }

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
}
