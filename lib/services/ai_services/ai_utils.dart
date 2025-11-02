import 'package:flutter/foundation.dart';

class AIUtils {
  /// Detect if text is Vietnamese
  bool isVietnamese(String text) {
    final vietnameseChars = RegExp(
        r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]');
    return vietnameseChars.hasMatch(text.toLowerCase());
  }

  /// Detect if message is a greeting
  bool isGreeting(String message) {
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

  /// Detect if message is about store
  bool isStoreQuestion(String message) {
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

  /// Detect if message is about products
  bool isProductQuestion(String message) {
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

  /// Detect if message is about favorites
  bool isFavoriteQuestion(String message) {
    final favoriteKeywords = {
      'en': ['favorite', 'favourite', 'like', 'save', 'bookmark', 'wishlist'],
      'vi': ['yêu thích', 'thích', 'lưu', 'đánh dấu', 'wishlist']
    };

    final isVietnameseText = isVietnamese(message);
    final keywords = favoriteKeywords[isVietnameseText ? 'vi' : 'en']!;
    return keywords.any(
        (keyword) => message.toLowerCase().contains(keyword.toLowerCase()));
  }

  /// Detect if message is about cart
  bool isCartQuestion(String message) {
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
        'items in cart',
        'how many',
        'quantity',
        'count',
        'total items',
        'items count'
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
        'giỏ',
        'bao nhiêu',
        'số lượng',
        'đếm',
        'tổng sản phẩm',
        'số sản phẩm'
      ]
    };

    final lowerMessage = message.toLowerCase();
    return cartKeywords['en']!
            .any((keyword) => lowerMessage.contains(keyword)) ||
        cartKeywords['vi']!.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Detect if message is asking about cart quantity
  bool isCartQuantityQuestion(String message) {
    final quantityKeywords = {
      'en': [
        'how many',
        'quantity',
        'count',
        'total items',
        'items count',
        'how much',
        'number of',
        'amount of'
      ],
      'vi': [
        'bao nhiêu',
        'số lượng',
        'đếm',
        'tổng sản phẩm',
        'số sản phẩm',
        'bao nhiêu cái',
        'mấy cái',
        'số lượng bao nhiêu'
      ]
    };

    final isVietnameseText = isVietnamese(message);
    final keywords = quantityKeywords[isVietnameseText ? 'vi' : 'en']!;
    final lowerMessage = message.toLowerCase();

    return keywords.any((keyword) => lowerMessage.contains(keyword)) &&
        isCartQuestion(message);
  }

  /// Detect if message is about invoices
  bool isInvoiceQuestion(String message) {
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

  /// Detect if message is about vouchers
  bool isVoucherQuestion(String message) {
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

  /// Detect add to cart requests
  bool isAddToCartRequest(String message) {
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

    final isVietnameseText = isVietnamese(message);
    final keywords = addToCartKeywords[isVietnameseText ? 'vi' : 'en']!;
    final lowerMessage = message.toLowerCase();

    final hasKeyword =
        keywords.any((keyword) => lowerMessage.contains(keyword.toLowerCase()));

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

  /// Extract product name from add to cart request
  String? extractProductNameFromRequest(String message) {
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
          extractedName = cleanProductName(extractedName);
          if (extractedName.isNotEmpty && !isOnlyCommonWords(extractedName)) {
            if (kDebugMode) {
              print(
                  'Extracted product name from add-to-cart pattern: "$extractedName"');
            }
            return extractedName;
          }
        }
      }
    }

    // Second, try to extract by looking for brand patterns
    final brandPattern = RegExp(
        r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\b',
        caseSensitive: false);

    final brandMatch = brandPattern.firstMatch(message);
    if (brandMatch != null) {
      final brand = brandMatch.group(0)!;
      final startIndex = message.toLowerCase().indexOf(brand.toLowerCase());
      if (startIndex >= 0) {
        final endIndex = startIndex + brand.length;
        final beforeBrand = message.substring(0, startIndex).trim();
        final afterBrand = message.substring(endIndex).trim();
        var fullName = '$beforeBrand $brand $afterBrand'.trim();
        fullName = cleanProductName(fullName);

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

        if (fullName.isNotEmpty && !isOnlyCommonWords(fullName)) {
          if (kDebugMode) {
            print('Extracted product name from brand pattern: "$fullName"');
          }
          return fullName;
        }
      }
    }

    // Third, try to extract product names with numbers (like "RTX 4070", "Core i5")
    final productPatterns = [
      RegExp(r'\b(?:RTX|GTX)\s+\d+[A-Z]*\b', caseSensitive: false),
      RegExp(r'\b(?:Core i[3579])\s+\d+[A-Z]*\b', caseSensitive: false),
      RegExp(r'\b(?:Ryzen [3579])\s+\d+[A-Z]*\b', caseSensitive: false),
      RegExp(r'\b(?:DDR\d+)\s+\d+[A-Z]*\b', caseSensitive: false),
    ];

    for (final pattern in productPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final productName = match.group(0)!.trim();
        if (kDebugMode) {
          print('Extracted product name from product pattern: "$productName"');
        }
        return productName;
      }
    }

    if (kDebugMode) {
      print('No product name extracted from message: "$message"');
    }
    return null;
  }

  /// Extract quantity from request
  int extractQuantityFromRequest(String message) {
    final quantityPatterns = [
      // Match numbers before product names (e.g., "2 RTX 4070", "3 Intel Core i5")
      RegExp(
          r'(\d+)\s+(?:RTX|GTX|Intel|AMD|Samsung|Kingston|Corsair|ASUS|MSI|Gigabyte)',
          caseSensitive: false),
      // Match numbers with quantity words
      RegExp(r'(\d+)\s*(?:piece|pieces|pc|pcs|unit|units|item|items)',
          caseSensitive: false),
      RegExp(r'(\d+)\s*(?:cái|chiếc|bộ|thùng)', caseSensitive: false),
      RegExp(r'quantity\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'số\s*lượng\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:x|times)', caseSensitive: false),
      // Match numbers at the beginning of add to cart patterns
      RegExp(r'add\s+(\d+)\s+', caseSensitive: false),
      RegExp(r'thêm\s+(\d+)\s+', caseSensitive: false),
      RegExp(r'buy\s+(\d+)\s+', caseSensitive: false),
      RegExp(r'mua\s+(\d+)\s+', caseSensitive: false),
    ];

    for (final pattern in quantityPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final quantity = int.tryParse(match.group(1) ?? '1');
        if (quantity != null && quantity > 0) {
          if (kDebugMode) {
            print(
                'Extracted quantity: $quantity from pattern: ${pattern.pattern}');
          }
          return quantity;
        }
      }
    }

    if (kDebugMode) {
      print('No quantity found in message: "$message", defaulting to 1');
    }
    return 1;
  }

