import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../objects/product_related/product.dart';
import '../enums/product_related/category_enum.dart';

/// Compatibility Question Handler
///
/// Handles questions about component compatibility using the 3-tier
/// recommendation system (Vertex AI → Cache → Rule-based)
class CompatibilityHandler {
  /// Handle compatibility questions
  Future<Map<String, dynamic>> handleCompatibilityQuestion(
    String userMessage,
    Map<String, dynamic> entities,
    bool isVietnamese,
  ) async {
    // Handle both String and List types from classifier
    final socketEntity = entities['socket'];
    final socket = socketEntity is String
        ? socketEntity
        : (socketEntity is List && socketEntity.isNotEmpty
            ? socketEntity.first.toString()
            : null);

    final categoryEntity = entities['category'];
    final category = categoryEntity is String
        ? categoryEntity
        : (categoryEntity is List && categoryEntity.isNotEmpty
            ? categoryEntity.first.toString()
            : null);

    final productNames = entities['product_names'] as List?;

    List<QueryDocumentSnapshot> compatibleDocs = [];
    String compatibilityContext = '';

    // Case 1: Socket-based compatibility
    if (socket != null) {
      final result =
          await _handleSocketCompatibility(socket, category, isVietnamese);
      compatibleDocs = result['products'];
      compatibilityContext = result['context'];
    }
    // Case 2: Product-based compatibility (e.g., "i7 12700 thuộc socket nào?")
    else if (productNames != null && productNames.isNotEmpty) {
      // This is asking about a product's socket/compatibility
      // We should find the product, get its socket, then find compatible products
      final result = await _handleProductCompatibility(
          productNames.first.toString(), category, isVietnamese);
      compatibleDocs = result['products'];
      compatibilityContext = result['context'];
    }
    // Case 3: General compatibility question
    else {
      return {
        'success': false,
        'message': isVietnamese
            ? 'Vui lòng cung cấp thêm thông tin về linh kiện hoặc socket bạn quan tâm.'
            : 'Please provide more information about the component or socket you\'re interested in.'
      };
    }

    if (compatibleDocs.isEmpty) {
      return {
        'success': false,
        'message': isVietnamese
            ? 'Xin lỗi, tôi không tìm thấy linh kiện tương thích với yêu cầu của bạn.'
            : 'Sorry, I couldn\'t find compatible components for your request.'
      };
    }

    return {
      'success': true,
      'products': compatibleDocs,
      'context': compatibilityContext,
      'userMessage': userMessage,
    };
  }

  /// Socket to RAM Type mapping
  /// AM4, AM5 → DDR4/DDR5
  /// LGA1700, LGA1200 → DDR4/DDR5
  static const Map<String, List<String>> _socketToRamTypeMapping = {
    // AMD Sockets
    'am4': ['ddr4'],
    'am5': ['ddr5'],
    'tr4': ['ddr4'],
    'trx4': ['ddr4'],
    'strx4': ['ddr4'],

    // Intel Sockets
    'lga1700': ['ddr4', 'ddr5'], // 12th/13th/14th gen supports both
    'lga1200': ['ddr4'],
    'lga1151': ['ddr4'],
    'lga2066': ['ddr4'],
  };

