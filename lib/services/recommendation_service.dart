import 'dart:math';
import 'package:gizmoglobe_client/data/database/database.dart';

import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/product_status.dart';

import 'package:gizmoglobe_client/objects/product_related/gpu_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/drive_related/drive.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard_related/mainboard.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/psu_related/psu.dart';
import 'package:gizmoglobe_client/objects/product_related/ram_related/ram.dart';

class RecommendationService {
  final Database _db = Database();

  static const Map<String, double> _weights = {
    'PRICE': 0.3,
    'RECENCY': 0.4,
    'POPULARITY': 0.3,
  };

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

    candidates = candidates.where((p) => p.status.getName() == ProductStatusEnum.active.getName() ||
        p.status.getName() == ProductStatusEnum.outOfStock.getName())
        .toList();

    final scoredCandidates = candidates.map((candidate) {
      final score = _getCompatibilityScore(candidate, build);
      return _ScoredCandidate(product: candidate, compatibilityScore: score);
    }).toList();

    // 3. Rank the list and return
    // The ranking function will prioritize compatibility
    return _calculatePriorityRanking(scoredCandidates, topN: topN);
  }

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
        p.status == ProductStatusEnum.outOfStock)
        .toList();

    return _calculatePriorityRanking(
      candidates.map((p) => _ScoredCandidate(product: p, compatibilityScore: 0)).toList(),
      topN: topN,
    );
  }

  List<Product> getRecommendationsForBuild(
      List<Product> build, {
        int topN = 10,
      }) {
    List<_ScoredCandidate> allScoredCandidates = [];

    final cpu = _getPartFromBuild(build, CategoryEnum.cpu) as CPU?;
    final mainboard = _getPartFromBuild(build, CategoryEnum.mainboard) as Mainboard?;
    final ram = _getPartFromBuild(build, CategoryEnum.ram) as RAM?;
    final gpu = _getPartFromBuild(build, CategoryEnum.gpu) as GPU?;

    // Check for CPU
    if (cpu == null) {
      final candidates = _db.cpuList;
      for (final candidate in candidates) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(_ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    // Check for Mainboard
    if (mainboard == null) {
      final candidates = _db.mainboardList;
      for (final candidate in candidates) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(_ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    // Check for RAM
    if (ram == null) {
      final candidates = _db.ramList;
      for (final candidate in candidates) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(_ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    // Check for PSU
    if (_getPartFromBuild(build, CategoryEnum.psu) == null) {
      final candidates = _db.psuList;
      for (final candidate in candidates) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(_ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    // Check for GPU
    if (gpu == null) {
      final candidates = _db.gpuList;
      for (final candidate in candidates) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(_ScoredCandidate(product: candidate, compatibilityScore: score));
      }
    }

    // Check for Drive
    if (_getPartFromBuild(build, CategoryEnum.drive) == null) {
      final candidates = _db.driveList;
      for (final candidate in candidates) {
        final score = _getCompatibilityScore(candidate, build);
        allScoredCandidates.add(_ScoredCandidate(product: candidate, compatibilityScore: score));
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
        final mainboards = _db.mainboardList.where((m) => m.socket == cpu.socket).toList();
        for (final item in mainboards) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }

        final requiredWattage = cpu.tdp + 200; // 200W headroom
        final psus = _db.psuList.where((p) => p.maxWattage >= requiredWattage).toList();
        for (final item in psus) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.mainboard:
        final mainboard = product as Mainboard;
        final cpus = _db.cpuList.where((c) => c.socket == mainboard.socket).toList();
        for (final item in cpus) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }

        final rams = _db.ramList.where((r) => r.type == mainboard.ramSpec.type).toList();
        for (final item in rams) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }

        if (mainboard.storageSlot.m2Slots > 0) {
          final m2drives = _db.driveList.where((d) => d.formFactor.name.startsWith('m2')).toList();
          for (final item in m2drives) {
            allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
          }
        }
        if (mainboard.storageSlot.sataPorts > 0) {
          final sataDrives = _db.driveList.where((d) => d.interfaceType.name == 'sata').toList();
          for (final item in sataDrives) {
            allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
          }
        }
        break;

      case CategoryEnum.gpu:
        final gpu = product as GPU;
        final requiredWattage = gpu.tdp + 200; // 200W headroom
        final psus = _db.psuList.where((p) => p.maxWattage >= requiredWattage).toList();
        for (final item in psus) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.ram:
        final ram = product as RAM;
        final mainboards = _db.mainboardList.where((m) => m.ramSpec.type == ram.type).toList();
        for (final item in mainboards) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.psu:
        final psu = product as PSU;
        final gpus = _db.gpuList.where((g) => g.tdp < (psu.maxWattage - 200)).toList();
        for (final item in gpus) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        final cpus = _db.cpuList.where((c) => c.tdp < (psu.maxWattage - 200)).toList();
        for (final item in cpus) {
          allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
        }
        break;

      case CategoryEnum.drive:
        final drive = product as Drive;
        if (drive.formFactor.name.startsWith('m2')) {
          final m2boards = _db.mainboardList.where((m) => m.storageSlot.m2Slots > 0).toList();
          for (final item in m2boards) {
            allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
          }
        } else if (drive.interfaceType.name == 'sata') {
          final sataBoards = _db.mainboardList.where((m) => m.storageSlot.sataPorts > 0).toList();
          for (final item in sataBoards) {
            allScoredCandidates.add(_ScoredCandidate(product: item, compatibilityScore: 1));
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

    // Get the main parts from the build
    final cpu = _getPartFromBuild(build, CategoryEnum.cpu) as CPU?;
    final mainboard = _getPartFromBuild(build, CategoryEnum.mainboard) as Mainboard?;
    final ram = _getPartFromBuild(build, CategoryEnum.ram) as RAM?;
    final gpu = _getPartFromBuild(build, CategoryEnum.gpu) as GPU?;

    // Check candidate against the build
    switch (candidate.category) {
      case CategoryEnum.cpu:
        final cpuCandidate = candidate as CPU;
        // Check against mainboard
        if (mainboard != null && cpuCandidate.socket == mainboard.socket) {
          score++;
        }
        // Check against PSU (is wattage sufficient?) - omitted here
        break;

      case CategoryEnum.mainboard:
        final mbCandidate = candidate as Mainboard;
        // Check against CPU
        if (cpu != null && mbCandidate.socket == cpu.socket) {
          score++;
        }
        // Check against RAM
        if (ram != null && mbCandidate.ramSpec.type == ram.type) {
          score++;
        }
        // Check against Drives
        for (final product in build) {
          if (product.category == CategoryEnum.drive) {
            final drive = product as Drive;
            if (drive.formFactor.name.startsWith('m2') && mbCandidate.storageSlot.m2Slots > 0) {
              score++;
            } else if (drive.interfaceType.name == 'sata' && mbCandidate.storageSlot.sataPorts > 0) {
              score++;
            }
          }
        }
        break;

      case CategoryEnum.ram:
        final ramCandidate = candidate as RAM;
        // Check against Mainboard
        if (mainboard != null && ramCandidate.type == mainboard.ramSpec.type) {
          score++;
        }
        break;

      case CategoryEnum.psu:
        final psuCandidate = candidate as PSU;
        // Check if PSU is powerful enough for the build
        num totalTdp = 0;
        if (cpu != null) totalTdp += cpu.tdp;
        if (gpu != null) totalTdp += gpu.tdp;
        final requiredWattage = totalTdp + 200; // 200W headroom

        if (psuCandidate.maxWattage >= requiredWattage) {
          score++;
        }
        break;

      case CategoryEnum.gpu:
      // Check if PSU is powerful enough for this GPU
        final psu = _getPartFromBuild(build, CategoryEnum.psu) as PSU?;
        if (psu != null) {
          final gpuCandidate = candidate as GPU;
          num totalTdp = gpuCandidate.tdp;
          if (cpu != null) totalTdp += cpu.tdp;

          if (psu.maxWattage >= totalTdp + 200) {
            score++;
          }
        } else {
          // No PSU, so it's a "neutral" match
          score++;
        }
        break;

      case CategoryEnum.drive:
        final driveCandidate = candidate as Drive;
        // Check if Mainboard has the right slots
        if (mainboard != null) {
          if (driveCandidate.formFactor.name.startsWith('m2') && mainboard.storageSlot.m2Slots > 0) {
            score++;
          } else if (driveCandidate.interfaceType.name == 'sata' && mainboard.storageSlot.sataPorts > 0) {
            score++;
          }
        } else {
          // No mainboard, so it's a "neutral" match
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
      final ageInDays = max(1, (nowInSeconds - product.release.millisecondsSinceEpoch / 1000) / (60 * 60 * 24));

      final salesVelocity = product.sales / ageInDays;
      final popularityScore = log(salesVelocity + 1);

      const halfLifeDays = 180;
      final recencyScore = exp(-ageInDays / halfLifeDays);

      final priceScore = log(product.discountedPrice + 1);

      // Find min/max for normalization
      if (priceScore < minPrice) minPrice = priceScore;
      if (priceScore > maxPrice) maxPrice = priceScore;
      if (popularityScore < minPop) minPop = popularityScore;
      if (popularityScore > maxPop) maxPop = popularityScore;
      if (recencyScore < minRecency) minRecency = recencyScore;
      if (recencyScore > maxRecency) maxRecency = recencyScore;

      tempProducts.add(_RankedProduct(
        product: product,
        compatibilityScore: candidate.compatibilityScore, // Store the new score
        price: priceScore,
        popularity: popularityScore,
        recency: recencyScore,
      ));
    }

    for (var temp in tempProducts) {
      // Normalize the "market" scores
      final normPrice = (maxPrice - minPrice) > 0 ? (temp.price - minPrice) / (maxPrice - minPrice) : 0;
      final normPop = (maxPop - minPop) > 0 ? (temp.popularity - minPop) / (maxPop - minPop) : 0;
      final normRecency = (maxRecency - minRecency) > 0 ? (temp.recency - minRecency) / (maxRecency - minRecency) : 0;

      final marketScore =
          (_weights['PRICE']! * normPrice) +
              (_weights['RECENCY']! * normRecency) +
              (_weights['POPULARITY']! * normPop);

      final finalScore = (temp.compatibilityScore * 10) + marketScore;

      temp.product.priorityScore = finalScore;
    }

    tempProducts.sort((a, b) => b.product.priorityScore.compareTo(a.product.priorityScore));

    return tempProducts.map((temp) => temp.product).take(topN).toList();
  }
}

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
