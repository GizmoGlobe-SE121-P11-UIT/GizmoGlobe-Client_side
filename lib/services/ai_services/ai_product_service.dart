import 'package:cloud_firestore/cloud_firestore.dart';
import '../../functions/helper.dart';

class AIProductService {
  final FirebaseFirestore _firestore;

  // Category mapping constants
  // ignore: constant_identifier_names
  static const Map<String, String> CATEGORY_MAPPING = {
    'cpu': 'cpu',
    'gpu': 'gpu',
    'ram': 'ram',
    'psu': 'psu',
    'drive': 'drive',
    'mainboard': 'mainboard'
  };

  AIProductService(this._firestore);

  /// Check Firebase connection
  Future<bool> checkFirebaseConnection() async {
    try {
      await _firestore.collection('products').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Search products with NLP-enhanced understanding
  Future<QuerySnapshot?> searchProductsWithNLP({
    required String productName,
    required String category,
    required List<String> synonyms,
    required bool isVietnamese,
  }) async {
    try {
      // For now, use the traditional search with the best NLP result
      // This can be enhanced later with more sophisticated query building

      // Try searching with the exact product name first
      var snapshot = await searchProducts(keyword: productName);

      // If no results, try with category
      if (snapshot.docs.isEmpty &&
          category.isNotEmpty &&
          category != 'unknown') {
        snapshot = await searchProducts(category: category);
      }

      // If still no results, try with synonyms
      if (snapshot.docs.isEmpty && synonyms.isNotEmpty) {
        for (final synonym in synonyms.take(3)) {
          final synonymSnapshot = await searchProducts(keyword: synonym);
          if (synonymSnapshot.docs.isNotEmpty) {
            snapshot = synonymSnapshot;
            break;
          }
        }
      }

      return snapshot;
    } catch (e) {
      return null;
    }
  }

  /// Search products with category and keyword filters
  Future<QuerySnapshot> searchProducts(
      {String? category, String? keyword}) async {
    try {
      final CollectionReference<Map<String, dynamic>> productsRef =
          _firestore.collection('products');

      // First query: Filter by active status
      var query = productsRef.where('status', isEqualTo: 'active');

      // Add category filter if specified
      if (category != null) {
        final standardCategory =
            CATEGORY_MAPPING[category.toLowerCase()] ?? category.toLowerCase();
        query = query.where('category', isEqualTo: standardCategory);
      }

      // Execute the query first, then filter by keyword in memory
      // This is more reliable than trying to match normalized names in Firestore
      final result = await query.get();

      // If no keyword, return all results
      if (keyword == null || keyword.trim().isEmpty) {
        return result;
      }

      // Filter docs in memory using partial matching
      final matchingDocs = result.docs.where((doc) {
        final data = doc.data();
        final productName = (data['productName'] as String?) ?? '';
        final productNameLower = productName.toLowerCase();
        final keywordLower = keyword.toLowerCase().trim();

        // Check 1: Direct substring match (case insensitive)
        if (productNameLower.contains(keywordLower)) return true;

        // Check 2: Handle CPU model patterns specifically (e.g., "i5 12400" -> "i5-12400" or "i5 12400")
        // Also handle variations like "i512400", "i5-12400", "core i5 12400"
        final cpuPattern =
            RegExp(r'(i[3579])\s*-?\s*(\d{4,5}[a-z]*)', caseSensitive: false);
        final keywordCpuMatch = cpuPattern.firstMatch(keywordLower);
        if (keywordCpuMatch != null) {
          final series = keywordCpuMatch.group(1)!.toLowerCase(); // e.g., "i5"
          final model = keywordCpuMatch.group(2)!; // e.g., "12400" or "12400f"
          // Check if product name contains both the series and model number
          if (productNameLower.contains(series) &&
              productNameLower.contains(model)) {
            return true;
          }
        }

        // Check 3: Handle Ryzen patterns (e.g., "ryzen 5 5600", "r5 5600", "5600x")
        final ryzenPattern =
            RegExp(r'(?:ryzen|r)\s*([3579])\s*(\d{4}[a-z]*)', caseSensitive: false);
        final keywordRyzenMatch = ryzenPattern.firstMatch(keywordLower);
        if (keywordRyzenMatch != null) {
          final series = keywordRyzenMatch.group(1)!; // e.g., "5"
          final model = keywordRyzenMatch.group(2)!; // e.g., "5600" or "5600x"
          if (productNameLower.contains('ryzen') &&
              productNameLower.contains(series) &&
              productNameLower.contains(model)) {
            return true;
          }
        }

        // Check 4: Split keyword into individual words and check all are present
        final keywordWords = keywordLower
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty && w.length >= 2)
            .toList();
        if (keywordWords.isNotEmpty) {
          final allWordsMatch = keywordWords.every((word) {
            // Remove non-alphanumeric chars for better matching
            final cleanWord = word.replaceAll(RegExp(r'[^a-z0-9]'), '');
            final cleanProductName =
                productNameLower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
            // Check for word boundary or substring match
            return cleanProductName.contains(cleanWord);
          });
          if (allWordsMatch) return true;
        }

        // Check 5: Use normalized matching as fallback
        final normalizedKeyword = normalizeProductName(keyword);
        final normalizedProductName = normalizeProductName(productName);
        if (normalizedProductName.contains(normalizedKeyword)) return true;

        // Check 6: Similarity score for fuzzy matching (lowered threshold)
        final similarity =
            calculateSimilarity(normalizedKeyword, normalizedProductName);
        if (similarity > 0.4) return true;

        return false;
      }).toList();

      // Return a filtered "snapshot" by creating a mock query result
      // Since we can't create a new QuerySnapshot, we'll use a workaround
      // by re-querying with document IDs if we have matches
      if (matchingDocs.isEmpty) {
        // Return empty result - just return the original with no matches
        return await productsRef
            .where('status', isEqualTo: '__NO_MATCH__')
            .get();
      }

      // If all docs match, return original result
      if (matchingDocs.length == result.docs.length) {
        return result;
      }

      // Get matching document IDs and re-query
      final matchingIds = matchingDocs.map((doc) => doc.id).toList();

      // Firestore 'whereIn' has a limit of 30 items, so we may need to batch
      if (matchingIds.length <= 30) {
        return await productsRef
            .where(FieldPath.documentId, whereIn: matchingIds)
            .get();
      } else {
        // For more than 30 matches, just return the original result
        // The caller should handle filtering if needed
        return result;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Find product by name
  Future<Map<String, dynamic>?> findProductByName(String productName) async {
    try {
      // Normalize product name for search
      final normalizedName = normalizeProductName(productName);
      final lowerProductName = productName.toLowerCase().trim();

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
          'normalizedName': normalizeProductName(data['productName'] ?? ''),
        };
      }).toList();

      // Find best match
      Map<String, dynamic>? bestMatch;
      double bestScore = 0.0;

      for (final product in products) {
        final productNormalizedName = product['normalizedName'] as String;
        final originalName = (product['productName'] as String?) ?? '';
        final originalNameLower = originalName.toLowerCase();

        double score = 0.0;

        // Priority 1: Direct substring match (highest priority)
        if (originalNameLower.contains(lowerProductName)) {
          score = 0.95;
        }
        // Priority 2: Check for CPU model pattern match (e.g., "i5 12400" in "CPU Intel Core i5 12400 ...")
        else if (_matchesCpuPattern(lowerProductName, originalNameLower)) {
          score = 0.9;
        }
        // Priority 3: Check for GPU model pattern match (e.g., "rtx 4060" in "GeForce RTX 4060 ...")
        else if (_matchesGpuPattern(lowerProductName, originalNameLower)) {
          score = 0.9;
        }
        // Priority 4: All search words present in product name
        else if (_allWordsPresent(lowerProductName, originalNameLower)) {
          score = 0.85;
        }
        // Priority 5: Calculate similarity scores
        else {
          final normalizedScore =
              calculateSimilarity(normalizedName, productNormalizedName);
          final originalScore =
              calculateSimilarity(lowerProductName, originalNameLower);
          score = normalizedScore > originalScore ? normalizedScore : originalScore;
        }

        if (score > bestScore && score > 0.15) {
          // Lowered threshold for better matching
          bestScore = score;
          bestMatch = product;
        }
      }

      return bestMatch;
    } catch (e) {
      return null;
    }
  }

  /// Check if search query matches CPU pattern in product name
  bool _matchesCpuPattern(String query, String productName) {
    // Intel patterns: i3, i5, i7, i9 with model numbers
    final intelPattern =
        RegExp(r'(i[3579])\s*-?\s*(\d{4,5}[a-z]*)', caseSensitive: false);
    final queryMatch = intelPattern.firstMatch(query);
    if (queryMatch != null) {
      final series = queryMatch.group(1)!.toLowerCase();
      final model = queryMatch.group(2)!.toLowerCase();
      return productName.contains(series) && productName.contains(model);
    }

    // AMD Ryzen patterns
    final ryzenPattern =
        RegExp(r'(?:ryzen|r)\s*([3579])\s*(\d{4}[a-z]*)', caseSensitive: false);
    final ryzenMatch = ryzenPattern.firstMatch(query);
    if (ryzenMatch != null) {
      final series = ryzenMatch.group(1)!;
      final model = ryzenMatch.group(2)!.toLowerCase();
      return productName.contains('ryzen') &&
          productName.contains(series) &&
          productName.contains(model);
    }

    // Intel Core Ultra patterns
    final ultraPattern =
        RegExp(r'(?:core\s+)?ultra\s*([579])\s*(\d{3}[a-z]*)', caseSensitive: false);
    final ultraMatch = ultraPattern.firstMatch(query);
    if (ultraMatch != null) {
      final series = ultraMatch.group(1)!;
      final model = ultraMatch.group(2)!.toLowerCase();
      return productName.contains('ultra') &&
          productName.contains(series) &&
          productName.contains(model);
    }

    return false;
  }

  /// Check if search query matches GPU pattern in product name
  bool _matchesGpuPattern(String query, String productName) {
    // NVIDIA RTX/GTX patterns
    final nvidiaPattern =
        RegExp(r'(rtx|gtx)\s*(\d{3,4})\s*(ti|super)?', caseSensitive: false);
    final nvidiaMatch = nvidiaPattern.firstMatch(query);
    if (nvidiaMatch != null) {
      final series = nvidiaMatch.group(1)!.toLowerCase();
      final model = nvidiaMatch.group(2)!;
      final suffix = nvidiaMatch.group(3)?.toLowerCase() ?? '';
      final hasMatch = productName.contains(series) && productName.contains(model);
      if (suffix.isNotEmpty) {
        return hasMatch && productName.contains(suffix);
      }
      return hasMatch;
    }

    // AMD RX patterns
    final amdPattern =
        RegExp(r'rx\s*(\d{3,4})\s*(xt)?', caseSensitive: false);
    final amdMatch = amdPattern.firstMatch(query);
    if (amdMatch != null) {
      final model = amdMatch.group(1)!;
      final suffix = amdMatch.group(2)?.toLowerCase() ?? '';
      final hasMatch = productName.contains('rx') && productName.contains(model);
      if (suffix.isNotEmpty) {
        return hasMatch && productName.contains(suffix);
      }
      return hasMatch;
    }

    return false;
  }

  /// Check if all words from query are present in product name
  bool _allWordsPresent(String query, String productName) {
    final queryWords = query
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w.length >= 2)
        .toList();

    if (queryWords.isEmpty) return false;

    final cleanProductName = productName.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    return queryWords.every((word) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-z0-9]'), '');
      return cleanProductName.contains(cleanWord);
    });
  }

  /// Get product suggestions for similar products
  Future<List<Map<String, dynamic>>> getProductSuggestions(
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
          'normalizedName': normalizeProductName(data['productName'] ?? ''),
        };
      }).toList();

      // Calculate similarity scores and sort by score
      final scoredProducts = products.map((product) {
        final productNormalizedName = product['normalizedName'] as String;
        final originalName = product['productName'] as String;

        final normalizedScore =
            calculateSimilarity(productName, productNormalizedName);
        final originalScore = calculateSimilarity(
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
      return [];
    }
  }

  /// Get product not found response
  Future<String> getProductNotFoundResponse(
      String productName, bool isVietnamese) async {
    // Try to suggest similar products
    final suggestions = await getProductSuggestions(productName);
    final suggestionText = suggestions.isNotEmpty
        ? '\n\nSản phẩm tương tự:\n${suggestions.take(3).map((p) => '- ${p['productName']}').join('\n')}'
        : '';

    return isVietnamese
        ? 'Xin lỗi, không tìm thấy sản phẩm "$productName". Vui lòng kiểm tra lại tên sản phẩm hoặc thử tìm kiếm sản phẩm trước.$suggestionText'
        : 'Sorry, product "$productName" not found. Please check the product name or try searching for products first.$suggestionText';
  }

  /// Format products information for AI prompts
  String formatProductsInfo(
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
            '\n   💰 Price: ${formatPriceWithDiscount(data['sellingPrice'], data['discount'])}');

        // Technical specifications by category
        buffer.writeln('\n   📝 Technical Specifications:');
        switch (category) {
          case 'gpu':
            final gpuAttrs = data['attributes'] as Map<String, dynamic>?;
            buffer.writeln(
                '      • Series: ${data['series']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Version: ${gpuAttrs?['version']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Memory (VRAM): ${formatValue(data['capacity'], 'capacity')}');
            buffer.writeln(
                '      • Bus Width: ${formatValue(data['bus'], 'bus')}');
            buffer.writeln(
                '      • Boost Clock: ${formatValue(data['clockSpeed'], 'clock')}');
            final gpuTdp = gpuAttrs?['tdp'];
            if (gpuTdp != null) {
              buffer.writeln('      • TDP: ${gpuTdp}W');
            }
            break;
          case 'cpu':
            final cpuAttrs = data['attributes'] as Map<String, dynamic>?;
            buffer.writeln(
                '      • Series: ${data['family']?.toString() ?? 'N/A'}');
            final cpuSocket = cpuAttrs?['socket']?.toString();
            if (cpuSocket != null) {
              buffer.writeln('      • Socket: ${cpuSocket.toUpperCase()}');
            }
            buffer.writeln(
                '      • Cores: ${data['core']?.toString() ?? 'N/A'} cores');
            buffer.writeln(
                '      • Threads: ${data['thread']?.toString() ?? 'N/A'} threads');
            final baseClock = cpuAttrs?['baseClock'];
            if (baseClock != null) {
              buffer.writeln(
                  '      • Base Clock: ${formatValue(baseClock, 'clock')}');
            }
            final turboClock = data['clockSpeed'] ?? cpuAttrs?['turboClock'];
            if (turboClock != null) {
              buffer.writeln(
                  '      • Turbo Clock: ${formatValue(turboClock, 'clock')}');
            }
            final cpuTdp = cpuAttrs?['tdp'];
            if (cpuTdp != null) {
              buffer.writeln('      • TDP: ${cpuTdp}W');
            }
            break;
          case 'ram':
            final ramAttrs = data['attributes'] as Map<String, dynamic>?;
            buffer.writeln(
                '      • Type: ${data['ramType']?.toString() ?? ramAttrs?['ramType']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Capacity: ${formatValue(data['capacity'], 'capacity')}');
            final capacityPerStick = ramAttrs?['capacityPerStickGb'];
            final kitStickCount = ramAttrs?['kitStickCount'];
            if (capacityPerStick != null && kitStickCount != null) {
              buffer.writeln(
                  '      • Kit: ${kitStickCount}x ${capacityPerStick}GB sticks');
            }
            buffer
                .writeln('      • Speed: ${formatValue(data['bus'], 'speed')}');
            final clLatency = ramAttrs?['clLatency'];
            if (clLatency != null) {
              buffer.writeln('      • CL Latency: CL$clLatency');
            }
            break;
          case 'psu':
            final psuAttrs = data['attributes'] as Map<String, dynamic>?;
            buffer.writeln(
                '      • Wattage: ${data['wattage'] != null ? '${data['wattage']}W' : psuAttrs?['maxWattage'] != null ? '${psuAttrs!['maxWattage']}W' : 'N/A'}');
            buffer.writeln(
                '      • Efficiency: ${data['efficiency']?.toString() ?? psuAttrs?['efficiency']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Modular: ${formatValue(data['modular'] ?? psuAttrs?['modularity'], 'modular')}');
            break;
          case 'drive':
            final driveAttrs = data['attributes'] as Map<String, dynamic>?;
            buffer.writeln(
                '      • Type: ${data['type']?.toString() ?? driveAttrs?['driveType']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Capacity: ${formatValue(data['capacity'], 'capacity')}');
            final driveGen = driveAttrs?['gen'];
            if (driveGen != null) {
              buffer.writeln('      • Generation: $driveGen');
            }
            final interfaceType = driveAttrs?['interfaceType'];
            if (interfaceType != null) {
              buffer.writeln('      • Interface: $interfaceType');
            }
            final formFactor = driveAttrs?['formFactor'];
            if (formFactor != null) {
              buffer.writeln('      • Form Factor: $formFactor');
            }
            final speed = driveAttrs?['speed'];
            if (speed != null) {
              buffer.writeln('      • Speed: $speed');
            }
            break;
          case 'mainboard':
            final mbAttrs = data['attributes'] as Map<String, dynamic>?;
            final mbSocket = mbAttrs?['socket']?.toString();
            if (mbSocket != null) {
              buffer.writeln('      • Socket: ${mbSocket.toUpperCase()}');
            }
            final chipset = mbAttrs?['chipsetCode'];
            if (chipset != null) {
              buffer.writeln('      • Chipset: $chipset');
            }
            buffer.writeln(
                '      • Form Factor: ${data['formFactor']?.toString() ?? mbAttrs?['formFactor']?.toString() ?? 'N/A'}');
            buffer.writeln(
                '      • Series: ${data['series']?.toString() ?? 'N/A'}');
            final ramSpec = mbAttrs?['ramSpec'];
            if (ramSpec != null && ramSpec is Map) {
              final ramType = ramSpec['type']?.toString();
              final maxCapacity = ramSpec['maxCapacity'];
              if (ramType != null) {
                buffer.writeln(
                    '      • RAM Support: ${ramType.toUpperCase()}${maxCapacity != null ? ' (Max ${maxCapacity}GB)' : ''}');
              }
            }
            buffer.writeln(
                '      • Compatibility: ${data['compatibility']?.toString() ?? 'N/A'}');
            break;
        }

        buffer.writeln(
            '\n   🏭 Manufacturer: ${data['manufacturerID'] ?? 'N/A'}');
        buffer.writeln('   📦 ${formatValue(data['stock'], 'stock')}');

        // Add product description if available
        if (data['description'] != null) {
          buffer.writeln('\n   📄 Description: ${data['description']}');
        }
        buffer.writeln('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        productCount++;
      }
    });

    return buffer.toString();
  }

  // Private helper methods
  String normalizeProductName(String input) {
    // Remove special characters and extra spaces
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

  List<String> extractProductParts(String input) {
    final parts = <String>[];

    // Split and normalize each part of the product name
    final regex = RegExp(r'(i[3579]|ryzen\s*[3579]|[0-9]+[a-z]*|[a-z]+)',
        caseSensitive: false);
    final matches = regex.allMatches(input);

    for (var match in matches) {
      var part = match.group(0)!.toLowerCase();

      // Normalize parts
      if (part.startsWith('i')) {
        parts.add(part); // Keep i3/i5/i7/i9 as is
      } else if (part.contains('ryzen')) {
        parts.add('ryzen');
        if (part.contains(RegExp(r'[3579]'))) {
          parts.add(part.replaceAll(RegExp(r'[^3579]'), ''));
        }
      } else if (part.contains(RegExp(r'[0-9]'))) {
        parts.add(part); // Keep model numbers as is
      }
    }

    return parts;
  }

  double calculateSimilarity(String str1, String str2) {
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
        else if (areSimilarWords(word1, word2)) {
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

  bool areSimilarWords(String word1, String word2) {
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

  String formatValue(dynamic value, String type) {
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
          return Helper.toCurrencyFormat(value);
        }
        if (value is String) {
          final match = RegExp(r'\?(\d+\.?\d*)₫').firstMatch(value);
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

  String formatPriceWithDiscount(dynamic price, dynamic discount) {
    if (price == null) return 'Price not available';
    if (price is! num) return formatValue(price, 'price');

    if (discount == null || discount == 0) {
      return formatValue(price, 'price');
    }

    // Discount is stored as percentage (0-100), not multiplier (0-1)
    final discountPercent = (discount as num).toDouble();
    final finalPrice = price * (1 - discountPercent / 100);

    return '${formatValue(finalPrice, 'price')} (Original: ${formatValue(price, 'price')})';
  }
}
