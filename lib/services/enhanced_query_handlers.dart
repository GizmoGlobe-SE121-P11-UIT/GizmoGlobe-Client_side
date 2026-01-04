import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Enhanced Query Handlers for Phase 2
///
/// Handles promotion, bestseller, and build suggestion queries
class EnhancedQueryHandlers {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Handle promotion queries (e.g., "Products with >30% discount?")
  Future<Map<String, dynamic>> handlePromotionQuery(
    String userMessage,
    Map<String, dynamic> entities,
    bool isVietnamese,
  ) async {
    final threshold = entities['discount_threshold'] as int? ?? 30;
    final categoryStr = entities['category'] as String?;

    try {
      // Query Firestore for products with discount >= threshold
      var query = _firestore
          .collection('products')
          .where('discount', isGreaterThanOrEqualTo: threshold)
          .where('status', isEqualTo: 'active')
          .orderBy('discount', descending: true);

      // Firebase stores enum names in lowercase
      if (categoryStr != null) {
        // Convert category string to lowercase enum name format
        final categoryNorm = categoryStr.toLowerCase();
        query = query.where('category', isEqualTo: categoryNorm);
      }

      final snapshot = await query.limit(10).get();

      if (snapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': isVietnamese
              ? 'Hiện tại không có sản phẩm nào giảm giá từ $threshold% trở lên.'
              : 'There are currently no products with $threshold%+ discount.'
        };
      }

      return {
        'success': true,
        'products': snapshot.docs,
        'context': isVietnamese
            ? 'Sản phẩm khuyến mãi ≥$threshold%'
            : 'Products with ≥$threshold% discount',
        'userMessage': userMessage,
        'threshold': threshold,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error handling promotion query: $e');
      }
      return {
        'success': false,
        'message': isVietnamese
            ? 'Có lỗi xảy ra khi tìm kiếm sản phẩm khuyến mãi.'
            : 'An error occurred while searching for promotional products.'
      };
    }
  }

  /// Handle bestseller queries
  Future<Map<String, dynamic>> handleBestsellerQuery(
    String userMessage,
    Map<String, dynamic> entities,
    bool isVietnamese,
  ) async {
    try {
      // Extract category if specified
      final categoryEntity = entities['category'];
      final categoryStr = categoryEntity is String
          ? categoryEntity
          : (categoryEntity is List && categoryEntity.isNotEmpty
              ? categoryEntity.first.toString()
              : null);

      // Build Firestore query
      var query = _firestore
          .collection('products')
          .where('status', isEqualTo: 'active');

      // Filter by category if specified
      if (categoryStr != null) {
        query = query.where('category', isEqualTo: categoryStr.toLowerCase());
      }

      // Get all documents and sort by sales in memory
      // (Firestore doesn't support orderBy on fields that might not exist)
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': isVietnamese
              ? 'Không tìm thấy sản phẩm${categoryStr != null ? " $categoryStr" : ""}.'
              : 'No products found${categoryStr != null ? " in $categoryStr category" : ""}.'
        };
      }

      // Sort by sales field (descending - highest sales first)
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final salesA = (a.data()['sales'] as num?)?.toInt() ?? 0;
          final salesB = (b.data()['sales'] as num?)?.toInt() ?? 0;
          return salesB.compareTo(salesA); // Descending order
        });

      // Take top 5
      final topDocs = sortedDocs.take(5).toList();

      if (kDebugMode) {
        print('Found ${topDocs.length} bestselling products');
        for (var doc in topDocs) {
          final data = doc.data();
          final sales = data['sales'] ?? 0;
          print('  - ${data['productName']}: $sales sales');
        }
      }

      return {
        'success': true,
        'products': topDocs,
        'context': isVietnamese
            ? 'Top 5 sản phẩm bán chạy${categoryStr != null ? " - ${categoryStr.toUpperCase()}" : ""}'
            : 'Top 5 bestselling products${categoryStr != null ? " - ${categoryStr.toUpperCase()}" : ""}',
        'userMessage': userMessage,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error handling bestseller query: $e');
      }
      return {
        'success': false,
        'message': isVietnamese
            ? 'Có lỗi xảy ra khi tìm sản phẩm bán chạy.'
            : 'An error occurred while finding bestselling products.'
      };
    }
  }

  /// Handle build suggestion queries
  Future<Map<String, dynamic>> handleBuildSuggestion(
    String userMessage,
    Map<String, dynamic> entities,
    bool isVietnamese,
  ) async {
    final budget = entities['budget'] as int? ?? 20; // Default 20 triệu
    final purpose = entities['purpose'] as String? ?? 'gaming';

    // Calculate budget allocation based on purpose
    _calculateBudgetAllocation(purpose, budget);

    // Get products for each category within budget - SEQUENTIALLY with compatibility check

    // Socket-to-RAM mapping (expanded for better coverage)
    final socketToRamType = {
      // AMD sockets
      'am4': ['ddr4'],
      'am5': ['ddr5'],
      'am3+': ['ddr3'],
      'am3': ['ddr3'],
      // Intel sockets
      'lga1851': ['ddr5'], // Latest Intel
      'lga1700': ['ddr4', 'ddr5'], // 12th-14th gen
      'lga1200': ['ddr4'], // 10th-11th gen
      'lga1151': ['ddr4'], // 6th-9th gen
      'lga1150': ['ddr3'],
      'lga2066': ['ddr4'],
      'lga2011': ['ddr4'],
    };

    try {
      // Check if user specified specific high-end components without budget
      final productNames = entities['product_names'] as List?;
      final category = entities['category'] as String?;

      if (productNames != null && productNames.isNotEmpty && budget == 20) {
        // User mentioned specific products but no budget - ask for budget
        final componentsMentioned = productNames.join(', ');

        // Check if it's high-end component (GPU, Threadripper, i9, Ryzen 9, etc.)
        final isHighEnd = productNames.any((name) {
          final nameLower = name.toString().toLowerCase();
          return nameLower.contains('5090') ||
              nameLower.contains('4090') ||
              nameLower.contains('4080') ||
              nameLower.contains('threadripper') ||
              nameLower.contains('i9') ||
              nameLower.contains('ryzen 9') ||
              nameLower.contains('ryzen 7') ||
              category == 'gpu';
        });

        if (isHighEnd) {
          return {
            'success': false,
            'message': isVietnamese
                ? 'Tôi hiểu bạn muốn xây dựng cấu hình với $componentsMentioned. Tuy nhiên, để đề xuất cấu hình chính xác nhất, bạn có thể cho tôi biết:\n\n'
                    '💰 **Ngân sách của bạn là bao nhiêu?**\n'
                    '(Ví dụ: "30 triệu", "50M", "100 triệu VND")\n\n'
                    'Điều này giúp tôi lựa chọn các linh kiện khác phù hợp với $componentsMentioned bạn mong muốn.'
                : 'I understand you want to build a PC with $componentsMentioned. However, to provide the most accurate build suggestion, could you please let me know:\n\n'
                    '💰 **What is your budget?**\n'
                    '(Example: "30 million", "50M", "100 million VND")\n\n'
                    'This helps me select other components that match your desired $componentsMentioned.'
          };
        }
      }

      // STEP 1: Get CPU candidates
      List<QueryDocumentSnapshot> cpuCandidates;

      // Check if user specified a specific CPU name
      final specificCpuName = productNames?.firstWhere(
        (name) {
          final nameLower = name.toString().toLowerCase();
          return nameLower.contains('threadripper') ||
              nameLower.contains('ryzen') ||
              nameLower.contains('i3') ||
              nameLower.contains('i5') ||
              nameLower.contains('i7') ||
              nameLower.contains('i9') ||
              nameLower.contains('core ultra') ||
              category == 'cpu';
        },
        orElse: () => null,
      );

      if (specificCpuName != null) {
        // User specified a CPU - search for it specifically
        if (kDebugMode) {
          print(
              'User specified CPU: $specificCpuName, searching for exact match...');
        }

        final cpuQuery = await _firestore
            .collection('products')
            .where('category', isEqualTo: 'cpu')
            .where('status', isEqualTo: 'active')
            .get();

        // Filter by name similarity
        cpuCandidates = cpuQuery.docs.where((doc) {
          final data = doc.data();
          final productName =
              (data['productName'] as String?)?.toLowerCase() ?? '';
          final searchName = specificCpuName.toString().toLowerCase();

          // Check if product name contains the search terms
          return productName.contains(searchName) ||
              searchName.split(' ').every((term) => productName.contains(term));
        }).toList();

        if (cpuCandidates.isEmpty) {
          return {
            'success': false,
            'message': isVietnamese
                ? 'Không tìm thấy CPU "$specificCpuName" trong kho. Vui lòng kiểm tra lại tên sản phẩm hoặc thử tìm kiếm CPU khác.'
                : 'Could not find CPU "$specificCpuName" in stock. Please check the product name or try searching for another CPU.'
          };
        }

        if (kDebugMode) {
          print(
              'Found ${cpuCandidates.length} matching CPUs for "$specificCpuName"');
        }
      } else {
        // No specific CPU - use varied price strategy
        cpuCandidates =
            await _getProductsByCategory('cpu', topN: 20, sortOrder: 'varied');
      }

      if (cpuCandidates.isEmpty) {
        return {
          'success': false,
          'message': isVietnamese
              ? 'Không tìm thấy CPU phù hợp.'
              : 'Could not find suitable CPU.'
        };
      }

      if (kDebugMode) {
        print(
            'Found ${cpuCandidates.length} CPU candidates, finding build closest to budget ${budget}M...');
      }

      // Collect all valid builds, then pick the one closest to budget
      final validBuilds = <Map<String, dynamic>>[];
      final budgetInThousands = budget * 1000;

      // Purpose-based budget allocation (industry standard)
      Map<String, double> allocation;
      switch (purpose.toLowerCase()) {
        case 'office':
        case 'học tập':
        case 'văn phòng':
          allocation = {
            'cpu': 0.375,
            'gpu': 0.0,
            'ram': 0.175,
            'mainboard': 0.125,
            'drive': 0.175,
            'psu': 0.065
          };
          break;
        case 'gaming':
        case 'game':
        case 'chơi game':
          allocation = {
            'cpu': 0.225,
            'gpu': 0.45,
            'ram': 0.125,
            'mainboard': 0.10,
            'drive': 0.09,
            'psu': 0.085
          };
          break;
        case 'design':
        case 'đồ họa':
        case 'kỹ thuật':
        case 'ai':
          allocation = {
            'cpu': 0.30,
            'gpu': 0.375,
            'ram': 0.20,
            'mainboard': 0.125,
            'drive': 0.125,
            'psu': 0.10
          };
          break;
        default:
          allocation = {
            'cpu': 0.30,
            'gpu': 0.30,
            'ram': 0.15,
            'mainboard': 0.10,
            'drive': 0.10,
            'psu': 0.05
          };
      }

      if (kDebugMode) {
        print(
            'Purpose "$purpose": CPU ${(allocation['cpu']! * 100).toInt()}%, GPU ${(allocation['gpu']! * 100).toInt()}%');
      }

      // Allocate CPU budget based on purpose
      final cpuBudgetThousands = budgetInThousands * allocation['cpu']!;

      // Filter CPUs within budget allocation (unless user specified a CPU)
      List<QueryDocumentSnapshot> affordableCpus;

      if (specificCpuName != null) {
        // User specified CPU - use it directly, don't filter by budget
        affordableCpus = cpuCandidates;
        if (kDebugMode) {
          print(
              'Using user-specified CPU: $specificCpuName (${cpuCandidates.length} matches)');
        }
      } else {
        // No specific CPU - filter by budget allocation
        affordableCpus = cpuCandidates.where((cpu) {
          final data = cpu.data() as Map<String, dynamic>;
          final price = (data['discountedPrice'] as num?)?.toDouble() ??
              (data['sellingPrice'] as num?)?.toDouble() ??
              0;
          return price <= cpuBudgetThousands;
        }).toList();

        // If no CPU within allocation, try +50% relaxed
        if (affordableCpus.isEmpty) {
          final relaxedBudget = cpuBudgetThousands * 1.5;
          affordableCpus.addAll(cpuCandidates.where((cpu) {
            final data = cpu.data() as Map<String, dynamic>;
            final price = (data['discountedPrice'] as num?)?.toDouble() ??
                (data['sellingPrice'] as num?)?.toDouble() ??
                0;
            return price <= relaxedBudget && price > cpuBudgetThousands;
          }));
        }
      }

      if (affordableCpus.isEmpty) {
        return {
          'success': false,
          'message': isVietnamese
              ? 'Không tìm thấy CPU phù hợp trong ngân sách $budget triệu.'
              : 'Could not find affordable CPU within $budget million VND budget.'
        };
      }

      if (kDebugMode) {
        print(
            'Filtered to ${affordableCpus.length} CPUs within 35-50% budget allocation (${(cpuBudgetThousands / 1000).toStringAsFixed(1)}M)');
      }

      // Try each affordable CPU to find different price point builds
      for (final cpuCandidate in affordableCpus) {
        final cpuData = cpuCandidate.data() as Map<String, dynamic>;
        final cpuAttrs = cpuData['attributes'] as Map<String, dynamic>?;
        final testSocket =
            cpuAttrs?['socket']?.toString().toLowerCase().replaceAll(' ', '');

        if (testSocket == null) continue;

        if (kDebugMode) {
          print('Testing CPU: ${cpuData['productName']}, Socket: $testSocket');
        }

        // Try to find compatible mainboard
        final mbDocs = await _getCompatibleMainboards(testSocket);
        if (mbDocs.isEmpty) {
          if (kDebugMode) {
            print('✗ Skipping: No compatible mainboard for socket $testSocket');
          }
          continue;
        }

        // Try to find compatible RAM
        final compatibleRamTypes = socketToRamType[testSocket] ?? [];
        final ramDocs = await _getCompatibleRam(compatibleRamTypes);
        if (ramDocs.isEmpty) {
          if (kDebugMode) {
            print('✗ Skipping: No compatible RAM for socket $testSocket');
          }
          continue;
        }

        // Get other components (fetch affordable options, then try expensive→cheap)
        final gpuDocs = await _getProductsByCategory('gpu',
            topN: 30, sortOrder: 'ascending');
        final driveDocs = await _getProductsByCategory('drive',
            topN: 30, sortOrder: 'ascending');
        final psuDocs = await _getProductsByCategory('psu',
            topN: 30, sortOrder: 'ascending');

        // Ensure we have ALL 6 components
        if (gpuDocs.isEmpty || driveDocs.isEmpty || psuDocs.isEmpty) {
          if (kDebugMode) {
            print(
                '✗ Skipping: Missing components - GPU:${gpuDocs.length}, Drive:${driveDocs.length}, PSU:${psuDocs.length}');
          }
          continue;
        }

        // Calculate base price (CPU + MB + RAM)
        final cpuPrice = (cpuData['discountedPrice'] as num?)?.toDouble() ??
            (cpuData['sellingPrice'] as num?)?.toDouble() ??
            0;
        final mbData = mbDocs.first.data() as Map<String, dynamic>;
        final mbPrice = (mbData['discountedPrice'] as num?)?.toDouble() ??
            (mbData['sellingPrice'] as num?)?.toDouble() ??
            0;
        final ramData = ramDocs.first.data() as Map<String, dynamic>;
        final ramPrice = (ramData['discountedPrice'] as num?)?.toDouble() ??
            (ramData['sellingPrice'] as num?)?.toDouble() ??
            0;

        final basePrice = cpuPrice + mbPrice + ramPrice;
        final remainingBudget = budgetInThousands - basePrice;

        if (kDebugMode) {
          print(
              '  Base (CPU+MB+RAM): ${basePrice / 1000}M, Remaining: ${remainingBudget / 1000}M');
        }

        // Try to find GPU/Drive/PSU combination that fits remaining budget
        // Start with most expensive (end of ascending list) to maximize budget
        bool foundValidBuild = false;
        for (int gpuIdx = gpuDocs.length - 1;
            gpuIdx >= 0 && !foundValidBuild;
            gpuIdx--) {
          for (int driveIdx = driveDocs.length - 1;
              driveIdx >= 0 && !foundValidBuild;
              driveIdx--) {
            for (int psuIdx = psuDocs.length - 1;
                psuIdx >= 0 && !foundValidBuild;
                psuIdx--) {
              final gpuData = gpuDocs[gpuIdx].data() as Map<String, dynamic>;
              final gpuPrice =
                  (gpuData['discountedPrice'] as num?)?.toDouble() ??
                      (gpuData['sellingPrice'] as num?)?.toDouble() ??
                      0;
              final driveData =
                  driveDocs[driveIdx].data() as Map<String, dynamic>;
              final drivePrice =
                  (driveData['discountedPrice'] as num?)?.toDouble() ??
                      (driveData['sellingPrice'] as num?)?.toDouble() ??
                      0;
              final psuData = psuDocs[psuIdx].data() as Map<String, dynamic>;
              final psuPrice =
                  (psuData['discountedPrice'] as num?)?.toDouble() ??
                      (psuData['sellingPrice'] as num?)?.toDouble() ??
                      0;

              final componentPrice = gpuPrice + drivePrice + psuPrice;
              final totalPrice = basePrice + componentPrice;

              // Check if this combination fits budget
              if (totalPrice <= budgetInThousands) {
                // Build the complete set (guaranteed 6 items)
                final buildSet = [
                  cpuCandidate,
                  mbDocs.first,
                  ramDocs.first,
                  gpuDocs[gpuIdx],
                  driveDocs[driveIdx],
                  psuDocs[psuIdx],
                ];

                // Verify we have exactly 6 components
                assert(buildSet.length == 6, 'Build must have 6 components!');

                validBuilds.add({
                  'buildSet': buildSet,
                  'totalPrice': totalPrice,
                  'cpuName': cpuData['productName'],
                });

                if (kDebugMode) {
                  print(
                      '✓ Valid build with ${cpuData['productName']}: ${totalPrice / 1000}M / ${budget}M (${buildSet.length} components)');
                }
                foundValidBuild = true;
              }
            }
          }
        }

        if (!foundValidBuild && kDebugMode) {
          if (kDebugMode) {
            print(
                '✗ No valid GPU/Drive/PSU combination found within remaining budget');
          }
        }
      }

      // If no valid builds found
      if (validBuilds.isEmpty) {
        return {
          'success': false,
          'message': isVietnamese
              ? 'Không tìm thấy bộ linh kiện tương thích hoàn chỉnh trong ngân sách $budget triệu. Vui lòng tăng ngân sách.'
              : 'Could not find a complete compatible component set within $budget million VND budget. Please increase budget.'
        };
      }

      // Sort by total price descending (most expensive/closest to budget first)
      validBuilds.sort((a, b) =>
          (b['totalPrice'] as double).compareTo(a['totalPrice'] as double));

      // Pick the build closest to budget (most expensive within limit)
      final bestBuild = validBuilds.first;
      final buildSet = bestBuild['buildSet'] as List<QueryDocumentSnapshot>;
      final totalPrice = bestBuild['totalPrice'] as double;

      if (kDebugMode) {
        print('✓ Selected best build: ${bestBuild['cpuName']}');
        print(
            '  Total: ${totalPrice / 1000}M / ${budget}M (${((totalPrice / budgetInThousands) * 100).toStringAsFixed(1)}% of budget)');
      }

      return {
        'success': true,
        'products': buildSet,
        'context': isVietnamese
            ? 'Gợi ý build PC $purpose - Ngân sách: $budget triệu VND'
            : 'PC build suggestion for $purpose - Budget: $budget million VND',
        'userMessage': userMessage,
        'budget': budget,
        'purpose': purpose,
        'totalPrice': totalPrice / 1000,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error handling build suggestion: $e');
      }
      return {
        'success': false,
        'message': isVietnamese
            ? 'Có lỗi xảy ra khi tạo gợi ý cấu hình.'
            : 'An error occurred while creating build suggestion.'
      };
    }
  }

  /// Calculate budget allocation based on purpose
  Map<String, int> _calculateBudgetAllocation(String purpose, int totalBudget) {
    // Gaming-focused allocation
    if (purpose.contains('game') || purpose.contains('gaming')) {
      return {
        'cpu': (totalBudget * 0.20).round(),
        'gpu': (totalBudget * 0.40).round(), // GPU gets 40%
        'ram': (totalBudget * 0.10).round(),
        'mainboard': (totalBudget * 0.12).round(),
        'drive': (totalBudget * 0.08).round(),
        'psu': (totalBudget * 0.10).round(),
      };
    }

    // Design/Rendering-focused
    if (purpose.contains('design') ||
        purpose.contains('render') ||
        purpose.contains('đồ họa')) {
      return {
        'cpu': (totalBudget * 0.30).round(), // More CPU power
        'gpu': (totalBudget * 0.35).round(),
        'ram': (totalBudget * 0.15).round(), // More RAM
        'mainboard': (totalBudget * 0.10).round(),
        'drive': (totalBudget * 0.05).round(),
        'psu': (totalBudget * 0.05).round(),
      };
    }

    // Office/General purpose - balanced
    return {
      'cpu': (totalBudget * 0.25).round(),
      'gpu': (totalBudget * 0.20).round(),
      'ram': (totalBudget * 0.15).round(),
      'mainboard': (totalBudget * 0.15).round(),
      'drive': (totalBudget * 0.15).round(),
      'psu': (totalBudget * 0.10).round(),
    };
  }

  /// Get products by category without price limit (sorted by price ascending)
  Future<List<QueryDocumentSnapshot>> _getProductsByCategory(String category,
      {int topN = 10, String sortOrder = 'descending'}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .get();

      final docs = snapshot.docs.toList();

      if (kDebugMode) {
        print('Category "$category": Found ${docs.length} products');
      }

      // Sort based on strategy
      if (sortOrder == 'descending') {
        // Most expensive first
        docs.sort((a, b) {
          final aPrice = (a.data()['discountedPrice'] as num?)?.toDouble() ??
              (a.data()['sellingPrice'] as num?)?.toDouble() ??
              0.0;
          final bPrice = (b.data()['discountedPrice'] as num?)?.toDouble() ??
              (b.data()['sellingPrice'] as num?)?.toDouble() ??
              0.0;
          return bPrice.compareTo(aPrice);
        });
      } else if (sortOrder == 'ascending') {
        // Cheapest first (for GPU/Drive/PSU with low budgets)
        docs.sort((a, b) {
          final aPrice = (a.data()['discountedPrice'] as num?)?.toDouble() ??
              (a.data()['sellingPrice'] as num?)?.toDouble() ??
              0.0;
          final bPrice = (b.data()['discountedPrice'] as num?)?.toDouble() ??
              (b.data()['sellingPrice'] as num?)?.toDouble() ??
              0.0;
          return aPrice.compareTo(bPrice);
        });
      } else if (sortOrder == 'varied') {
        // Mix of prices (for CPU - get different price points)
        docs.sort((a, b) {
          final aPrice = (a.data()['discountedPrice'] as num?)?.toDouble() ??
              (a.data()['sellingPrice'] as num?)?.toDouble() ??
              0.0;
          final bPrice = (b.data()['discountedPrice'] as num?)?.toDouble() ??
              (b.data()['sellingPrice'] as num?)?.toDouble() ??
              0.0;
          return aPrice.compareTo(bPrice); // Start with cheap
        });
        // Shuffle to get variety
        docs.shuffle();
      }

      return docs.take(topN).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting products by category $category: $e');
      }
      return [];
    }
  }

  /// Get mainboards compatible with a specific socket (no budget limit)
  Future<List<QueryDocumentSnapshot>> _getCompatibleMainboards(
      String socket) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: 'mainboard')
          .where('status', isEqualTo: 'active')
          .get();

      if (kDebugMode) {
        print(
            'Mainboard Query: Found ${snapshot.docs.length} total mainboards');
        print('Looking for socket: $socket');
        if (snapshot.docs.isNotEmpty) {
          print('Sample Mainboards:');
          for (var doc in snapshot.docs.take(3)) {
            final data = doc.data();
            final attrs = data['attributes'] as Map<String, dynamic>?;
            final mbSock = attrs?['socket'];
            final price =
                (data['discountedPrice'] ?? data['sellingPrice']) / 1000;
            print(
                '  - ${data['productName']}: Socket=$mbSock, Price=${price}M');
          }
        }
      }

      final compatibleDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final attrs = data['attributes'] as Map<String, dynamic>?;
        final mbSocket =
            attrs?['socket']?.toString().toLowerCase().replaceAll(' ', '');
        return mbSocket == socket;
      }).toList();

      // Sort by price ascending (cheapest first)
      compatibleDocs.sort((a, b) {
        final aPrice = (a.data()['discountedPrice'] as num?)?.toDouble() ??
            (a.data()['sellingPrice'] as num?)?.toDouble() ??
            double.infinity;
        final bPrice = (b.data()['discountedPrice'] as num?)?.toDouble() ??
            (b.data()['sellingPrice'] as num?)?.toDouble() ??
            double.infinity;
        return aPrice.compareTo(bPrice);
      });

      if (kDebugMode) {
        print('Found ${compatibleDocs.length} compatible mainboards');
      }

      return compatibleDocs.take(1).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting compatible mainboards: $e');
      }
      return [];
    }
  }

  /// Get RAM compatible with specific RAM types (no budget limit)
  Future<List<QueryDocumentSnapshot>> _getCompatibleRam(
      List<String> ramTypes) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: 'ram')
          .where('status', isEqualTo: 'active')
          .get();

      if (kDebugMode) {
        print('RAM Query: Found ${snapshot.docs.length} total RAM products');
        print('Looking for RAM types: $ramTypes');
        if (snapshot.docs.isNotEmpty) {
          print('Sample RAM products:');
          for (var doc in snapshot.docs.take(3)) {
            final data = doc.data();
            final attrs = data['attributes'] as Map<String, dynamic>?;
            final type = attrs?['type'];
            final price =
                (data['discountedPrice'] ?? data['sellingPrice']) / 1000;
            print('  - ${data['productName']}: Type=$type, Price=${price}M');
          }
        }
      }

      final compatibleDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final attrs = data['attributes'] as Map<String, dynamic>?;
        final ramTypeRaw = attrs?['type']?.toString().toLowerCase();
        return ramTypeRaw != null && ramTypes.contains(ramTypeRaw);
      }).toList();

      // Sort by price ascending (cheapest first)
      compatibleDocs.sort((a, b) {
        final aPrice = (a.data()['discountedPrice'] as num?)?.toDouble() ??
            (a.data()['sellingPrice'] as num?)?.toDouble() ??
            double.infinity;
        final bPrice = (b.data()['discountedPrice'] as num?)?.toDouble() ??
            (b.data()['sellingPrice'] as num?)?.toDouble() ??
            double.infinity;
        return aPrice.compareTo(bPrice);
      });

      if (kDebugMode) {
        print('Found ${compatibleDocs.length} compatible RAM products');
      }

      return compatibleDocs.take(1).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting compatible RAM: $e');
      }
      return [];
    }
  }
}
