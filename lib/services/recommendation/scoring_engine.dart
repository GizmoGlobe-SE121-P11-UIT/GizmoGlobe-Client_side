import 'dart:math';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/gpu_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/services/recommendation/user_profile.dart';

class ScoringEngine {

  static double estimatePerformance(Product p) {
    if (p is CPU) {
      return (p.core * 0.6) + (p.turboClock * 0.4);
    } else if (p is GPU) {
      return (p.memory * 0.7) + (p.boostClock * 0.3);
    }
    return 1.0; // Default for other components
  }

  static double logPriceScore(int price) {
    if (price <= 0) return 0;
    // Inverse log score: Lower price = Higher score
    return 1.0 / (log(price) / ln10);
  }

  static double calculateRecencyScore(DateTime? releaseDate) {
    if (releaseDate == null) return 0.5;
    final monthsOld = DateTime.now().difference(releaseDate).inDays / 30;
    if (monthsOld < 1) return 1.0;
    return 1.0 / log(monthsOld + exp(1));
  }

  /// Calculates a score multiplier (default 1.0) based on the user's survey profile.
  /// A higher score means the product is more relevant to the user's needs.
  static double getProfileRelevanceScore(Product product, UserProfile? profile) {
    if (profile == null) return 1.0;

    double score = 1.0;

    // 1. Purpose Analysis
    final purposes = profile.usage;
    for (final purpose in purposes) {
      final pStr = purpose.toLowerCase();

      // Gaming
      if (pStr.contains('chơi game') || pStr.contains('game')) {
        if (_isGamingProduct(product)) score += 0.4;
      }

      // Graphic Design / Multimedia
      if (pStr.contains('thiết kế') || pStr.contains('đồ họa') || pStr.contains('multimedia')) {
        if (_isPerformanceProduct(product)) score += 0.4;
      }

      // Programming / Engineering
      if (pStr.contains('lập trình') || pStr.contains('kỹ thuật')) {
        // Boost CPU, RAM, Keyboards
        if (product.category == CategoryEnum.cpu ||
            product.category == CategoryEnum.ram) {
          score += 0.2;
        }
      }

      // Office / Study
      if (pStr.contains('văn phòng') || pStr.contains('học tập')) {
        // Slight boost to budget-friendly items, maybe penalize extreme high-end
        if (product.price < 15000000) score += 0.1;
      }
    }

    // 2. Budget Analysis (Heuristic)
    // Already handled by budgetLimit in UserProfile, but we can add extra logic here if needed
    // For now, we rely on the budget filter in RecommendationService

    return score;
  }

  static bool _isGamingProduct(Product product) {
    final name = product.productName.toLowerCase();
    return name.contains('gaming') ||
        name.contains('rtx') ||
        name.contains('gtx') ||
        name.contains('radeon') ||
        product.category == CategoryEnum.gpu;
  }

  static bool _isPerformanceProduct(Product product) {
    final name = product.productName.toLowerCase();
    return name.contains('pro') ||
        name.contains('workstation') ||
        name.contains('creator') ||
        name.contains('quadro') ||
        name.contains('studio') ||
        (product.category == CategoryEnum.ram && (product.price > 2000000));
  }
}
