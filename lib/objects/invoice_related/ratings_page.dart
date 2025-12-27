import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/objects/invoice_related/rating.dart';

class RatingsPage {
  final List<Rating> ratings;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  RatingsPage({
    required this.ratings,
    required this.lastDocument,
    required this.hasMore,
  });
}