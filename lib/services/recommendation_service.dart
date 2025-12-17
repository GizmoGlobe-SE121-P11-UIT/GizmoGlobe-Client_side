import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/data/database/database.dart';

import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';

import 'package:gizmoglobe_client/objects/product_related/gpu_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/drive_related/drive.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard_related/mainboard.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/psu_related/psu.dart';
import 'package:gizmoglobe_client/objects/product_related/ram_related/ram.dart';

/// Hybrid Recommendation Service
///
/// This service provides product recommendations using a 3-tier fallback system:
/// 1. **Vertex AI** (if configured) - ML-based recommendations from Google Cloud
/// 2. **Firestore Cache** - Collaborative filtering computed by Cloud Functions
/// 3. **Content-Based** - Rule-based similarity using product specifications
///
/// The system automatically falls back to the next tier if the current one fails.
class RecommendationService {
  final Database _db = Database();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<String, double> _weights = {
    'PRICE': 0.3,
    'RECENCY': 0.4,
    'POPULARITY': 0.3,
  };

  // ==========================================================================
  // HYBRID RECOMMENDATIONS (MAIN ENTRY POINT)
  // ==========================================================================

  /// Get similar products using the hybrid approach.
  /// Falls back from Vertex AI → Firestore Cache → Content-Based.
  ///
  /// [product] - The product to find similar products for
  /// [topN] - Maximum number of recommendations to return
  /// [reason] - Output parameter indicating which method was used
  Future<List<Product>> getSimilarProducts(
    Product product, {
    int topN = 10,
    bool excludeOutOfStock = false,
  }) async {
    if (product.productID == null) return [];

    // Tier 1: Try Vertex AI recommendations (if configured)
    try {
      final vertexResults =
          await _getVertexAIRecommendations(product.productID!, topN);
      if (vertexResults.isNotEmpty) {
        return _filterResults(vertexResults, excludeOutOfStock, topN);
      }
    } catch (e) {
      // Vertex AI not configured or failed, fall through
    }

    // Tier 2: Try Firestore cached similarity (from Cloud Functions)
    try {
      final cacheResults = await _getCachedSimilarity(product.productID!, topN);
      if (cacheResults.isNotEmpty) {
        return _filterResults(cacheResults, excludeOutOfStock, topN);
      }
    } catch (e) {
      // Cache not available, fall through
    }

    // Tier 3: Content-based similarity (always available)
    return getContentBasedSimilarProducts(product,
        topN: topN, excludeOutOfStock: excludeOutOfStock);
  }

  /// Filter results by stock status
  List<Product> _filterResults(
      List<Product> products, bool excludeOutOfStock, int topN) {
    return products
        .where((p) =>
            p.status == ProductStatusEnum.active ||
            (!excludeOutOfStock && p.status == ProductStatusEnum.outOfStock))
        .take(topN)
        .toList();
  }

  // ==========================================================================
  // TIER 1: VERTEX AI RECOMMENDATIONS
  // ==========================================================================

  /// Get recommendations from Vertex AI via Cloud Functions proxy.
  /// Returns empty list if Vertex AI is not configured.
  Future<List<Product>> _getVertexAIRecommendations(
      String productId, int topN) async {
    try {
      // Check if Vertex AI is enabled in config
      final configDoc =
          await _firestore.collection('config').doc('recommendations').get();

      if (!configDoc.exists) {
        return [];
      }

      final config = configDoc.data();
      if (config == null || config['vertexAIEnabled'] != true) {
        return [];
      }

      // Call Cloud Function that proxies to Vertex AI
      final resultDoc = await _firestore
          .collection('vertex_recommendations')
          .doc(productId)
          .get();

      if (!resultDoc.exists) {
        return [];
      }

      final data = resultDoc.data();
      if (data == null) {
        return [];
      }

      final similarIds = List<String>.from(data['similar'] ?? []);
      return _resolveProductIds(similarIds, topN);
    } catch (e) {
      return [];
    }
  }

