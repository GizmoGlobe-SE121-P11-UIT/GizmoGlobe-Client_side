import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/product_related/gpu_related/gpu.dart';

import '../enums/product_related/category_enum.dart';
import '../objects/product_related/cpu_related/cpu.dart';
import '../objects/product_related/drive_related/drive.dart';
import '../objects/product_related/mainboard_related/mainboard.dart';
import '../objects/product_related/product.dart';
import '../objects/product_related/psu_related/psu.dart';
import '../objects/product_related/ram_related/ram.dart';

class RecommendationService {
  static const Map<String, double> _weights = {
    'PRICE': 0.4,
    'RECENCY': 0.35,
    'POPULARITY': 0.25,
  };

  /// This is the main function you will call from your app's UI
  /// It finds a ranked list of compatible products for a given slot.
  List<Product> getCompatibleParts(
      Product product,
      {int topN = 10}
  ) {
    List<Product> allCandidates = [];

    //
    // --- STAGE 1: GATHER ALL COMPATIBLE CANDIDATES BASED ON THE INPUT PRODUCT'S CATEGORY ---
    //
    switch (product.category) {
      case CategoryEnum.cpu:
        final cpu = product as CPU;
        // Find compatible Mainboards
        final mainboards = getProductsWithCategory(CategoryEnum.mainboard).where((m) => (m as Mainboard).socket == cpu.socket).toList();
        allCandidates.addAll(mainboards);

        // Find compatible PSUs
        final requiredWattage = (cpu.tdp + 200) * 1.15;
        final psus = getProductsWithCategory(CategoryEnum.psu).where((p) => (p as PSU).maxWattage >= requiredWattage).toList();
        allCandidates.addAll(psus);
        break;

      case CategoryEnum.mainboard:
        final mainboard = product as Mainboard;
        final cpus = getProductsWithCategory(CategoryEnum.cpu).where((c) => (c as CPU).socket == mainboard.socket).toList();
        allCandidates.addAll(cpus);

        // Find compatible RAM
        final rams = getProductsWithCategory(CategoryEnum.ram).where((r) => (r as RAM).type == mainboard.ramSpec.type).toList();
        allCandidates.addAll(rams);

        // Find compatible Drives (M.2 and SATA)
        if (mainboard.storageSlot.m2Slots > 0) {
          allCandidates.addAll(getProductsWithCategory(CategoryEnum.drive).where((d) => (d as Drive).formFactor.name.startsWith('m2')));
        }
        if (mainboard.storageSlot.sataPorts > 0) {
          allCandidates.addAll(getProductsWithCategory(CategoryEnum.drive).where((d) => (d as Drive).interfaceType.name == 'sata'));
        }
        break;

      case CategoryEnum.gpu:
        final gpu = product as GPU;
        // Find compatible PSUs
        final requiredWattage = (gpu.tdp + 200) * 1.15;
        final psus = getProductsWithCategory(CategoryEnum.psu).where((p) => (p as PSU).maxWattage >= requiredWattage).toList();
        allCandidates.addAll(psus);
        break;

      case CategoryEnum.ram:
        final ram = product as RAM;
        // Find compatible Mainboards
        final mainboards = getProductsWithCategory(CategoryEnum.mainboard).where((m) => (m as Mainboard).ramSpec.type == ram.type).toList();
        allCandidates.addAll(mainboards);
        break;

      case CategoryEnum.psu:
      // A PSU is compatible with almost anything,
      // but we can recommend parts that "fit" its wattage
        final psu = product as PSU;
        // Find "high-end" GPUs this PSU can power
        // (PSU_WATTAGE - 200W_BUFFER) > GPU_TDP
        final gpus = getProductsWithCategory(CategoryEnum.gpu).where((g) => (g as GPU).tdp < (psu.maxWattage / 1.15 - 200)).toList();
        allCandidates.addAll(gpus);

        // Find "high-end" CPUs this PSU can power
        final cpus = getProductsWithCategory(CategoryEnum.cpu).where((c) => (c as CPU).tdp < (psu.maxWattage / 1.15 - 200)).toList();
        allCandidates.addAll(cpus);
        break;

      case CategoryEnum.drive:
        final drive = product as Drive;
        // Find Mainboards that have the correct slot
        if (drive.formFactor.name.startsWith('m2')) {
          allCandidates.addAll(getProductsWithCategory(CategoryEnum.mainboard).where((m) => (m as Mainboard).storageSlot.m2Slots > 0));
        } else if (drive.interfaceType.name == 'sata') {
          allCandidates.addAll(getProductsWithCategory(CategoryEnum.mainboard).where((m) => (m as Mainboard).storageSlot.sataPorts > 0));
        }
        break;
      case CategoryEnum.empty:
      return [];
    }
    return _calculatePriorityRanking(allCandidates, topN: topN);
  }
  List<Product> _calculatePriorityRanking(List<Product> products, {int topN = 10}) {
    if (products.isEmpty) {
      return [];
    }

    final nowInSeconds = DateTime.now().millisecondsSinceEpoch / 1000;

    double minPrice = double.infinity, maxPrice = double.negativeInfinity;
    double minPop = double.infinity, maxPop = double.negativeInfinity;
    double minRecency = double.infinity, maxRecency = double.negativeInfinity;

    // Use a temporary list to hold products and their raw scores
    List<_RankedProduct> tempProducts = [];

    for (var product in products) {
      // --- Calculate Age ---
      // Corrected the (6S0 * 60 * 24) typo to (60 * 60 * 24)
      final ageInDays = max(1, (nowInSeconds - product.release.millisecondsSinceEpoch / 1000) / (60 * 60 * 24));

      // --- A. Popularity Score ("Sales Velocity") ---
      // We use log(x + 1) which is the equivalent of JS log1p(x)
      final salesVelocity = product.sales / ageInDays;
      final popularityScore = log(salesVelocity + 1);

      // --- B. Recency Score (Exponential Decay) ---
      const halfLifeDays = 180;
      final recencyScore = exp(-ageInDays / halfLifeDays);

      // --- C. Price Score ("High-End") ---
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
        price: priceScore,
        popularity: popularityScore,
        recency: recencyScore,
      ));
    }

    // --- 2. Calculate Final Weighted Score ---
    // Now we iterate again to normalize all scores from 0.0 to 1.0
    for (var temp in tempProducts) {
      final normPrice = (maxPrice - minPrice) > 0 ? (temp.price - minPrice) / (maxPrice - minPrice) : 0;
      final normPop = (maxPop - minPop) > 0 ? (temp.popularity - minPop) / (maxPop - minPop) : 0;
      final normRecency = (maxRecency - minRecency) > 0 ? (temp.recency - minRecency) / (maxRecency - minRecency) : 0;

      // The final "Vector" score!
      final priorityScore =
          (_weights['PRICE']! * normPrice) +
              (_weights['RECENCY']! * normRecency) +
              (_weights['POPULARITY']! * normPop);

      // Store the final score on the original product object
      temp.product.priorityScore = priorityScore;
    }

    // --- 3. Sort and Return Top N ---
    // Sort descending by the final score
    tempProducts.sort((a, b) => b.product.priorityScore.compareTo(a.product.priorityScore));

    // Return just the Top N original Product objects
    return tempProducts.map((temp) => temp.product).take(topN).toList();
  }
}

class _RankedProduct {
  final Product product;
  final double price;
  final double popularity;
  final double recency;

  _RankedProduct({
    required this.product,
    required this.price,
    required this.popularity,
    required this.recency,
  });
}

List<Product> getProductsWithCategory(CategoryEnum category) {
  return Database().productList.where((p) => p.category == category).toList();
}