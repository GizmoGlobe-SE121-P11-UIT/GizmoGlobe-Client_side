import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service to track user events to Vertex AI Retail API.
///
/// This service sends events to Cloud Functions which forwards them
/// to Vertex AI Retail API for better recommendations and analytics.
class VertexAIEventService {
  static const String _baseUrl =
      'https://us-central1-se121p11-gizmoglobe.cloudfunctions.net';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track a search event.
  ///
  /// Called when user performs a search or applies filters.
  /// This helps Vertex AI understand search patterns.
  Future<void> trackSearch(String searchQuery, List<String> filters) async {
    try {
      final visitorId = _getVisitorId();

      final response = await http.post(
        Uri.parse('$_baseUrl/trackVertexAIEvent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventType': 'search',
          'visitorId': visitorId,
          'searchQuery': searchQuery,
          'filters': filters,
        }),
      );

      if (response.statusCode != 200) {
        // Failed to track search event
      }
    } catch (e) {
      // Silently fail - tracking is non-critical
    }
  }

  /// Track a detail-page-view event.
  ///
  /// Called when user views a product detail page.
  /// This is crucial for measuring engagement and recommendations.
  Future<void> trackDetailPageView(String productId) async {
    try {
      final visitorId = _getVisitorId();

      final response = await http.post(
        Uri.parse('$_baseUrl/trackVertexAIEvent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventType': 'detail-page-view',
          'visitorId': visitorId,
          'productDetails': [
            {
              'product': {'id': productId},
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        // Failed to track detail-page-view
      }
    } catch (e) {
      // Silently fail - tracking is non-critical
    }
  }

  /// Get visitor ID for tracking.
  ///
  /// Uses Firebase Auth UID if user is logged in,
  /// otherwise generates an anonymous visitor ID.
  String _getVisitorId() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      return userId;
    }
    // For anonymous users, use a consistent identifier based on timestamp
    return 'anonymous-${DateTime.now().millisecondsSinceEpoch}';
  }
}