  // ==========================================================================
  // TIER 2: FIRESTORE CACHED SIMILARITY (Collaborative Filtering)
  // ==========================================================================

  /// Get cached similarity data computed by Cloud Functions.
  /// This uses collaborative filtering based on purchase patterns.
  Future<List<Product>> _getCachedSimilarity(String productId, int topN) async {
    try {
      final doc = await _firestore
          .collection('product_similarity')
          .doc(productId)
          .get();

      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      final similarItems =
          List<Map<String, dynamic>>.from(data['similar'] ?? []);

      // Sort by score (highest first) and take top N
      similarItems.sort((a, b) =>
          ((b['score'] ?? 0) as num).compareTo((a['score'] ?? 0) as num));

      final similarIds = similarItems
          .take(topN)
          .map((item) => item['productId'] as String)
          .toList();

      return _resolveProductIds(similarIds, topN);
    } catch (e) {
      return [];
    }
  }

  /// Convert product IDs to Product objects
  List<Product> _resolveProductIds(List<String> ids, int topN) {
    final List<Product> results = [];

    for (final id in ids) {
      if (results.length >= topN) break;

      try {
        final product = _db.productList.firstWhere(
          (p) => p.productID == id,
          orElse: () => _db.fullProductList.firstWhere(
            (p) => p.productID == id,
            orElse: () => throw Exception('Not found'),
          ),
        );
        results.add(product);
      } catch (e) {
        // Product not found, skip
      }
    }

    return results;
  }

  // ==========================================================================
  // TIER 3: CONTENT-BASED SIMILARITY (Rule-Based)
  // ==========================================================================

  /// Get similar products based on product specifications.
  /// This is the fallback when ML/cached data is not available.
  List<Product> getContentBasedSimilarProducts(
    Product product, {
    int topN = 10,
    bool excludeOutOfStock = false,
  }) {
    if (product.productID == null) return [];

    // Get candidates from same category
    List<Product> candidates = getProductsWithCategory(product.category)
        .where((p) => p.productID != product.productID)
        .where((p) =>
            p.status == ProductStatusEnum.active ||
            (!excludeOutOfStock && p.status == ProductStatusEnum.outOfStock))
        .toList();

    if (candidates.isEmpty) return [];

    // Calculate similarity scores
    final scoredCandidates = candidates.map((candidate) {
      final score = _getProductSimilarity(product, candidate);
      return _SimilarityResult(product: candidate, score: score);
    }).toList();

    // Sort by similarity score (highest first)
    scoredCandidates.sort((a, b) => b.score.compareTo(a.score));

    // Return top N
    return scoredCandidates.take(topN).map((r) => r.product).toList();
  }

  /// Calculate similarity score between two products (0.0 to 1.0).
  /// Higher score means more similar.
  double _getProductSimilarity(Product a, Product b) {
    // Must be same category
    if (a.category != b.category) return 0.0;

    // Calculate category-specific similarity
    double specScore = 0.0;
    switch (a.category) {
      case CategoryEnum.cpu:
        specScore = _getCPUSimilarity(a as CPU, b as CPU);
        break;
      case CategoryEnum.gpu:
        specScore = _getGPUSimilarity(a as GPU, b as GPU);
        break;
      case CategoryEnum.ram:
        specScore = _getRAMSimilarity(a as RAM, b as RAM);
        break;
      case CategoryEnum.psu:
        specScore = _getPSUSimilarity(a as PSU, b as PSU);
        break;
      case CategoryEnum.mainboard:
        specScore = _getMainboardSimilarity(a as Mainboard, b as Mainboard);
        break;
      case CategoryEnum.drive:
        specScore = _getDriveSimilarity(a as Drive, b as Drive);
        break;
      default:
        return 0.0;
    }

    // Add price similarity (20% weight)
    final priceScore =
        _getPriceSimilarity(a.discountedPrice, b.discountedPrice);

    // Add manufacturer bonus (10% weight)
    final manufacturerScore =
        a.manufacturer.manufacturerID == b.manufacturer.manufacturerID
            ? 1.0
            : 0.0;

    // Weighted combination
    return (specScore * 0.7) + (priceScore * 0.2) + (manufacturerScore * 0.1);
  }

