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
      // Ensure existing history is properly converted (in case it contains IdentityMaps)
      final existingHistory = _conversationHistory[userId]!;
      _conversationHistory[userId] = _normalizeHistory(existingHistory);
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
          _conversationHistory[userId] = _normalizeHistory(history);
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

  /// Normalize history to ensure all maps are regular Map<String, dynamic>, not IdentityMaps
  List<Map<String, dynamic>> _normalizeHistory(
      List<Map<String, dynamic>> history) {
    return history.map((interaction) {
      return <String, dynamic>{
        'question': interaction['question']?.toString() ?? '',
        'answer': interaction['answer']?.toString() ?? '',
        'timestamp': interaction['timestamp'] is DateTime
            ? interaction['timestamp'] as DateTime
            : (interaction['timestamp'] is String
                ? DateTime.tryParse(interaction['timestamp'] as String) ??
                    DateTime.now()
                : DateTime.now()),
        'messageId': interaction['messageId']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
      };
    }).toList();
  }

  /// Sync conversation history from Firebase
  Future<void> _syncFromFirebase(String userId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(userId).get();

      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        final messages = <Map<String, dynamic>>[];

        // Convert Firebase document to conversation format
        // Convert the entire data map to avoid IdentityMap issues
        final dataMap = Map<String, dynamic>.from(data);
        dataMap.forEach((key, value) {
          if (value is Map) {
            // Convert IdentityMap to regular Map to avoid type errors
            final message = Map<String, dynamic>.from(value);
            if (message['content'] != null && message['timestamp'] != null) {
              // Ensure timestamp is properly converted
              final timestamp = message['timestamp'];
              final timestampDate = timestamp is Timestamp
                  ? timestamp.toDate()
                  : (timestamp is DateTime ? timestamp : DateTime.now());

              final newMessage = <String, dynamic>{
                'question': message['content']?.toString() ?? '',
                'answer': (message['aiResponse'] ?? 'No response available')
                    .toString(),
                'timestamp': timestampDate,
                'messageId': key,
              };
              messages.add(newMessage);
            }
          }
        });

        // Sort DESCENDING (newest first)
        messages.sort((a, b) =>
            (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

        // Then take first 10 = newest 10
        final recentMessages = messages.take(_maxHistoryLength).toList();

        _conversationHistory[userId] = _normalizeHistory(recentMessages);

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

      // Get current document
      final docRef = _firestore.collection('chats').doc(userId);
      final docSnapshot = await docRef.get();

      Map<String, dynamic> currentData =
          docSnapshot.exists ? docSnapshot.data() as Map<String, dynamic> : {};

      // Add new message
      currentData[messageId] = messageData;

      // Get all message IDs and sort by timestamp (oldest first)
      final messageIds = currentData.keys
          .where((key) =>
              currentData[key] is Map && currentData[key]['messageId'] != null)
          .toList();

      // If we have more than max messages, remove oldest ones
      // Use a lower limit for Firebase (50) to keep document size manageable
      const maxFirebaseMessages = 50;
      if (messageIds.length > maxFirebaseMessages) {
        // Sort by messageId (which is timestamp in milliseconds)
        messageIds.sort((a, b) {
          final timestampA = int.tryParse(a) ?? 0;
          final timestampB = int.tryParse(b) ?? 0;
          return timestampA.compareTo(timestampB);
        });

        // Remove oldest messages
        final messagesToRemove = messageIds.length - maxFirebaseMessages;
        for (int i = 0; i < messagesToRemove; i++) {
          currentData.remove(messageIds[i]);
        }

        if (kDebugMode) {
          print(
              'Removed $messagesToRemove old messages to keep document size under limit');
        }
      }

      // Update document with limited messages
      await docRef.set(currentData, SetOptions(merge: true));

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
  /// Always includes conversation context when history exists
  Future<String> processContext(String userMessage, String userId) async {
    // Ensure user history is initialized
    await initializeUserHistory(userId);

    final now = DateTime.now();
    final history = _conversationHistory[userId];

    // If no history, return message as-is
    if (history == null || history.isEmpty) {
      return userMessage;
    }

    // Clear old history if exists
    final lastInteraction = history.last['timestamp'] as DateTime;
    if (now.difference(lastInteraction) > _historyExpiration) {
      _conversationHistory.remove(userId);
      await _saveToSharedPreferences(userId);
      return userMessage;
    }

    // Always include context when history exists
    final hasContextReferences = _hasContextReferences(userMessage);
    final isAddToCartRequest = _utils.isAddToCartRequest(userMessage);

    // Build context - include more details for explicit references or add-to-cart
    final includeDetailedContext = hasContextReferences || isAddToCartRequest;

    final contextBuilder = StringBuffer();
    contextBuilder.writeln('CONVERSATION CONTEXT:');
    contextBuilder.writeln('==============================================');

    // Include last 5-10 interactions depending on context need
    final contextLength = includeDetailedContext ? 10 : 5;
    // Take the LAST N messages (most recent), then reverse so newest is first
    final startIndex =
        history.length > contextLength ? history.length - contextLength : 0;
    final recentHistory = history.sublist(startIndex).reversed.toList();

    for (int i = 0; i < recentHistory.length; i++) {
      final interaction = recentHistory[i];
      final question = interaction['question'] as String;
      final answer = interaction['answer'] as String;
      final timestamp = interaction['timestamp'] as DateTime;
      final timeAgo = _formatTimeAgo(now.difference(timestamp));

      contextBuilder.writeln('Interaction ${i + 1} ($timeAgo ago):');
      contextBuilder.writeln('Q: $question');

      if (includeDetailedContext) {
        // Full answer for detailed context
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
      } else {
        // Summary for general context (keep it concise)
        final summary = _summarizeAnswer(answer);
        contextBuilder.writeln('A: $summary');
      }
      contextBuilder.writeln('---');
    }

    contextBuilder.writeln('CURRENT QUESTION: $userMessage');
    if (isAddToCartRequest) {
      contextBuilder.writeln(
          'NOTE: This appears to be an add-to-cart request. Use context to identify the product.');
    } else if (hasContextReferences) {
      contextBuilder.writeln(
          'NOTE: User may be referring to previous topics. Use context to understand references.');
    } else {
      contextBuilder.writeln(
          'NOTE: Use conversation context to provide relevant and coherent responses.');
    }
    contextBuilder.writeln('==============================================');

    return contextBuilder.toString();
  }

  /// Summarize answer for concise context inclusion
  String _summarizeAnswer(String answer) {
    // Extract key information: product names, prices, stock
    final productNames = _extractProductNames(answer);
    final priceInfo = _extractPriceInfo(answer);
    final stockInfo = _extractStockInfo(answer);

    final parts = <String>[];
    if (productNames.isNotEmpty) {
      parts.add('Products: ${productNames.join(', ')}');
    }
    if (priceInfo.isNotEmpty) {
      parts.add('Prices: ${priceInfo.join(', ')}');
    }
    if (stockInfo.isNotEmpty) {
      parts.add('Stock: ${stockInfo.join(', ')}');
    }

    // If we have key info, return summary; otherwise return first 100 chars
    if (parts.isNotEmpty) {
      return parts.join(' | ');
    }

    // Fallback: return first 100 characters
    return answer.length > 100 ? '${answer.substring(0, 100)}...' : answer;
  }

  /// Extract product names from text
  List<String> _extractProductNames(String text) {
    final names = <String>[];
    // Look for patterns like [PRODUCT_NAME:...] or product names in quotes
    final productPattern = RegExp(r'\[PRODUCT_NAME:([^\]]+)\]|"([^"]+)"');
    final matches = productPattern.allMatches(text);
    for (final match in matches) {
      final name = match.group(1) ?? match.group(2) ?? '';
      if (name.isNotEmpty && name.length > 3) {
        names.add(name);
      }
    }
    return names;
  }

  /// Extract price information from text
  List<String> _extractPriceInfo(String text) {
    final prices = <String>[];
    // Look for currency patterns
    final pricePattern = RegExp(r'\d+[.,]\d+\s*₫|\d+\s*₫');
    final matches = pricePattern.allMatches(text);
    for (final match in matches.take(3)) {
      prices.add(match.group(0)!);
    }
    return prices;
  }

  /// Extract stock information from text
  List<String> _extractStockInfo(String text) {
    final stock = <String>[];
    // Look for stock patterns
    final stockPattern = RegExp(
        r'(?:stock|kho|tồn kho|available|available|in stock|còn hàng)[:\s]+(\d+)',
        caseSensitive: false);
    final matches = stockPattern.allMatches(text);
    for (final match in matches.take(2)) {
      stock.add(match.group(1)!);
    }
    return stock;
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
      productName ??= _extractProductNameFromText(question);

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

      // Always check AI answer for product names (may have more specific info)
      // Extract all product names from answer, not just one
      final answerProductNames = _extractAllProductNames(answer);
      for (final answerProductName in answerProductNames) {
        if (answerProductName != null &&
            _isValidProductName(answerProductName) &&
            !foundProducts.contains(answerProductName)) {
          if (kDebugMode) {
            print(
                'Extracted product name from AI answer: "$answerProductName"');
          }
          foundProducts.add(answerProductName);

          // Store additional context about this product
          final productDetail =
              _extractProductDetail(answer, answerProductName);
          if (productDetail.isNotEmpty) {
            foundProductDetails.add('$answerProductName: $productDetail');
          }
        }
      }

      // If still no product found, try the original single extraction
      if (productName == null && foundProducts.isEmpty) {
        productName = _extractProductNameFromText(answer);
        if (productName != null && _isValidProductName(productName)) {
          if (kDebugMode) {
            print(
                'Extracted product name from AI answer (fallback): "$productName"');
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
    final history = _conversationHistory[userId] ?? [];
    // Normalize to ensure no IdentityMaps
    return _normalizeHistory(history);
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

  /// Extract all product names from text (not just the first one)
  List<String?> _extractAllProductNames(String text) {
    final productNames = <String?>[];

    // Use the same patterns as extractProductNameFromText but get all matches
    final productPatterns = [
      // Match "CPU Intel Core Ultra 7 265" or "CPU Intel Core i7 12700K" format
      RegExp(
          r'\b(?:CPU\s+)?(?:Intel|AMD|NVIDIA|Samsung|Kingston|Corsair|ASUS|MSI|Gigabyte)\s+(?:Core\s+(?:Ultra\s*[3579]\s*\d+|i[3579]\s*\d+[A-Z]*)|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*|HyperX\s+Fury|DDR\d+)\b',
          caseSensitive: false,
          unicode: true),
      RegExp(
          r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\s+(?:HyperX\s+)?(?:Fury|Core|Ryzen|RTX|GTX|DDR\d+)\s+(?:\d+[A-Z]*|[^\s]+(?:\s+[^\s]+)*)',
          caseSensitive: false,
          unicode: true),
      RegExp(
          r'\b(?:Core\s+(?:Ultra\s*[3579]\s*\d+|i[3579]\s*\d+[A-Z]*)|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*)\b',
          caseSensitive: false,
          unicode: true),
    ];

    for (final pattern in productPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        String? productName = match.group(0)?.trim();
        if (productName != null && productName.length > 3) {
          productName = _utils.cleanProductName(productName);
          if (productName.isNotEmpty && _isValidProductName(productName)) {
            productNames.add(productName);
          }
        }
      }
    }

    // Also try the standard extraction method
    final singleExtraction = _utils.extractProductNameFromText(text);
    if (singleExtraction != null && !productNames.contains(singleExtraction)) {
      productNames.add(singleExtraction);
    }

    return productNames;
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
