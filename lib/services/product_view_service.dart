import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service to track product views for collaborative filtering.
///
/// This data is used by Cloud Functions to compute product similarity.
/// Views are tracked when users open product detail pages.
class ProductViewService {
  static const String _baseUrl =
      'https://us-central1-se121p11-gizmoglobe.cloudfunctions.net';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track a product view event.
  ///
  /// Called automatically when user opens a product detail page.
  /// This data is used for collaborative filtering recommendations.
  Future<void> trackProductView(String productId, {String? sessionId}) async {
    try {
      final userId = _auth.currentUser?.uid;

      final response = await http.post(
        Uri.parse('$_baseUrl/trackProductView'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId ?? 'anonymous',
          'productId': productId,
          'sessionId': sessionId,
        }),
      );

      if (response.statusCode != 200) {
        // Failed to track product view
      }
    } catch (e) {
      // Silently fail - tracking is non-critical
    }
  }

  /// Batch track multiple product views (for history sync).
  Future<void> trackMultipleViews(List<String> productIds) async {
    for (final productId in productIds) {
      await trackProductView(productId);
    }
  }
}
