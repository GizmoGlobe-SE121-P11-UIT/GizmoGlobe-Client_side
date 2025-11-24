import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/builder/pc_builder_state.dart';
import 'package:gizmoglobe_client/services/platform_actions.dart'
    as platform_actions;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PCBuilderCubit extends Cubit<PCBuilderState> {
  final Random _random = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Firebase _firebaseService = Firebase();
  static const _regularFontAsset = 'assets/fonts/NotoSans-Regular.ttf';
  static const _boldFontAsset = 'assets/fonts/NotoSans-Bold.ttf';
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static const Map<String, String> _categoryLabels = {
    'cpu': 'CPU',
    'mainboard': 'Mainboard',
    'ram': 'RAM',
    'drive': 'Drive',
    'gpu': 'GPU',
    'psu': 'PSU',
  };

  PCBuilderCubit({String? initialConfigId, int initialTabIndex = 0})
      : super(
          PCBuilderState(
            configurations: _buildEmptyConfigurations(),
          ),
        ) {
    _initializeConfiguration(
      initialId: initialConfigId,
      initialTabIndex: initialTabIndex,
    );
  }

  static Map<String, dynamic> _emptyConfigurationEntry() => {
        'cpu': null,
        'mainboard': null,
        'ram': <Product>[],
        'drive': <Product>[],
        'gpu': null,
        'psu': null,
      };

  static List<Map<String, dynamic>> _buildEmptyConfigurations() =>
      List.generate(5, (_) => _emptyConfigurationEntry());

  void _initializeConfiguration(
      {String? initialId, int? initialTabIndex}) async {
    final trimmedId = initialId?.trim() ?? '';

    // If an explicit session id is provided, try to load it first
    if (trimmedId.isNotEmpty) {
      final loadedSpecific = await _loadBuilderFromFirebase(trimmedId);
      if (loadedSpecific) {
        _updateEstimatedCost();
        return;
      }
    }

    // Otherwise try to load the most recently updated builder session
    final loadedLatest = await _loadLatestBuilderFromFirebase();
    if (loadedLatest) {
      _updateEstimatedCost();
      return;
    }

    // No existing builder found, create a brand-new session
    final configId = _generateConfigId();
    final tabIndex = _normalizeTabIndex(initialTabIndex ?? 0);

    _syncBrowserUrl(configId, tabIndex);

    emit(
      state.copyWith(
        configurationId: configId,
        configurationUrl: _buildSessionUrl(configId, tabIndex),
        activeConfigurationIndex: tabIndex,
      ),
    );
    _updateEstimatedCost();
    _saveBuilderToFirebase();
  }

  int _normalizeTabIndex(int value) {
    if (value < 0) return 0;
    if (value >= state.configurations.length) {
      return state.configurations.length - 1;
    }
    return value;
  }

  String _buildHashPath(String configId, int tabIndex) {
    return '/builder/$configId';
  }

  String _buildSessionUrl(String configId, int tabIndex) {
    if (configId.isEmpty) return '';
    final path = _buildHashPath(configId, tabIndex);
    if (kIsWeb) {
      return '${Uri.base.origin}/#$path';
    }
    return path;
  }

  String _generateConfigId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(36, (_) => chars[_random.nextInt(chars.length)])
        .join();
  }

  void switchConfiguration(int index) {
    if (index < 0 || index >= state.configurations.length) return;

    final normalized = _normalizeTabIndex(index);
    final configId = state.configurationId;

    _syncBrowserUrl(configId, normalized);

    emit(
      state.copyWith(
        activeConfigurationIndex: normalized,
        configurationUrl: _buildSessionUrl(configId, normalized),
      ),
    );
    _updateEstimatedCost();
  }

  void selectComponent(String componentKey, Product? product) {
    final updatedConfigs =
        List<Map<String, dynamic>>.from(state.configurations);
    updatedConfigs[state.activeConfigurationIndex] = Map<String, dynamic>.from(
        updatedConfigs[state.activeConfigurationIndex]);

    final updatedQuantities = Map<String, int>.from(state.quantities);

    // For RAM and drive, support multiple products (list)
    // For other components, single product
    if (componentKey == 'ram' || componentKey == 'drive') {
      final currentList = updatedConfigs[state.activeConfigurationIndex]
              [componentKey] as List<Product>? ??
          <Product>[];
      if (product != null) {
        // Add product to the list with default quantity 1
        updatedConfigs[state.activeConfigurationIndex]
            [componentKey] = [...currentList, product];
        if (product.productID != null) {
          updatedQuantities[product.productID!] = 1;
        }
      } else {
        // Clear the list and quantities
        final productsToRemove =
            currentList.map((p) => p.productID).whereType<String>().toList();
        for (final productId in productsToRemove) {
          updatedQuantities.remove(productId);
        }
        updatedConfigs[state.activeConfigurationIndex]
            [componentKey] = <Product>[];
      }
    } else {
      // Single product for other components
      final oldProduct = updatedConfigs[state.activeConfigurationIndex]
          [componentKey] as Product?;
      if (oldProduct?.productID != null) {
        updatedQuantities.remove(oldProduct!.productID!);
      }
      updatedConfigs[state.activeConfigurationIndex][componentKey] = product;
      if (product != null && product.productID != null) {
        updatedQuantities[product.productID!] = 1;
      }
    }

    emit(state.copyWith(
        configurations: updatedConfigs, quantities: updatedQuantities));
    _updateEstimatedCost();
    _saveBuilderToFirebase();
  }

  void removeComponentFromList(String componentKey, int index) {
    if (componentKey != 'ram' && componentKey != 'drive') return;

    final updatedConfigs =
        List<Map<String, dynamic>>.from(state.configurations);
    updatedConfigs[state.activeConfigurationIndex] = Map<String, dynamic>.from(
        updatedConfigs[state.activeConfigurationIndex]);

    final updatedQuantities = Map<String, int>.from(state.quantities);
    final currentList = updatedConfigs[state.activeConfigurationIndex]
            [componentKey] as List<Product>? ??
        <Product>[];
    if (index >= 0 && index < currentList.length) {
      final productToRemove = currentList[index];
      if (productToRemove.productID != null) {
        updatedQuantities.remove(productToRemove.productID!);
      }
      final newList = List<Product>.from(currentList)..removeAt(index);
      updatedConfigs[state.activeConfigurationIndex][componentKey] = newList;
    }

    emit(state.copyWith(
        configurations: updatedConfigs, quantities: updatedQuantities));
    _updateEstimatedCost();
    _saveBuilderToFirebase();
  }

  void updateQuantity(String componentKey, Product product, int quantity) {
    if (quantity < 1) return;

    final updatedQuantities = Map<String, int>.from(state.quantities);
    if (product.productID != null) {
      updatedQuantities[product.productID!] = quantity;
    }

    emit(state.copyWith(quantities: updatedQuantities));
    _updateEstimatedCost();
    _saveBuilderToFirebase();
  }

  void updateQuantityInList(String componentKey, int index, int quantity) {
    if (componentKey != 'ram' && componentKey != 'drive') return;
    if (quantity < 1) return;

    final config = state.activeConfiguration;
    final products = config[componentKey] as List<Product>? ?? [];
    if (index >= 0 && index < products.length) {
      final product = products[index];
      updateQuantity(componentKey, product, quantity);
    }
  }

  void toggleCompatibilityChecker(bool value) {
    emit(state.copyWith(enableCompatibilityChecker: value));
    _saveBuilderToFirebase();
  }

  void _updateEstimatedCost() {
    final config = state.activeConfiguration;
    int total = 0;

    config.forEach((key, value) {
      if (key == 'ram' || key == 'drive') {
        // Handle list of products
        final products = value as List<Product>? ?? [];
        for (final product in products) {
          final quantity = product.productID != null
              ? (state.quantities[product.productID!] ?? 1)
              : 1;
          total += (product.discountedPrice.toInt() * quantity);
        }
      } else {
        // Handle single product
        final product = value as Product?;
        if (product != null) {
          final quantity = product.productID != null
              ? (state.quantities[product.productID!] ?? 1)
              : 1;
          total += (product.discountedPrice.toInt() * quantity);
        }
      }
    });

    emit(state.copyWith(estimatedCost: total));
  }

  void recreateConfiguration() {
    final updatedConfigs = _buildEmptyConfigurations();
    emit(state.copyWith(
      configurations: updatedConfigs,
      activeConfigurationIndex: 0,
      estimatedCost: 0,
      quantities: {},
    ));
    _initializeConfiguration(initialTabIndex: 0);
  }

  void _syncBrowserUrl(String configId, int tabIndex) {
    if (!kIsWeb || configId.isEmpty) return;
    final targetHash = _buildHashPath(configId, tabIndex);
    if (platform_actions.getHashPath() == targetHash) return;

    Future.microtask(() {
      try {
        platform_actions.replaceHashUrl(targetHash);
      } catch (_) {
        platform_actions.setHashFragment(targetHash);
      }
    });
  }

  List<_BuilderComponentEntry> _collectActiveComponents() {
    final entries = <_BuilderComponentEntry>[];
    final activeConfig = state.activeConfiguration;

    for (final entry in activeConfig.entries) {
      final category = entry.key;
      final value = entry.value;

      if (category == 'ram' || category == 'drive') {
        final products = value as List<Product>? ?? [];
        for (final product in products) {
          final productId = product.productID;
          if (productId == null) continue;
          final quantity = state.quantities[productId] ?? 1;
          entries.add(
            _BuilderComponentEntry(
              category: category,
              label: _categoryLabels[category] ?? category.toUpperCase(),
              product: product,
              quantity: quantity,
            ),
          );
        }
        continue;
      }

      final product = value as Product?;
      if (product == null || product.productID == null) {
        continue;
      }

      final quantity = state.quantities[product.productID!] ?? 1;
      entries.add(
        _BuilderComponentEntry(
          category: category,
          label: _categoryLabels[category] ?? category.toUpperCase(),
          product: product,
          quantity: quantity,
        ),
      );
    }

    return entries;
  }

  void compareConfigurations() {
    // TODO: Implement comparison feature
    if (kDebugMode) {
      print('Compare configurations');
    }
  }

  Future<void> downloadConfigurationPdf() async {
    final components = _collectActiveComponents();
    if (components.isEmpty) {
      if (kDebugMode) {
        print('No components selected, skipping PDF generation.');
      }
      return;
    }

    final document = pw.Document();
    final notoSansRegular = await _loadBuilderRegularFont();
    final notoSansBold = await _loadBuilderBoldFont();
    final timestamp = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    final estimatedTotal = components.fold<double>(
      0,
      (sum, entry) => sum + entry.product.discountedPrice * entry.quantity,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: notoSansRegular,
            bold: notoSansBold,
            italic: notoSansRegular,
          ),
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PC Builder Summary',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Session ID: ${state.configurationId.isEmpty ? '-' : state.configurationId}'),
              pw.Text('Generated: $timestamp'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: const [
                  'Category',
                  'Product',
                  'Discounted Price',
                  'Quantity',
                ],
                data: components
                    .map(
                      (entry) => [
                        entry.label,
                        entry.product.productName,
                        Helper.toCurrencyFormatForPDF(
                            entry.product.discountedPrice),
                        'x${entry.quantity}',
                      ],
                    )
                    .toList(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border.symmetric(
                    horizontal: pw.BorderSide(color: PdfColors.grey200),
                  ),
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 6,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Estimated Total',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey700,
                      ),
                    ),
                    pw.Text(
                      Helper.toCurrencyFormatForPDF(estimatedTotal),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final pdfBytes = await document.save();
    final fileName =
        'pc_builder_${state.configurationId.isNotEmpty ? state.configurationId : 'session'}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  Future<void> buyNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print('User must be logged in to add components to cart.');
      }
      return;
    }

    final components = _collectActiveComponents();
    if (components.isEmpty) {
      if (kDebugMode) {
        print('No components selected, skipping add to cart.');
      }
      return;
    }

    for (final entry in components) {
      final productId = entry.product.productID;
      if (productId == null) continue;
      try {
        await _firebaseService.addToCart(user.uid, productId, entry.quantity);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to add ${entry.product.productName} to cart: $e');
        }
      }
    }
  }

  static Future<pw.Font> _loadBuilderRegularFont() async {
    final cached = _cachedRegularFont;
    if (cached != null) {
      return cached;
    }
    final font = await _loadBuilderFont(_regularFontAsset);
    _cachedRegularFont = font;
    return font;
  }

  static Future<pw.Font> _loadBuilderBoldFont() async {
    final cached = _cachedBoldFont;
    if (cached != null) {
      return cached;
    }
    final font = await _loadBuilderFont(_boldFontAsset);
    _cachedBoldFont = font;
    return font;
  }

  static Future<pw.Font> _loadBuilderFont(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.Font.ttf(data);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        Exception('Failed to load builder font asset: $assetPath'),
        stackTrace,
      );
    }
  }

  Future<void> addConfiguration() async {
    final newConfigId = _generateConfigId();
    const tabIndex = 0;
    final freshConfigs = _buildEmptyConfigurations();

    emit(
      state.copyWith(
        configurationId: newConfigId,
        configurationUrl: _buildSessionUrl(newConfigId, tabIndex),
        activeConfigurationIndex: tabIndex,
        configurations: freshConfigs,
        quantities: {},
        estimatedCost: 0,
      ),
    );
    _syncBrowserUrl(newConfigId, tabIndex);
    await _saveBuilderToFirebase();
  }

  Future<void> deleteConfiguration() async {
    final user = FirebaseAuth.instance.currentUser;
    final configId = state.configurationId;
    if (user == null || configId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('builders')
          .doc(configId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete builder session: $e');
      }
    }

    final loadedExisting = await _loadLatestBuilderFromFirebase();
    if (loadedExisting) {
      _updateEstimatedCost();
      return;
    }

    await addConfiguration();
  }

  Future<void> resetConfiguration() async {
    final activeIndex = state.activeConfigurationIndex;
    final updatedConfigs =
        List<Map<String, dynamic>>.from(state.configurations);
    if (activeIndex >= updatedConfigs.length) return;

    updatedConfigs[activeIndex] = _emptyConfigurationEntry();
    emit(
      state.copyWith(
        configurations: updatedConfigs,
        quantities: {},
        estimatedCost: 0,
      ),
    );
    await _saveBuilderToFirebase();
  }

  Future<void> uploadConfiguration() async {
    await _saveBuilderToFirebase();
  }

  Future<List<BuilderSessionSummary>> fetchBuilderSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('builders')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['updatedAt'];
        final estimatedCost = (data['estimatedCost'] as num?)?.toInt() ?? 0;
        final componentCount = _countComponentsFromData(data);
        return BuilderSessionSummary(
          id: doc.id,
          updatedAt: timestamp is Timestamp ? timestamp.toDate() : null,
          estimatedCost: estimatedCost,
          componentCount: componentCount,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch builder sessions: $e');
      }
      return [];
    }
  }

  Future<bool> loadBuilderSession(String configId) async {
    final loaded = await _loadBuilderFromFirebase(configId);
    if (loaded) {
      _updateEstimatedCost();
    }
    return loaded;
  }

  Future<bool> _loadLatestBuilderFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('builders')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      final latestDocId = snapshot.docs.first.id;
      return _loadBuilderFromFirebase(latestDocId);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading latest builder from Firebase: $e');
      }
      return false;
    }
  }

  Future<bool> _loadBuilderFromFirebase(String configId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || configId.isEmpty) return false;

    try {
      final doc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('builders')
          .doc(configId)
          .get();

      if (!doc.exists || !doc.data()!.containsKey('configurationId')) {
        return false;
      }

      final data = doc.data()!;
      final activeIndex = (data['activeConfigurationIndex'] as int?) ?? 0;
      final enableCompatibilityChecker =
          (data['enableCompatibilityChecker'] as bool?) ?? false;
      final estimatedCost = (data['estimatedCost'] as int?) ?? 0;

      // Import Database to access product lists
      final database = Database();
      if (database.productList.isEmpty && database.fullProductList.isEmpty) {
        // Products not loaded yet, can't restore
        return false;
      }

      // Reconstruct configuration
      final updatedConfigs =
          List<Map<String, dynamic>>.from(state.configurations);
      final updatedQuantities = <String, int>{};

      // Load each category
      final categories = ['cpu', 'mainboard', 'ram', 'drive', 'gpu', 'psu'];
      for (final category in categories) {
        final categoryData = data[category] as List<dynamic>?;
        if (categoryData == null || categoryData.isEmpty) {
          if (category == 'ram' || category == 'drive') {
            updatedConfigs[activeIndex][category] = <Product>[];
          } else {
            updatedConfigs[activeIndex][category] = null;
          }
          continue;
        }

        if (category == 'ram' || category == 'drive') {
          // Handle list of products
          final products = <Product>[];
          for (final item in categoryData) {
            final itemMap = item as Map<String, dynamic>?;
            if (itemMap == null) continue;

            final productID = itemMap['productID'] as String?;
            final quantity = (itemMap['quantity'] as int?) ?? 1;

            if (productID == null || productID.isEmpty) continue;

            // Find product in database
            Product? product;
            try {
              product = database.fullProductList.firstWhere(
                (p) => p.productID == productID,
                orElse: () {
                  return database.productList.firstWhere(
                    (p) => p.productID == productID,
                    orElse: () => throw Exception('Product not found'),
                  );
                },
              );
            } catch (_) {
              // Product not found, skip
              continue;
            }

            products.add(product);
            updatedQuantities[productID] = quantity;
          }
          updatedConfigs[activeIndex][category] = products;
        } else {
          // Handle single product
          final item = categoryData.isNotEmpty ? categoryData.first : null;
          if (item == null) {
            updatedConfigs[activeIndex][category] = null;
            continue;
          }

          final itemMap = item as Map<String, dynamic>?;
          if (itemMap == null) {
            updatedConfigs[activeIndex][category] = null;
            continue;
          }

          final productID = itemMap['productID'] as String?;
          final quantity = (itemMap['quantity'] as int?) ?? 1;

          if (productID == null || productID.isEmpty) {
            updatedConfigs[activeIndex][category] = null;
            continue;
          }

          // Find product in database
          Product? product;
          try {
            product = database.fullProductList.firstWhere(
              (p) => p.productID == productID,
              orElse: () {
                return database.productList.firstWhere(
                  (p) => p.productID == productID,
                  orElse: () => throw Exception('Product not found'),
                );
              },
            );
          } catch (_) {
            // Product not found, set to null
            updatedConfigs[activeIndex][category] = null;
            continue;
          }

          updatedConfigs[activeIndex][category] = product;
          updatedQuantities[productID] = quantity;
        }
      }

      emit(
        state.copyWith(
          configurationId: configId,
          configurationUrl: _buildSessionUrl(configId, activeIndex),
          activeConfigurationIndex: activeIndex,
          configurations: updatedConfigs,
          enableCompatibilityChecker: enableCompatibilityChecker,
          estimatedCost: estimatedCost,
          quantities: updatedQuantities,
        ),
      );

      _syncBrowserUrl(configId, activeIndex);

      if (kDebugMode) {
        print(
            'Builder loaded from Firebase: customers/${user.uid}/builders/$configId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading builder from Firebase: $e');
      }
      return false;
    }
  }

  Future<void> _saveBuilderToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final configId = state.configurationId;
    if (configId.isEmpty) return;

    try {
      final activeConfig = state.activeConfiguration;

      // Convert Product objects to arrays with productID and quantity for each category
      final Map<String, dynamic> builderData = {
        'configurationId': configId,
        'activeConfigurationIndex': state.activeConfigurationIndex,
        'enableCompatibilityChecker': state.enableCompatibilityChecker,
        'estimatedCost': state.estimatedCost,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save each category as an array with productID and quantity
      activeConfig.forEach((category, value) {
        if (category == 'ram' || category == 'drive') {
          // Handle list of products
          final products = value as List<Product>? ?? [];
          builderData[category] = products.map((product) {
            final quantity = product.productID != null
                ? (state.quantities[product.productID!] ?? 1)
                : 1;
            return {
              'productID': product.productID,
              'quantity': quantity,
            };
          }).toList();
        } else {
          // Handle single product
          final product = value as Product?;
          if (product != null && product.productID != null) {
            final quantity = state.quantities[product.productID!] ?? 1;
            builderData[category] = [
              {
                'productID': product.productID,
                'quantity': quantity,
              }
            ];
          } else {
            builderData[category] = [];
          }
        }
      });

      await _firestore
          .collection('customers')
          .doc(userId)
          .collection('builders')
          .doc(configId)
          .set(builderData, SetOptions(merge: true));

      if (kDebugMode) {
        print(
            'Builder saved to Firebase: customers/$userId/builders/$configId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving builder to Firebase: $e');
      }
    }
  }

  int _countComponentsFromData(Map<String, dynamic> data) {
    final categories = ['cpu', 'mainboard', 'ram', 'drive', 'gpu', 'psu'];
    var count = 0;
    for (final category in categories) {
      final items = data[category];
      if (items is List) {
        count += items.length;
      }
    }
    return count;
  }
}

class _BuilderComponentEntry {
  final String category;
  final String label;
  final Product product;
  final int quantity;

  const _BuilderComponentEntry({
    required this.category,
    required this.label,
    required this.product,
    required this.quantity,
  });
}

class BuilderSessionSummary {
  final String id;
  final DateTime? updatedAt;
  final int estimatedCost;
  final int componentCount;

  BuilderSessionSummary({
    required this.id,
    required this.updatedAt,
    required this.estimatedCost,
    required this.componentCount,
  });
}