  /// Handle socket-based compatibility queries
  Future<Map<String, dynamic>> _handleSocketCompatibility(
    String socket,
    String? category,
    bool isVietnamese,
  ) async {
    // Firebase stores enum names in lowercase (e.g., "lga1700")
    final socketNorm = socket.toLowerCase().replaceAll(' ', '');

    final context = isVietnamese
        ? 'Linh kiện tương thích với socket ${socket.toUpperCase()}'
        : 'Components compatible with socket ${socket.toUpperCase()}';

    try {
      // Return the QueryDocumentSnapshots directly
      final allDocs = <QueryDocumentSnapshot>[];

      if (category == null || category == 'cpu') {
        final cpuSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: 'cpu')
            .where('status', isEqualTo: 'active')
            .get();

        // Filter by socket from attributes map
        for (var doc in cpuSnapshot.docs) {
          final data = doc.data();
          final attrs = data['attributes'] as Map<String, dynamic>?;
          final cpuSocket = attrs?['socket']?.toString().toLowerCase();
          if (cpuSocket == socketNorm) {
            allDocs.add(doc);
          }
        }
      }

      if (category == null || category == 'mainboard') {
        final mbSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: 'mainboard')
            .where('status', isEqualTo: 'active')
            .get();

        // Filter by socket from attributes map
        for (var doc in mbSnapshot.docs) {
          final data = doc.data();
          final attrs = data['attributes'] as Map<String, dynamic>?;
          final mbSocket = attrs?['socket']?.toString().toLowerCase();
          if (mbSocket == socketNorm) {
            allDocs.add(doc);
          }
        }
      }