  /// CPU similarity: socket > series > cores > TDP > clock
  double _getCPUSimilarity(CPU a, CPU b) {
    double score = 0.0;

    // Socket compatibility (40%) - critical for replacement
    if (a.socket == b.socket) score += 0.4;

    // Same series (25%)
    if (a.series == b.series) score += 0.25;

    // Similar core count (15%) - within 50%
    final coreDiff = (a.core - b.core).abs() / max(a.core, 1);
    if (coreDiff <= 0.5) score += 0.15 * (1 - coreDiff);

    // Similar TDP (10%) - within 30W
    final tdpDiff = (a.tdp - b.tdp).abs();
    if (tdpDiff <= 30) score += 0.1 * (1 - tdpDiff / 30);

    // Similar clock speed (10%) - within 20%
    final clockDiff = (a.baseClock - b.baseClock).abs() / max(a.baseClock, 0.1);
    if (clockDiff <= 0.2) score += 0.1 * (1 - clockDiff / 0.2);

    return score;
  }

  /// GPU similarity: series > version > VRAM > TDP > clock
  double _getGPUSimilarity(GPU a, GPU b) {
    double score = 0.0;

    // Same series (35%)
    if (a.series == b.series) score += 0.35;

    // Same version tier (25%)
    if (a.version == b.version) score += 0.25;

    // Similar VRAM (20%) - within 4GB
    final vramDiff = (a.memory - b.memory).abs();
    if (vramDiff <= 4) score += 0.2 * (1 - vramDiff / 4);

    // Similar TDP (10%) - within 50W
    final tdpDiff = (a.tdp - b.tdp).abs();
    if (tdpDiff <= 50) score += 0.1 * (1 - tdpDiff / 50);

    // Similar boost clock (10%) - within 15%
    final clockDiff =
        (a.boostClock - b.boostClock).abs() / max(a.boostClock, 0.1);
    if (clockDiff <= 0.15) score += 0.1 * (1 - clockDiff / 0.15);

    return score;
  }

  /// RAM similarity: type > capacity > bus > kit count > latency
  double _getRAMSimilarity(RAM a, RAM b) {
    double score = 0.0;

    // Same RAM type (40%) - critical for compatibility
    if (a.type == b.type) score += 0.4;

    // Same capacity per stick (25%)
    if (a.capacityPerStickGb == b.capacityPerStickGb) score += 0.25;

    // Similar bus speed (20%) - within 800 MHz
    final busDiff = (a.bus - b.bus).abs();
    if (busDiff <= 800) score += 0.2 * (1 - busDiff / 800);

    // Same kit stick count (10%)
    if (a.kitStickCount == b.kitStickCount) score += 0.1;

    // Similar CL latency (5%) - within 4
    final clDiff = (a.clLatency - b.clLatency).abs();
    if (clDiff <= 4) score += 0.05 * (1 - clDiff / 4);

    return score;
  }

  /// PSU similarity: wattage > efficiency > modularity > brand
  double _getPSUSimilarity(PSU a, PSU b) {
    double score = 0.0;

    // Similar wattage (40%) - within 150W
    final wattageDiff = (a.maxWattage - b.maxWattage).abs();
    if (wattageDiff <= 150) score += 0.4 * (1 - wattageDiff / 150);

    // Same efficiency rating (30%)
    if (a.efficiency == b.efficiency) score += 0.3;

    // Same modularity type (20%)
    if (a.modularity == b.modularity) score += 0.2;

    // Same manufacturer (10%)
    if (a.manufacturer.manufacturerID == b.manufacturer.manufacturerID) {
      score += 0.1;
    }

    return score;
  }