  /// Detect product category from message
  String? detectProductCategory(String message) {
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
        return entry.key;
      }
    }
    return null;
  }

  /// Extract search keywords from message
  List<String> extractSearchKeywords(String message) {
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

  /// Extract product name from text
  String? extractProductNameFromText(String text) {
    final productPatterns = [
      RegExp(
          r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\s+(?:HyperX\s+)?(?:Fury|Core|Ryzen|RTX|GTX|DDR\d+)\s+(?:\d+[A-Z]*|[^\s]+(?:\s+[^\s]+)*)',
          caseSensitive: false),
      RegExp(
          r'\b(?:Core i[3579]\s*\d+[A-Z]*|Ryzen\s*[3579]\s*\d+[A-Z]*|RTX\s*\d+\s*[A-Z]*|GTX\s*\d+\s*[A-Z]*)\b',
          caseSensitive: false),
      RegExp(r'\b(?:DDR\d+)\s+(?:\d+)\s*(?:GB|MB)\s*(?:\d+)?\s*(?:MHz)?\b',
          caseSensitive: false),
      RegExp(
          r'["""]([^"""]*(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)[^"""]*)["""]',
          caseSensitive: false),
      RegExp(
          r'(?:Product Name|Name|Model):\s*([^:\n]*?(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)[^:\n]*?)(?:\n|$)',
          caseSensitive: false),
      RegExp(
          r'\b(?:tell me about|show me|what about|info about|details about)\s+([^.!?]*?(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)[^.!?]*?)(?:\s|$)',
          caseSensitive: false),
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
          productName = productName.replaceAll(RegExp(r'^\s*[:"""]\s*'), '');
          productName = productName.replaceAll(RegExp(r'\s*[:"""]\s*$'), '');
          productName = productName.replaceAll(
              RegExp(r'\s+category\s*:?\s*$', caseSensitive: false), '');
          productName = productName.replaceAll(RegExp(r'\s+$'), '');
          productName = cleanProductName(productName);

          if (isCompleteProductName(productName)) {
            return productName;
          }
        }
      }
    }

    return null;
  }

  /// Extract product name from user question
  String? extractProductNameFromUserQuestion(String question) {
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

    final brandPattern = RegExp(
        r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\b',
        caseSensitive: false);

    final brandMatch = brandPattern.firstMatch(cleanedQuestion);
    if (brandMatch != null) {
      final brand = brandMatch.group(0)!;
      final startIndex = question.toLowerCase().indexOf(brand.toLowerCase());
      if (startIndex >= 0) {
        final endIndex = startIndex + brand.length;
        final beforeBrand = question.substring(0, startIndex).trim();
        final afterBrand = question.substring(endIndex).trim();
        var fullName = '$beforeBrand $brand $afterBrand'.trim();
        fullName = cleanProductName(fullName);
        return fullName;
      }
    }

    return null;
  }

  /// Validate if the extracted name is a complete product name
  bool isCompleteProductName(String productName) {
    final incompletePatterns = [
      RegExp(r'^[A-Za-z]+\s+(?:RAM|CPU|GPU|SSD|HDD|PSU|Mainboard)\s*$',
          caseSensitive: false),
      RegExp(r'^[A-Za-z]+\s+category\s*:?\s*$', caseSensitive: false),
      RegExp(r'^[A-Za-z]+\s*$', caseSensitive: false),
    ];

    for (final pattern in incompletePatterns) {
      if (pattern.hasMatch(productName)) {
        return false;
      }
    }

    final hasBrand = RegExp(
            r'\b(?:Kingston|Intel|AMD|NVIDIA|Samsung|Corsair|ASUS|MSI|Gigabyte)\b',
            caseSensitive: false)
        .hasMatch(productName);
    final hasModel = RegExp(
            r'\b(?:HyperX|Fury|Core|Ryzen|RTX|GTX|DDR\d+|\d+[A-Z]*)\b',
            caseSensitive: false)
        .hasMatch(productName);

    if (hasBrand) {
      if (productName.length > 5) {
        return true;
      }
    }

    return hasBrand && hasModel;
  }

  /// Clean up product name
  String cleanProductName(String productName) {
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

    for (final word in unwantedWords) {
      cleanedName = cleanedName.replaceAll(
          RegExp(r'\b$word\b', caseSensitive: false), '');
    }

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

    cleanedName = cleanedName
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleanedName;
  }

  /// Check if the cleaned message contains only common words
  bool isOnlyCommonWords(String message) {
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
      'tại'
    ];

    final words = message.toLowerCase().split(' ');
    return words.every((word) => commonWords.contains(word) || word.length < 3);
  }

  /// Remove markdown formatting but keep simple dash bullets
  String sanitizeMarkdown(String input) {
    var text = input;
    text = text.replaceAllMapped(
        RegExp(r"\*\*([^*]+)\*\*"), (m) => m.group(1) ?? "");
    text =
        text.replaceAllMapped(RegExp(r"\*([^*]+)\*"), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(RegExp(r"_([^_]+)_"), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(
        RegExp(r"~{2}([^~]+)~{2}"), (m) => m.group(1) ?? "");
    text = text.replaceAll(RegExp(r"^#{1,6}\s+", multiLine: true), "");
    text =
        text.replaceAllMapped(RegExp(r"```[\s\S]*?```", multiLine: true), (m) {
      final inner = m
          .group(0)!
          .replaceAll(RegExp(r"^```[a-zA-Z]*\n?"), "")
          .replaceAll("```", "");
      return inner.trim();
    });
    text = text.replaceAllMapped(RegExp(r"`([^`]+)`"), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(
        RegExp(r"\[([^\]]+)\]\(([^)]+)\)"), (m) => m.group(1) ?? "");
    text = text.replaceAllMapped(
        RegExp(r"!\[([^\]]*)\]\(([^)]+)\)"), (m) => m.group(1) ?? "");
    text = text.replaceAll(RegExp(r"^>\s?", multiLine: true), "");
    text =
        text.replaceAll(RegExp(r"^(-{3,}|\*{3,}|_{3,})$", multiLine: true), "");
    text = text.replaceAll(RegExp(r"^\s*[\*\+]\s+", multiLine: true), "- ");
    text = text.replaceAll(
        RegExp(r"^\s*[•·▪►➤⦿⦾●○◆◇•]\s*", multiLine: true), "- ");
    text = text.replaceAll(RegExp(r"^\s*\d+\.\s+", multiLine: true), "- ");
    text = text.replaceAll(RegExp(r"^-\s{2,}", multiLine: true), "- ");
    text = text.replaceAll(RegExp(r"\\(?=\₫\d)"), "");
    text = text.replaceAll(RegExp(r"[ \t]+$", multiLine: true), "");
    return text.trim();
  }

  /// Get product not found response
  String getProductNotFoundResponse(bool isVietnamese) {
    if (isVietnamese) {
      return 'Tôi không thể tìm thấy sản phẩm nào trong cuộc trò chuyện gần đây. Vui lòng chỉ rõ tên sản phẩm bạn muốn thêm vào giỏ hàng. Ví dụ: "Thêm Intel Core i5 vào giỏ hàng" hoặc "Add RTX 3080 to cart".';
    } else {
      return 'I couldn\'t find any product mentioned in our recent conversation. Please specify the product name you want to add to cart. For example: "Add Intel Core i5 to cart" or "Thêm RTX 3080 vào giỏ hàng".';
    }
  }
}
