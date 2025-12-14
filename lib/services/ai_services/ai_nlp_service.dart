import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// NLP Service for product understanding using Gemini API
///
/// This service uses Gemini's NLP capabilities to:
/// - Understand product synonyms and variations
/// - Extract product features and specifications
/// - Recognize user intent and product categories
/// - Map colloquial terms to technical product names
class AINLPService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Analyze user query to extract product information and intent
  Future<Map<String, dynamic>> analyzeProductQuery(
      String userQuery, bool isVietnamese) async {
    try {
      final prompt = _createAnalysisPrompt(userQuery, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      if (kDebugMode) {
        print('NLP Analysis Response: $response');
      }

      return _parseAnalysisResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in NLP analysis: $e');
      }
      return _getFallbackAnalysis(userQuery);
    }
  }

  /// Extract product synonyms and variations
  Future<List<String>> getProductSynonyms(
      String productName, bool isVietnamese) async {
    try {
      final prompt = _createSynonymsPrompt(productName, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      return _parseSynonymsResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting synonyms: $e');
      }
      return [productName];
    }
  }

  /// Map colloquial terms to technical product names
  Future<String?> mapToTechnicalName(
      String colloquialTerm, bool isVietnamese) async {
    try {
      final prompt = _createMappingPrompt(colloquialTerm, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      return _parseMappingResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error mapping to technical name: $e');
      }
      return null;
    }
  }

  /// Understand product features from user description
  Future<Map<String, dynamic>> extractProductFeatures(
      String userDescription, bool isVietnamese) async {
    try {
      final prompt =
          _createFeatureExtractionPrompt(userDescription, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      return _parseFeatureResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting features: $e');
      }
      return {};
    }
  }

  /// Extract product name using NLP when regex patterns fail
  /// This uses Gemini to intelligently extract product names from text
  Future<String?> extractProductNameWithNLP(
      String text, bool isVietnamese) async {
    try {
      final prompt = _createProductNameExtractionPrompt(text, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      if (kDebugMode) {
        print('NLP Product Name Extraction Response: $response');
      }

      return _parseProductNameResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in NLP product name extraction: $e');
      }
      return null;
    }
  }

  /// Extract multiple product names from text using NLP
  /// This is more flexible than regex and can handle various formats
  Future<List<String>> extractProductNamesFromText(
      String text, bool isVietnamese) async {
    try {
      final prompt =
          _createMultipleProductNamesExtractionPrompt(text, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      if (kDebugMode) {
        print('NLP Multiple Product Names Extraction Response: $response');
      }

      return _parseMultipleProductNamesResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in NLP multiple product names extraction: $e');
      }
      return [];
    }
  }

  // Private helper methods

  String _createAnalysisPrompt(String userQuery, bool isVietnamese) {
    return isVietnamese
        ? '''
Bạn là một chuyên gia về phần cứng máy tính. Hãy phân tích câu hỏi của khách hàng và trích xuất thông tin sản phẩm.

Câu hỏi của khách hàng: "$userQuery"

Hãy trả lời theo định dạng JSON sau:
{
  "product_name": "tên sản phẩm chính xác",
  "category": "cpu|gpu|ram|psu|drive|mainboard",
  "brand": "thương hiệu",
  "features": ["tính năng 1", "tính năng 2"],
  "synonyms": ["từ đồng nghĩa 1", "từ đồng nghĩa 2"],
  "intent": "search|compare|specs|price",
  "confidence": 0.95
}

Lưu ý:
- "drive" bao gồm SSD, HDD, NVMe
- "Corsair drive" = "Corsair SSD" hoặc "Corsair HDD"
- "Intel processor" = "Intel CPU"
- "graphics card" = "GPU"
- "memory" = "RAM"
'''
        : '''
You are a computer hardware expert. Analyze the customer's question and extract product information.

Customer question: "$userQuery"

Please respond in the following JSON format:
{
  "product_name": "exact product name",
  "category": "cpu|gpu|ram|psu|drive|mainboard",
  "brand": "brand name",
  "features": ["feature1", "feature2"],
  "synonyms": ["synonym1", "synonym2"],
  "intent": "search|compare|specs|price",
  "confidence": 0.95
}

Notes:
- "drive" includes SSD, HDD, NVMe
- "Corsair drive" = "Corsair SSD" or "Corsair HDD"
- "Intel processor" = "Intel CPU"
- "graphics card" = "GPU"
- "memory" = "RAM"
''';
  }

  String _createSynonymsPrompt(String productName, bool isVietnamese) {
    return isVietnamese
        ? '''
Tìm các từ đồng nghĩa và biến thể của sản phẩm: "$productName"

Trả lời theo định dạng JSON:
{
  "synonyms": ["từ đồng nghĩa 1", "từ đồng nghĩa 2", "từ đồng nghĩa 3"]
}

Ví dụ:
- "Corsair drive" -> ["Corsair SSD", "Corsair HDD", "Corsair storage"]
- "Intel processor" -> ["Intel CPU", "Intel chip", "Intel processor"]
- "RTX 4090" -> ["NVIDIA RTX 4090", "RTX 4090 GPU", "RTX 4090 graphics card"]
'''
        : '''
Find synonyms and variations for the product: "$productName"

Respond in JSON format:
{
  "synonyms": ["synonym1", "synonym2", "synonym3"]
}

Examples:
- "Corsair drive" -> ["Corsair SSD", "Corsair HDD", "Corsair storage"]
- "Intel processor" -> ["Intel CPU", "Intel chip", "Intel processor"]
- "RTX 4090" -> ["NVIDIA RTX 4090", "RTX 4090 GPU", "RTX 4090 graphics card"]
''';
  }

  String _createMappingPrompt(String colloquialTerm, bool isVietnamese) {
    return isVietnamese
        ? '''
Chuyển đổi thuật ngữ thông dụng thành tên kỹ thuật chính xác.

Thuật ngữ: "$colloquialTerm"

Trả lời theo định dạng JSON:
{
  "technical_name": "tên kỹ thuật chính xác",
  "category": "cpu|gpu|ram|psu|drive|mainboard"
}

Ví dụ:
- "ổ cứng" -> {"technical_name": "HDD", "category": "drive"}
- "bộ nhớ" -> {"technical_name": "RAM", "category": "ram"}
- "card đồ họa" -> {"technical_name": "GPU", "category": "gpu"}
'''
        : '''
Convert colloquial terms to accurate technical names.

Term: "$colloquialTerm"

Respond in JSON format:
{
  "technical_name": "accurate technical name",
  "category": "cpu|gpu|ram|psu|drive|mainboard"
}

Examples:
- "hard drive" -> {"technical_name": "HDD", "category": "drive"}
- "memory" -> {"technical_name": "RAM", "category": "ram"}
- "graphics card" -> {"technical_name": "GPU", "category": "gpu"}
''';
  }

  String _createFeatureExtractionPrompt(
      String userDescription, bool isVietnamese) {
    return isVietnamese
        ? '''
Trích xuất các tính năng sản phẩm từ mô tả của người dùng.

Mô tả: "$userDescription"

Trả lời theo định dạng JSON:
{
  "features": {
    "capacity": "dung lượng",
    "speed": "tốc độ",
    "brand": "thương hiệu",
    "model": "model",
    "type": "loại sản phẩm"
  }
}
'''
        : '''
Extract product features from user description.

Description: "$userDescription"

Respond in JSON format:
{
  "features": {
    "capacity": "capacity value",
    "speed": "speed value",
    "brand": "brand name",
    "model": "model name",
    "type": "product type"
  }
}
''';
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
                  'NLP Service: Using fallback model: $model (Attempt ${retryCount + 1}/$modelMaxRetries)');
            } else {
              print(
                  'NLP Service: Calling Gemini API with $model... (Attempt ${retryCount + 1}/$modelMaxRetries)');
            }
          }

          final response = await http.post(
            Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey'),
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
                'temperature': 0.3,
                'topK': 40,
                'topP': 0.95,
              }
            }),
          );

          if (kDebugMode) {
            print(
                'NLP Service: Gemini API response status: ${response.statusCode}');
          }

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            final candidates = responseData['candidates'] as List;
            if (candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              final parts = content['parts'] as List;
              if (parts.isNotEmpty) {
                if (useFallback && kDebugMode) {
                  print(
                      'NLP Service: Successfully used fallback model: $model');
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
                    'NLP Service: Model 2.5-flash is overloaded after ${retryCount + 1} attempt(s), switching to 2.5-flash-lite fallback...');
              }
              useFallback = true;
              break; // Break retry loop and try next model
            }

            // If fallback also fails, retry
            retryCount++;
            if (retryCount < modelMaxRetries) {
              if (kDebugMode) {
                print(
                    'NLP Service: Model overloaded, retrying in ${retryCount * 2} seconds...');
              }
              await Future.delayed(Duration(seconds: retryCount * 2));
              continue;
            }
          } else {
            // For other errors, try next model if available
            if (model == 'gemini-2.5-flash' && !useFallback) {
              if (kDebugMode) {
                print(
                    'NLP Service: Model 2.5-flash failed with status ${response.statusCode} after ${retryCount + 1} attempt(s), switching to 2.5-flash-lite fallback...');
              }
              useFallback = true;
              break; // Break retry loop and try next model
            }
            throw Exception(
                'API call failed with status code: ${response.statusCode}, body: ${response.body}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('NLP Service: Error calling Gemini API with $model: $e');
          }

          // If 2.5-flash fails, try fallback
          if (model == 'gemini-2.5-flash' && !useFallback) {
            if (kDebugMode) {
              print(
                  'NLP Service: Switching to 2.5-flash-lite fallback due to error after ${retryCount + 1} attempt(s)...');
            }
            useFallback = true;
            break; // Break retry loop and try next model
          }

          retryCount++;
          if (retryCount < modelMaxRetries) {
            if (kDebugMode) {
              print('NLP Service: Retrying in ${retryCount * 2} seconds...');
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

  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      // Extract JSON from response (remove any markdown formatting)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing analysis response: $e');
      }
    }
    return _getFallbackAnalysis('');
  }

  List<String> _parseSynonymsResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final synonyms = data['synonyms'] as List?;
        if (synonyms != null) {
          return synonyms.cast<String>();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing synonyms response: $e');
      }
    }
    return [];
  }

  String? _parseMappingResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        return data['technical_name'] as String?;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing mapping response: $e');
      }
    }
    return null;
  }

  Map<String, dynamic> _parseFeatureResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        return data['features'] as Map<String, dynamic>? ?? {};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing feature response: $e');
      }
    }
    return {};
  }

  String _createProductNameExtractionPrompt(String text, bool isVietnamese) {
    return isVietnamese
        ? '''
Bạn là chuyên gia về phần cứng máy tính. Hãy trích xuất tên sản phẩm chính xác từ đoạn văn bản sau.

Văn bản: "$text"

Hãy trả lời CHỈ với tên sản phẩm, không có giải thích thêm. Nếu không tìm thấy sản phẩm, trả lời "null".

Ví dụ:
- "thêm cpu i7 hoặc core ultra 7 mới nhất vào giỏ hàng" -> "CPU Intel Core Ultra 7"
- "add RTX 4090 to cart" -> "RTX 4090"
- "mua RAM DDR5" -> "DDR5 RAM"
- "thêm nó vào giỏ hàng" -> "null" (không có tên sản phẩm cụ thể)

Tên sản phẩm:
'''
        : '''
You are a computer hardware expert. Extract the exact product name from the following text.

Text: "$text"

Respond with ONLY the product name, no additional explanation. If no product is found, respond with "null".

Examples:
- "add cpu i7 or core ultra 7 latest to cart" -> "CPU Intel Core Ultra 7"
- "add RTX 4090 to cart" -> "RTX 4090"
- "buy DDR5 RAM" -> "DDR5 RAM"
- "add it to cart" -> "null" (no specific product name)

Product name:
''';
  }

  String? _parseProductNameResponse(String response) {
    try {
      final trimmed = response.trim();

      // Check if response is "null" or empty
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'null' ||
          trimmed.toLowerCase() == 'none' ||
          trimmed.toLowerCase() == 'không tìm thấy') {
        return null;
      }

      // Remove any quotes at start or end
      var productName = trimmed;
      productName = productName.replaceAll(RegExp(r'^"'), '');
      productName = productName.replaceAll(RegExp(r'"$'), '');
      productName = productName.replaceAll(RegExp(r"^'"), '');
      productName = productName.replaceAll(RegExp(r"'$"), '');

      // Remove common prefixes/suffixes that might be added
      productName = productName
          .replaceAll(
              RegExp(r'^(Product name|Tên sản phẩm|Product|Sản phẩm):\s*',
                  caseSensitive: false),
              '')
          .trim();

      if (productName.isEmpty || productName.length < 2) {
        return null;
      }

      return productName;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing product name response: $e');
      }
      return null;
    }
  }

  String _createMultipleProductNamesExtractionPrompt(
      String text, bool isVietnamese) {
    return isVietnamese
        ? '''
Bạn là chuyên gia về phần cứng máy tính. Hãy trích xuất TẤT CẢ các tên sản phẩm và thương hiệu được đề cập trong đoạn văn bản sau.

Văn bản: "$text"

Hãy trả lời theo định dạng JSON sau:
{
  "product_names": ["tên sản phẩm 1", "tên sản phẩm 2", ...],
  "brands": ["thương hiệu 1", "thương hiệu 2", ...]
}

Lưu ý:
- Chỉ trích xuất các sản phẩm phần cứng máy tính thực sự được đề cập (CPU, GPU, RAM, SSD, HDD, PSU, Mainboard)
- Trích xuất thương hiệu được đề cập rõ ràng (Intel, AMD, NVIDIA, Samsung, Kingston, Corsair, ASUS, MSI, Gigabyte)
- Nếu không có sản phẩm nào, trả về mảng rỗng: {"product_names": [], "brands": []}
- Tên sản phẩm phải chính xác và đầy đủ (ví dụ: "Intel Core i7-12700K" thay vì chỉ "i7")
- Tối đa 3 sản phẩm và 3 thương hiệu

Ví dụ:
- "The Intel Core i7-12700K is a 12th Gen processor" -> {"product_names": ["Intel Core i7-12700K"], "brands": ["Intel"]}
- "Bạn có thể tham khảo các mẫu CPU Intel sau: CPU Intel Core i7 12700K" -> {"product_names": ["CPU Intel Core i7 12700K"], "brands": ["Intel"]}
- "I recommend RTX 4090 or RTX 4080" -> {"product_names": ["RTX 4090", "RTX 4080"], "brands": ["NVIDIA"]}
- "This is a great CPU" -> {"product_names": [], "brands": []} (không có tên cụ thể)
'''
        : '''
You are a computer hardware expert. Extract ALL product names and brands mentioned in the following text.

Text: "$text"

Respond in the following JSON format:
{
  "product_names": ["product name 1", "product name 2", ...],
  "brands": ["brand 1", "brand 2", ...]
}

Notes:
- Only extract actual computer hardware products mentioned (CPU, GPU, RAM, SSD, HDD, PSU, Mainboard)
- Extract brands that are explicitly mentioned (Intel, AMD, NVIDIA, Samsung, Kingston, Corsair, ASUS, MSI, Gigabyte)
- If no products are found, return empty array: {"product_names": [], "brands": []}
- Product names must be accurate and complete (e.g., "Intel Core i7-12700K" instead of just "i7")
- Maximum 3 products and 3 brands

Examples:
- "The Intel Core i7-12700K is a 12th Gen processor" -> {"product_names": ["Intel Core i7-12700K"], "brands": ["Intel"]}
- "You can refer to the following Intel CPU models: CPU Intel Core i7 12700K" -> {"product_names": ["CPU Intel Core i7 12700K"], "brands": ["Intel"]}
- "I recommend RTX 4090 or RTX 4080" -> {"product_names": ["RTX 4090", "RTX 4080"], "brands": ["NVIDIA"]}
- "This is a great CPU" -> {"product_names": [], "brands": []} (no specific name)
''';
  }

  List<String> _parseMultipleProductNamesResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final productNames = data['product_names'] as List?;
        if (productNames != null) {
          return productNames
              .cast<String>()
              .where((name) => name.isNotEmpty && name.length > 2)
              .take(3)
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing multiple product names response: $e');
      }
    }
    return [];
  }

  /// Extract product names and brands from text using NLP
  /// Returns a map with 'product_names' and 'brands' lists
  Future<Map<String, List<String>>> extractProductNamesAndBrands(
      String text, bool isVietnamese) async {
    try {
      final prompt =
          _createMultipleProductNamesExtractionPrompt(text, isVietnamese);
      final response = await _callGeminiAPI(prompt);

      if (kDebugMode) {
        print('NLP Product Names and Brands Extraction Response: $response');
      }

      return _parseProductNamesAndBrandsResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in NLP product names and brands extraction: $e');
      }
      return {'product_names': [], 'brands': []};
    }
  }

  Map<String, List<String>> _parseProductNamesAndBrandsResponse(
      String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        final productNames = (data['product_names'] as List?)
                ?.cast<String>()
                .where((name) => name.isNotEmpty && name.length > 2)
                .take(3)
                .toList() ??
            [];

        final brands = (data['brands'] as List?)
                ?.cast<String>()
                .where((brand) => brand.isNotEmpty)
                .take(3)
                .toList() ??
            [];

        return {
          'product_names': productNames,
          'brands': brands,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing product names and brands response: $e');
      }
    }
    return {'product_names': [], 'brands': []};
  }

  Map<String, dynamic> _getFallbackAnalysis(String userQuery) {
    return {
      'product_name': userQuery,
      'category': 'unknown',
      'brand': '',
      'features': [],
      'synonyms': [userQuery],
      'intent': 'search',
      'confidence': 0.5
    };
  }
}