  /// Mainboard similarity: socket > chipset > form factor > RAM support
  double _getMainboardSimilarity(Mainboard a, Mainboard b) {
    double score = 0.0;

    // Same socket (35%) - critical for CPU compatibility
    if (a.socket == b.socket) score += 0.35;

    // Same/similar chipset (25%)
    if (a.chipsetCode == b.chipsetCode) {
      score += 0.25;
    } else if (_isSimilarChipset(a.chipsetCode, b.chipsetCode)) {
      score += 0.15;
    }

    // Same form factor (20%)
    if (a.formFactor == b.formFactor) score += 0.2;

    // Same RAM type support (15%)
    if (a.ramSpec.type == b.ramSpec.type) score += 0.15;

    // Similar M.2 slots (5%)
    final m2Diff = (a.storageSlot.m2Slots - b.storageSlot.m2Slots).abs();
    if (m2Diff <= 1) score += 0.05 * (1 - m2Diff / 2);

    return score;
  }

  /// Check if two chipsets are in the same family
  bool _isSimilarChipset(String a, String b) {
    final aLetters = a.replaceAll(RegExp(r'[0-9]'), '');
    final bLetters = b.replaceAll(RegExp(r'[0-9]'), '');
    return aLetters.toLowerCase() == bLetters.toLowerCase();
  }

  /// Drive similarity: type > interface > form factor > capacity > gen
  double _getDriveSimilarity(Drive a, Drive b) {
    double score = 0.0;

    // Same drive type (30%)
    if (a.driveType == b.driveType) score += 0.3;

    // Same interface type (25%)
    if (a.interfaceType == b.interfaceType) score += 0.25;

    // Same form factor (20%)
    if (a.formFactor == b.formFactor) score += 0.2;

    // Similar capacity (15%) - within 256GB
    final capDiff = (a.memoryGb - b.memoryGb).abs();
    if (capDiff <= 256) score += 0.15 * (1 - capDiff / 256);

    // Same generation (10%)
    if (a.gen == b.gen) score += 0.1;

    return score;
  }

  /// Calculate price similarity (0.0 to 1.0)
  double _getPriceSimilarity(int priceA, int priceB) {
    if (priceA == 0 || priceB == 0) return 0.0;
    final priceDiff = (priceA - priceB).abs() / max(priceA, priceB);
    if (priceDiff > 0.3) return 0.0;
    return 1.0 - (priceDiff / 0.3);
  }

  // ==========================================================================
  // EXISTING COMPATIBILITY-BASED METHODS
  // ==========================================================================

  Product? _getPartFromBuild(List<Product> build, CategoryEnum category) {
    for (final product in build) {
      if (product.category == category) {
        return product;
      }
    }
    return null;
  }

  List<Product> _getAllProducts() {
    return [
      ..._db.cpuList,
      ..._db.gpuList,
      ..._db.mainboardList,
      ..._db.ramList,
      ..._db.psuList,
      ..._db.driveList,
    ];
  }

  List<Product> getRankedCompatiblePartsForSlot(
    List<Product> build,
    CategoryEnum shoppingFor, {
    int topN = 50,
  }) {
    List<Product> candidates = [];

    switch (shoppingFor) {
      case CategoryEnum.cpu:
        candidates = _db.cpuList;
        break;
      case CategoryEnum.mainboard:
        candidates = _db.mainboardList;
        break;
      case CategoryEnum.ram:
        candidates = _db.ramList;
        break;
      case CategoryEnum.gpu:
        candidates = _db.gpuList;
        break;
      case CategoryEnum.psu:
        candidates = _db.psuList;
        break;
      case CategoryEnum.drive:
        candidates = _db.driveList;
        break;
      default:
        return [];
    }

    candidates = candidates
        .where((p) =>
            p.status.getName() == ProductStatusEnum.active.getName() ||
            p.status.getName() == ProductStatusEnum.outOfStock.getName())
        .toList();

    final scoredCandidates = candidates.map((candidate) {
      final score = _getCompatibilityScore(candidate, build);
      return _ScoredCandidate(product: candidate, compatibilityScore: score);
    }).toList();

    return _calculatePriorityRanking(scoredCandidates, topN: topN);
  }

