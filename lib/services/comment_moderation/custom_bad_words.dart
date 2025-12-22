/// Custom bad words list for the GizmoGlobe project.
/// Add your custom profanity words here.
class CustomBadWords {
  /// Vietnamese custom bad words
  static const List<String> vietnamese = [
    // Add your custom Vietnamese bad words here
    // Example (uncomment to use):
    // 'lừa đảo',
    // 'scam',
    // 'hàng giả',
    // 'hàng nhái',
  ];

  /// English custom bad words
  static const List<String> english = [
    // Add your custom English bad words here
    // Example:
    // 'badword1',
    // 'badword2',
  ];

  /// Get all custom bad words
  static List<String> get all => [...vietnamese, ...english];

  /// Check if text contains any custom bad words
  static bool containsBadWords(String text) {
    final lowerText = text.toLowerCase();
    return all.any((word) => lowerText.contains(word.toLowerCase()));
  }

  /// Get all bad words found in the text
  static List<String> findBadWords(String text) {
    final lowerText = text.toLowerCase();
    return all.where((word) => lowerText.contains(word.toLowerCase())).toList();
  }

  /// Sanitize text by replacing custom bad words with asterisks
  static String sanitize(String text) {
    var sanitized = text;
    for (final word in all) {
      if (word.isEmpty) continue;
      final pattern =
          RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      sanitized = sanitized.replaceAll(pattern, '***');
    }
    return sanitized;
  }
}
