
class UserProfile {
  final List<String> usage;      // e.g., "Gaming", "Office"
  final List<String> priorities; // e.g., "Price", "Performance"
  final double budgetLimit;

  UserProfile({
    this.usage = const [],
    this.priorities = const [],
    this.budgetLimit = double.infinity,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Helper to find value by key loosely (ignoring potential minor encoding diffs or whitespace)
    dynamic getValue(String targetKey) {
      if (map.containsKey(targetKey)) return map[targetKey];
      // Fallback: iterate keys to find a match
      for (final key in map.keys) {
        if (key.trim() == targetKey.trim()) return map[key];
      }
      return null;
    }

    final usage = (getValue('Bạn chủ yếu sử dụng máy tính cho mục đích gì?') as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    final priorities = (getValue('Yếu tố quan trọng nhất khi quyết định mua máy?') as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    double budget = double.infinity;
    final budgetStr = getValue('Ngân sách bạn dự kiến cho lần mua máy sắp tới?') as String?;

    if (budgetStr != null) {
      if (budgetStr.contains('dưới 15 triệu')) {
        budget = 15000000;
      } else if (budgetStr.contains('15 – 20 triệu')) {
        budget = 20000000;
      }
      else if (budgetStr.contains('20 – 30 triệu')) {
        budget = 30000000;
      }
      else if (budgetStr.contains('30 – 50 triệu')) {
        budget = 50000000;
      }
      else if (budgetStr.contains('Trên 50 triệu')) {
        budget = 100000000;
      }
    }

    return UserProfile(
      usage: usage,
      priorities: priorities,
      budgetLimit: budget,
    );
  }

  Map<String, double> getWeights() {
    double wPerform = 0.25;
    double wPrice = 0.35;
    double wRecency = 0.20;
    double wPop = 0.20;

    if (usage.contains("Chơi game") || usage.contains("Thiết kế đồ họa / Kiến trúc / Multimedia") || priorities.contains("Hiệu năng (cấu hình)")) {
      wPerform += 0.25;
      wPrice -= 0.3;
      wRecency += 0.05;
    }

    if (priorities.contains("Giá cả")) {
      wPrice += 0.2;
      wPerform -= 0.1;
      wRecency -= 0.1;
    }

    return {
      'PERF': wPerform,
      'PRICE': wPrice,
      'RECENCY': wRecency,
      'POP': wPop,
    };
  }
}