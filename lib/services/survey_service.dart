import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../objects/survey_models.dart';

class SurveyService {
  SurveyService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _questionsCol =>
      _firestore.collection('surveyQuestions');

  /// Fetch questions for a given survey version, ordered by displayOrder
  Stream<List<SurveyQuestion>> watchQuestions({String version = 'v1'}) {
    return _questionsCol
        .where('version', isEqualTo: version)
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) => snap.docs.map(SurveyQuestion.fromDoc).toList());
  }

  Future<List<SurveyQuestion>> getQuestions({String version = 'v1'}) async {
    final snap = await _questionsCol
        .where('version', isEqualTo: version)
        .orderBy('displayOrder')
        .get();
    return snap.docs.map(SurveyQuestion.fromDoc).toList();
  }

  /// Save response to both user-scoped and global pools atomically
  Future<void> submitResponse({
    required List<SurveyAnswer> answers,
    String version = 'v1',
    String channel = 'app',
  }) async {
    final user = _auth.currentUser;
    final userId = user?.uid;
    final now = DateTime.now();

    // Build "raw" map consistent with importer (questionId -> value)
    final Map<String, dynamic> rawMap = {
      for (final a in answers) a.questionId: a.value,
    };

    final responseData = <String, dynamic>{
      'submittedAt': Timestamp.fromDate(now),
      'channel': channel,
      'version': version,
      'raw': rawMap,
    };

    final batch = _firestore.batch();

    // 1) surveyResponses_raw with docId = userId (or guest timestamp fallback)
    final String rawDocId =
        userId ?? 'guest_${now.millisecondsSinceEpoch.toString()}';
    final rawRef = _firestore.collection('surveyResponses_raw').doc(rawDocId);
    batch.set(rawRef, responseData);

    // 2) customers/{userId}/survey/{userId} copy (update-or-create) when signed-in
    if (userId != null) {
      // Ensure parent customer doc exists (create empty doc if missing)
      final customerSurveyRef = _firestore
          .collection('customers')
          .doc(userId)
          .collection('survey')
          .doc(userId);
      batch.set(customerSurveyRef, responseData, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Submit a pre-built response payload (use when you want form-like 'raw')
  Future<void> submitRaw(Map<String, dynamic> responseData) async {
    final user = _auth.currentUser;
    final userId = user?.uid;
    final now = DateTime.now();

    final batch = _firestore.batch();

    // Defensively ensure 'raw' is Map<String, dynamic>
    final dynamic rawAny = responseData['raw'];
    if (rawAny is Map && rawAny is! Map<String, dynamic>) {
      responseData = {
        ...responseData,
        'raw': Map<String, dynamic>.from(rawAny),
      };
    }

    try {
      // 1) surveyResponses_raw with docId = userId (or guest timestamp fallback)
      final String rawDocId =
          userId ?? 'guest_${now.millisecondsSinceEpoch.toString()}';
      final rawRef = _firestore.collection('surveyResponses_raw').doc(rawDocId);
      batch.set(rawRef, responseData);

      // 2) customers/{userId}/survey/{userId} copy (update-or-create) when signed-in
      if (userId != null) {
        // Ensure parent customer doc exists (create empty doc if missing)
        final customerSurveyRef = _firestore
            .collection('customers')
            .doc(userId)
            .collection('survey')
            .doc(userId);
        batch.set(customerSurveyRef, responseData, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e, st) {
      // ignore: avoid_print
      print('SurveyService.submitRaw error: $e');
      // ignore: avoid_print
      print(st);
      rethrow;
    }
  }

  /// Read existing 'raw' response for current user (form-like), or null if none
  Future<Map<String, dynamic>?> getCurrentUserRaw() async {
    final user = _auth.currentUser;
    final userId = user?.uid;
    if (userId == null) return null;
    final doc =
        await _firestore.collection('surveyResponses_raw').doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final raw = data['raw'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
