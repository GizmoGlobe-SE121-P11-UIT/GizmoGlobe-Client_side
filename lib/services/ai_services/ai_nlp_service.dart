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
  static const String _model = 'gemini-2.0-flash';

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

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey'),
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
            'maxOutputTokens': 1024,
          }
        }),
      );

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
      }

      throw Exception(
          'Failed to get response from Gemini API: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error calling Gemini API: $e');
    }
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