  List<Product> getTrendingProducts({
    int topN = 10,
    CategoryEnum? category,
  }) {
    List<Product> candidates;

    if (category != null) {
      candidates =
          _getAllProducts().where((p) => p.category == category).toList();
    } else {
      candidates = _getAllProducts();
    }

    candidates = candidates
        .where((p) =>
            p.status == ProductStatusEnum.active ||
            p.status == ProductStatusEnum.outOfStock)
        .toList();

    return _calculatePriorityRanking(
      candidates
          .map((p) => _ScoredCandidate(product: p, compatibilityScore: 0))
          .toList(),
      topN: topN,
    );
  }

  List<Product> getRecommendationsForBuild(
    List<Product> build, {
    int topN = 10,
  }) {
    List<_ScoredCandidate> allScoredCandidates = [];

    final cpu = _getPartFromBuild(build, CategoryEnum.cpu) as CPU?;
    final mainboard =
        _getPartFromBuild(build, CategoryEnum.mainboard) as Mainboard?;
    final ram = _getPartFromBuild(build, CategoryEnum.ram) as RAM?;
    final gpu = _getPartFromBuild(build, CategoryEnum.gpu) as GPU?;

    if (cpu == null) {
      for (final candidate in _db.cpuList) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(
            _ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    if (mainboard == null) {
      for (final candidate in _db.mainboardList) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(
            _ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    if (ram == null) {
      for (final candidate in _db.ramList) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(
            _ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    if (_getPartFromBuild(build, CategoryEnum.psu) == null) {
      for (final candidate in _db.psuList) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(
            _ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    if (gpu == null) {
      for (final candidate in _db.gpuList) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(
            _ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    if (_getPartFromBuild(build, CategoryEnum.drive) == null) {
      for (final candidate in _db.driveList) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(
            _ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    return _calculatePriorityRanking(allScoredCandidates, topN: topN);
  }

  List<Product> getCompatibleForProduct(
    Product product, {
    int topN = 10,
  }) {
    List<_ScoredCandidate> allScoredCandidates = [];

    switch (product.category) {
      case CategoryEnum.cpu:
        final cpu = product as CPU;
        final mainboards =
            _db.mainboardList.where((m) => m.socket == cpu.socket).toList();
        for (final item in mainboards) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }

        final requiredWattage = cpu.tdp + 200;
        final psus =
            _db.psuList.where((p) => p.maxWattage >= requiredWattage).toList();
        for (final item in psus) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.mainboard:
        final mainboard = product as Mainboard;
        final cpus =
            _db.cpuList.where((c) => c.socket == mainboard.socket).toList();
        for (final item in cpus) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }

        final rams =
            _db.ramList.where((r) => r.type == mainboard.ramSpec.type).toList();
        for (final item in rams) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }

        if (mainboard.storageSlot.m2Slots > 0) {
          final m2drives = _db.driveList
              .where((d) => d.formFactor.name.startsWith('m2'))
              .toList();
          for (final item in m2drives) {
            allScoredCandidates
                .add(_ScoredCandidate(product: item, compatibilityScore: 1));
          }
        }
        if (mainboard.storageSlot.sataPorts > 0) {
          final sataDrives = _db.driveList
              .where((d) => d.interfaceType.name == 'sata')
              .toList();
          for (final item in sataDrives) {
            allScoredCandidates
                .add(_ScoredCandidate(product: item, compatibilityScore: 1));
          }
        }
        break;

      case CategoryEnum.gpu:
        final gpu = product as GPU;
        final requiredWattage = gpu.tdp + 200;
        final psus =
            _db.psuList.where((p) => p.maxWattage >= requiredWattage).toList();
        for (final item in psus) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.ram:
        final ram = product as RAM;
        final mainboards =
            _db.mainboardList.where((m) => m.ramSpec.type == ram.type).toList();
        for (final item in mainboards) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.psu:
        final psu = product as PSU;
        final gpus =
            _db.gpuList.where((g) => g.tdp < (psu.maxWattage - 200)).toList();
        for (final item in gpus) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        final cpus =
            _db.cpuList.where((c) => c.tdp < (psu.maxWattage - 200)).toList();
        for (final item in cpus) {
          allScoredCandidates
              .add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.drive:
        final drive = product as Drive;
        if (drive.formFactor.name.startsWith('m2')) {
          final m2boards = _db.mainboardList
              .where((m) => m.storageSlot.m2Slots > 0)
              .toList();
          for (final item in m2boards) {
            allScoredCandidates
                .add(_ScoredCandidate(product: item, compatibilityScore: 1));
          }
        } else if (drive.interfaceType.name == 'sata') {
          final sataBoards = _db.mainboardList
              .where((m) => m.storageSlot.sataPorts > 0)
              .toList();
          for (final item in sataBoards) {
            allScoredCandidates
                .add(_ScoredCandidate(product: item, compatibilityScore: 1));
          }
        }
        break;

      default:
        break;
    }

    return _calculatePriorityRanking(allScoredCandidates, topN: topN);
  }

  int _getCompatibilityScore(Product candidate, List<Product> build) {
    int score = 0;

    final cpu = _getPartFromBuild(build, CategoryEnum.cpu) as CPU?;
    final mainboard =
        _getPartFromBuild(build, CategoryEnum.mainboard) as Mainboard?;
    final ram = _getPartFromBuild(build, CategoryEnum.ram) as RAM?;
    final gpu = _getPartFromBuild(build, CategoryEnum.gpu) as GPU?;

    switch (candidate.category) {
      case CategoryEnum.cpu:
        final cpuCandidate = candidate as CPU;
        if (mainboard != null && cpuCandidate.socket == mainboard.socket) {
          score++;
        }
        break;

      case CategoryEnum.mainboard:
        final mbCandidate = candidate as Mainboard;
        if (cpu != null && mbCandidate.socket == cpu.socket) {
          score++;
        }
        if (ram != null && mbCandidate.ramSpec.type == ram.type) {
          score++;
        }
        for (final product in build) {
          if (product.category == CategoryEnum.drive) {
            final drive = product as Drive;
            if (drive.formFactor.name.startsWith('m2') &&
                mbCandidate.storageSlot.m2Slots > 0) {
              score++;
            } else if (drive.interfaceType.name == 'sata' &&
                mbCandidate.storageSlot.sataPorts > 0) {
              score++;
            }
          }
        }
        break;

      case CategoryEnum.ram:
        final ramCandidate = candidate as RAM;
        if (mainboard != null && ramCandidate.type == mainboard.ramSpec.type) {
          score++;
        }
        break;

      case CategoryEnum.psu:
        final psuCandidate = candidate as PSU;
        num totalTdp = 0;
        if (cpu != null) totalTdp += cpu.tdp;
        if (gpu != null) totalTdp += gpu.tdp;
        final requiredWattage = totalTdp + 200;

        if (psuCandidate.maxWattage >= requiredWattage) {
          score++;
        }
        break;

      case CategoryEnum.gpu:
        final psu = _getPartFromBuild(build, CategoryEnum.psu) as PSU?;
        if (psu != null) {
          final gpuCandidate = candidate as GPU;
          num totalTdp = gpuCandidate.tdp;
          if (cpu != null) totalTdp += cpu.tdp;

          if (psu.maxWattage >= totalTdp + 200) {
            score++;
          }
        } else {
          score++;
        }
        break;

      case CategoryEnum.drive:
        final driveCandidate = candidate as Drive;
        if (mainboard != null) {
          if (driveCandidate.formFactor.name.startsWith('m2') &&
              mainboard.storageSlot.m2Slots > 0) {
            score++;
          } else if (driveCandidate.interfaceType.name == 'sata' &&
              mainboard.storageSlot.sataPorts > 0) {
            score++;
          }
        } else {
          score++;
        }
        break;

      case CategoryEnum.empty:
        break;
    }

    return score;
  }

  List<Product> _calculatePriorityRanking(
    List<_ScoredCandidate> scoredCandidates, {
    int topN = 10,
  }) {
    if (scoredCandidates.isEmpty) {
      return [];
    }

    final nowInSeconds = DateTime.now().millisecondsSinceEpoch / 1000;

    double minPrice = double.infinity, maxPrice = double.negativeInfinity;
    double minPop = double.infinity, maxPop = double.negativeInfinity;
    double minRecency = double.infinity, maxRecency = double.negativeInfinity;

    List<_RankedProduct> tempProducts = [];

    for (var candidate in scoredCandidates) {
      final product = candidate.product;
      final ageInDays = max(
          1,
          (nowInSeconds - product.release.millisecondsSinceEpoch / 1000) /
              (60 * 60 * 24));

      final salesVelocity = product.sales / ageInDays;
      final popularityScore = log(salesVelocity + 1);

      const halfLifeDays = 180;
      final recencyScore = exp(-ageInDays / halfLifeDays);

      final priceScore = log(product.discountedPrice + 1);

      if (priceScore < minPrice) minPrice = priceScore;
      if (priceScore > maxPrice) maxPrice = priceScore;
      if (popularityScore < minPop) minPop = popularityScore;
      if (popularityScore > maxPop) maxPop = popularityScore;
      if (recencyScore < minRecency) minRecency = recencyScore;
      if (recencyScore > maxRecency) maxRecency = recencyScore;

      tempProducts.add(_RankedProduct(
        product: product,
        compatibilityScore: candidate.compatibilityScore,
        price: priceScore,
        popularity: popularityScore,
        recency: recencyScore,
      ));
    }

    for (var temp in tempProducts) {
      final normPrice = (maxPrice - minPrice) > 0
          ? (temp.price - minPrice) / (maxPrice - minPrice)
          : 0;
      final normPop = (maxPop - minPop) > 0
          ? (temp.popularity - minPop) / (maxPop - minPop)
          : 0;
      final normRecency = (maxRecency - minRecency) > 0
          ? (temp.recency - minRecency) / (maxRecency - minRecency)
          : 0;

      final marketScore = (_weights['PRICE']! * normPrice) +
          (_weights['RECENCY']! * normRecency) +
          (_weights['POPULARITY']! * normPop);

      final finalScore = (temp.compatibilityScore * 10) + marketScore;

      temp.product.priorityScore = finalScore;
    }

    tempProducts.sort(
        (a, b) => b.product.priorityScore.compareTo(a.product.priorityScore));

    return tempProducts.map((temp) => temp.product).take(topN).toList();
  }
}

// Helper classes
class _RankedProduct {
  final Product product;
  final int compatibilityScore;
  final double price;
  final double popularity;
  final double recency;

  _RankedProduct({
    required this.product,
    required this.compatibilityScore,
    required this.price,
    required this.popularity,
    required this.recency,
  });
}

class _ScoredCandidate {
  final Product product;
  final int compatibilityScore;

  _ScoredCandidate({
    required this.product,
    required this.compatibilityScore,
  });
}

class _SimilarityResult {
  final Product product;
  final double score;

  _SimilarityResult({
    required this.product,
    required this.score,
  });
}

List<Product> getProductsWithCategory(CategoryEnum category) {
  switch (category) {
    case CategoryEnum.cpu:
      return Database().cpuList;
    case CategoryEnum.gpu:
      return Database().gpuList;
    case CategoryEnum.mainboard:
      return Database().mainboardList;
    case CategoryEnum.ram:
      return Database().ramList;
    case CategoryEnum.psu:
      return Database().psuList;
    case CategoryEnum.drive:
      return Database().driveList;
    case CategoryEnum.empty:
      return [];
  }
}
