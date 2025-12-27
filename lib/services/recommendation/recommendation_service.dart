import 'dart:math';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'find_compatible.dart';
import 'scoring_engine.dart';
import 'user_profile.dart';

class RecommendationService {
  final Database _db = Database();
  UserProfile _userProfile = UserProfile();

  RecommendationService({UserProfile? userProfile}) {
    if (userProfile != null) {
      _userProfile = userProfile;
    } else {
      final rawProfile = Database().userSurveyProfile;
      if (rawProfile != null) {
        _userProfile = UserProfile.fromMap(rawProfile);
      }
    }
  }

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
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

  /// Adapter method for Product Detail View
  /// Finds compatible parts for a single product using the new logic
  List<Product> getCompatibleForProduct(Product target, {int topN = 10}) {
    List<Product> recommendations = [];
    List<CategoryEnum> categoriesToCheck = [];

    // Determine logical complementary parts
    switch (target.category) {
      case CategoryEnum.cpu:
        categoriesToCheck = [CategoryEnum.mainboard];
        break;
      case CategoryEnum.mainboard:
        categoriesToCheck = [CategoryEnum.cpu, CategoryEnum.ram, CategoryEnum.gpu, CategoryEnum.drive];
        break;
      case CategoryEnum.ram:
      case CategoryEnum.gpu:
      case CategoryEnum.drive:
        categoriesToCheck = [CategoryEnum.mainboard];
        break;
      default:
        break;
    }

    // Fetch ranked parts for each category
    // We treat the single target product as a "build" of size 1
    for (var category in categoriesToCheck) {
      recommendations.addAll(
          getRankedCompatiblePartsForSlot([target], category, topN: 5)
      );
    }

    // Sort combined results by the calculated score using weights
    return _applyWeightsAndSort(recommendations, topN: topN);
  }

  /// Main method to get ranked parts for a specific slot in a build
  List<Product> getRankedCompatiblePartsForSlot(
      List<Product> build,
      CategoryEnum shoppingFor, {
        int topN = 50,
      }) {
    List<Product> candidates = [];

    // 1. Select Candidate Pool
    switch (shoppingFor) {
      case CategoryEnum.cpu: candidates = _db.cpuList; break;
      case CategoryEnum.mainboard: candidates = _db.mainboardList; break;
      case CategoryEnum.ram: candidates = _db.ramList; break;
      case CategoryEnum.gpu: candidates = _db.gpuList; break;
      case CategoryEnum.psu: candidates = _db.psuList; break;
      case CategoryEnum.drive: candidates = _db.driveList; break;
      default: return [];
    }

    // 2. Filter by Status and Budget
    candidates = candidates.where((p) {
      final isActive = p.status == ProductStatusEnum.active || p.status == ProductStatusEnum.outOfStock;
      final withinBudget = p.discountedPrice <= _userProfile.budgetLimit;
      return isActive && withinBudget;
    }).toList();

    // 3. Filter by Compatibility (Strict)
    // Using the logic from find_compatible.dart
    List<Product> compatibleCandidates = candidates.where((candidate) {
      // Must be compatible with EVERY part currently in the build
      return build.every((existingPart) => areProductsCompatible(existingPart, candidate));
    }).toList();

    // Fallback: If strict compatibility yields no results (likely due to conflicts in the build),
    // try to find parts compatible with the "core" component (Mainboard > CPU > GPU).
    if (compatibleCandidates.isEmpty && build.isNotEmpty) {
      // Find a "pivot" product to base recommendations on
      Product? pivot;
      try {
        pivot = build.firstWhere((p) => p.category == CategoryEnum.mainboard);
      } catch (_) {
        try {
          pivot = build.firstWhere((p) => p.category == CategoryEnum.cpu);
        } catch (_) {
          try {
            pivot = build.firstWhere((p) => p.category == CategoryEnum.gpu);
          } catch (_) {
            pivot = build.first;
          }
        }
      }

      compatibleCandidates = candidates.where((candidate) {
        return areProductsCompatible(pivot!, candidate);
      }).toList();
    }

    // 4. Rank Candidates using weights
    return _applyWeightsAndSort(compatibleCandidates, topN: topN);
  }

  /// Get general trending products (optionally filtered by category)
  List<Product> getTrendingProducts({
    int topN = 10,
    CategoryEnum? category,
  }) {
    List<Product> candidates;

    if (category != null) {
      candidates = _getAllProducts().where((p) => p.category == category).toList();
    } else {
      candidates = _getAllProducts();
    }

    candidates = candidates.where((p) =>
    p.status == ProductStatusEnum.active ||
        p.status == ProductStatusEnum.outOfStock).toList();

    return _applyWeightsAndSort(candidates, topN: topN);
  }

  /// Suggests parts for missing slots in a build
  List<Product> getRecommendationsForBuild(
      List<Product> build, {
        int topN = 10,
      }) {
    List<Product> allRecommendations = [];

    // Identify missing categories
    final hasCpu = build.any((p) => p.category == CategoryEnum.cpu);
    final hasGpu = build.any((p) => p.category == CategoryEnum.gpu);
    final hasMb = build.any((p) => p.category == CategoryEnum.mainboard);
    final hasRam = build.any((p) => p.category == CategoryEnum.ram);

    if (!hasCpu) allRecommendations.addAll(getRankedCompatiblePartsForSlot(build, CategoryEnum.cpu, topN: 1000));
    if (!hasMb) allRecommendations.addAll(getRankedCompatiblePartsForSlot(build, CategoryEnum.mainboard, topN: 1000));
    if (!hasRam) allRecommendations.addAll(getRankedCompatiblePartsForSlot(build, CategoryEnum.ram, topN: 1000));
    if (!hasGpu) allRecommendations.addAll(getRankedCompatiblePartsForSlot(build, CategoryEnum.gpu, topN: 1000));

    // Sort combined list by score using weights
    return _applyWeightsAndSort(allRecommendations, topN: topN);
  }

  List<Product> _applyWeightsAndSort(List<Product> candidates, {int topN = 10}) {
    if (candidates.isEmpty) return [];

    final weights = _userProfile.getWeights();
    final favoriteIds = _db.favoriteProducts.map((e) => e.productID).toSet();

    // Calculate scores
    for (var p in candidates) {
      double perf = ScoringEngine.estimatePerformance(p);
      double price = ScoringEngine.logPriceScore(p.discountedPrice);

      DateTime releaseDate = DateTime.fromMillisecondsSinceEpoch(p.release.millisecondsSinceEpoch);
      double recency = ScoringEngine.calculateRecencyScore(releaseDate);

      double pop = log(p.sales + 1);

      // Base score
      double baseScore = (perf * weights['PERF']!) +
          (price * weights['PRICE']!) +
          (recency * weights['RECENCY']!) +
          (pop * weights['POP']!);

      // Apply profile relevance multiplier
      double relevanceMultiplier = ScoringEngine.getProfileRelevanceScore(p, _userProfile);

      if (favoriteIds.contains(p.productID)) {
        relevanceMultiplier += 0.5;
      }

      p.priorityScore = baseScore * relevanceMultiplier;
    }

    // Sort descending
    candidates.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    return candidates.take(topN).toList();
  }
}