      // NEW: Handle RAM compatibility based on socket
      if (category == null || category == 'ram') {
        final compatibleRamTypes = _socketToRamTypeMapping[socketNorm];

        if (compatibleRamTypes != null && compatibleRamTypes.isNotEmpty) {
          final ramSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: 'ram')
              .where('status', isEqualTo: 'active')
              .get();

          // Filter by RAM type from attributes map
          for (var doc in ramSnapshot.docs) {
            final data = doc.data();
            final attrs = data['attributes'] as Map<String, dynamic>?;
            final ramType = attrs?['ramType']?.toString().toLowerCase();

            // Check if this RAM type is compatible with the socket
            if (ramType != null &&
                compatibleRamTypes
                    .any((type) => ramType.contains(type.toLowerCase()))) {
              allDocs.add(doc);
            }
          }

          if (kDebugMode) {
            print(
                'Found ${allDocs.where((d) => (d.data() as Map)['category'] == 'ram').length} RAM products for socket $socketNorm (RAM types: $compatibleRamTypes)');
          }
        } else if (kDebugMode) {
          print('No RAM type mapping found for socket: $socketNorm');
        }
      }

      // Limit results to top 5
      return {
        'products': allDocs.take(5).toList(),
        'context': context,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error querying Firestore for socket compatibility: $e');
      }
      return {
        'products': <QueryDocumentSnapshot>[],
        'context': context,
      };
    }
  }

  /// Handle product-based compatibility queries
  /// When user asks "i7 12700 thuộc socket nào?", find the product's socket
  /// then return compatible products (mainboards, etc.)
  Future<Map<String, dynamic>> _handleProductCompatibility(
    String productName,
    String? requestedCategory,
    bool isVietnamese,
  ) async {
    try {
      // Search for the product in Firestore
      final searchQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'active')
          .get();

      // Find matching product by name
      if (kDebugMode) {
        print('Searching for product: "$productName"');
      }

      QueryDocumentSnapshot? matchedProduct;
      for (var doc in searchQuery.docs) {
        final data = doc.data();
        final name = data['productName']?.toString().toLowerCase() ?? '';
        if (name.contains(productName.toLowerCase())) {
          matchedProduct = doc;
          if (kDebugMode) {
            print('Found matching product: ${data['productName']}');
          }
          break;
        }
      }

      if (matchedProduct == null) {
        if (kDebugMode) {
          print('No product found matching: "$productName"');
        }
        return {
          'products': <QueryDocumentSnapshot>[],
          'context': isVietnamese
              ? 'Không tìm thấy sản phẩm "$productName"'
              : 'Product "$productName" not found',
        };
      }

      // Get product socket from attributes
      final productData = matchedProduct.data() as Map<String, dynamic>;
      final attrs = productData['attributes'] as Map<String, dynamic>?;
      final productSocket = attrs?['socket']?.toString();
      final productCategory = productData['category']?.toString();

      if (productSocket == null) {
        return {
          'products': [matchedProduct], // Return the product itself
          'context': isVietnamese
              ? '${productData['productName']}'
              : '${productData['productName']}',
        };
      }

      // Now find compatible products with the same socket
      // If asking about CPU → show mainboards with same socket
      // If asking about mainboard → show CPUs with same socket
      // If asking about RAM for CPU/mainboard → show compatible RAM types
      final socketNorm = productSocket.toLowerCase().replaceAll(' ', '');
      final List<QueryDocumentSnapshot> compatibleDocs = [matchedProduct];

      // If user is asking for RAM compatible with this CPU/Mainboard
      if (requestedCategory == 'ram' &&
          (productCategory == 'cpu' || productCategory == 'mainboard')) {
        // Use socket-to-RAM-type mapping
        final compatibleRamTypes = _socketToRamTypeMapping[socketNorm];

        if (compatibleRamTypes != null && compatibleRamTypes.isNotEmpty) {
          final ramSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: 'ram')
              .where('status', isEqualTo: 'active')
              .get();

          for (var doc in ramSnapshot.docs) {
            final data = doc.data();
            final ramType = data['ramType']?.toString().toLowerCase();
            if (ramType != null && compatibleRamTypes.contains(ramType)) {
              compatibleDocs.add(doc);
            }
          }

          if (kDebugMode) {
            print(
                'Found ${compatibleDocs.length - 1} RAM products for ${productData['productName']} (socket $socketNorm, RAM types: $compatibleRamTypes)');
          }
        }
      }
      // Query mainboards if product is CPU (and not specifically asking for RAM)
      else if (productCategory == 'cpu' && requestedCategory != 'ram') {
        final mbSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: 'mainboard')
            .where('status', isEqualTo: 'active')
            .get();

        for (var doc in mbSnapshot.docs) {
          final data = doc.data();
          final attrs = data['attributes'] as Map<String, dynamic>?;
          final mbSocket = attrs?['socket']?.toString().toLowerCase();
          if (mbSocket == socketNorm) {
            compatibleDocs.add(doc);
          }
        }
      }

      final context = isVietnamese
          ? '${productData['productName']} sử dụng socket ${productSocket.toUpperCase()}'
          : '${productData['productName']} uses socket ${productSocket.toUpperCase()}';

      return {
        'products': compatibleDocs.take(5).toList(),
        'context': context,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in _handleProductCompatibility: $e');
      }
      return {
        'products': <QueryDocumentSnapshot>[],
        'context': isVietnamese
            ? 'Có lỗi xảy ra khi tìm kiếm'
            : 'Error occurred during search',
      };
    }
  }

  /// Convert products to Firestore document format for AI prompt
  Future<List<QueryDocumentSnapshot>> convertToFirestoreDocs(
      List<Product> products) async {
    if (products.isEmpty) return [];

    try {
      // Get all product IDs
      final productIds = products
          .where((p) => p.productID != null)
          .map((p) => p.productID!)
          .toList();

      if (productIds.isEmpty) return [];

      // Firestore whereIn limit is 10, so batch the queries
      final List<QueryDocumentSnapshot> allDocs = [];

      for (int i = 0; i < productIds.length; i += 10) {
        final batch = productIds.skip(i).take(10).toList();

        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        allDocs.addAll(snapshot.docs);
      }

      return allDocs;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching product docs: $e');
      }
      return [];
    }
  }

  /// Parse category string to CategoryEnum
  CategoryEnum? parseCategoryEnum(String? category) {
    if (category == null) return null;

    switch (category.toLowerCase()) {
      case 'cpu':
        return CategoryEnum.cpu;
      case 'gpu':
        return CategoryEnum.gpu;
      case 'ram':
        return CategoryEnum.ram;
      case 'mainboard':
      case 'motherboard':
        return CategoryEnum.mainboard;
      case 'psu':
        return CategoryEnum.psu;
      case 'drive':
      case 'ssd':
      case 'hdd':
        return CategoryEnum.drive;
      default:
        return null;
    }
  }
}
