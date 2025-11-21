import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_profanity_words_checker/flutter_profanity_words_checker.dart'
    as profanity;
import 'package:google_generative_ai/google_generative_ai.dart';

/// Represents the result of running a comment through the moderation pipeline.
class CommentModerationResult {
  CommentModerationResult({
    required this.originalText,
    required this.sanitizedText,
    required this.flaggedTerms,
    required this.toxicityScore,
    required this.shouldBlock,
    required this.reason,
    required this.source,
  });

  final String originalText;
  final String sanitizedText;
  final List<String> flaggedTerms;
  final double toxicityScore;
  final bool shouldBlock;
  final String reason;
  final String source;

  bool get wasModified => originalText.trim() != sanitizedText.trim();
  bool get hasFlaggedTerms => flaggedTerms.isNotEmpty;
}

class _DictionarySanitizationResult {
  _DictionarySanitizationResult({
    required this.sanitizedText,
    required this.flaggedTerms,
  });

  final String sanitizedText;
  final List<String> flaggedTerms;
}

/// Service that relies on an established bad-word dictionary for sanitizing
/// comments and uses Gemini purely for contextual toxicity scoring.
class CommentModerationService {
  CommentModerationService({
    GenerativeModel? model,
    String? apiKey,
    profanity.FlutterProfanityChecker? englishChecker,
    profanity.FlutterProfanityChecker? vietnameseChecker,
  })  : _model = model ??
            (() {
              final key = apiKey ?? dotenv.env['GEMINI_API_KEY'];
              if (key == null || key.isEmpty) {
                throw StateError(
                    'GEMINI_API_KEY is missing. Add it to the .env file.');
              }
              return GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
            })(),
        _englishChecker = englishChecker ??
            profanity.FlutterProfanityChecker(language: profanity.Language.en),
        _vietnameseChecker = vietnameseChecker ??
            profanity.FlutterProfanityChecker(language: profanity.Language.vi);

  final GenerativeModel _model;
  final profanity.FlutterProfanityChecker _englishChecker;
  final profanity.FlutterProfanityChecker _vietnameseChecker;

  bool _dictionariesLoaded = false;

  Future<CommentModerationResult> filterComment(
    String comment, {
    String? userId,
  }) async {
    final trimmed = comment.trimRight();
    if (trimmed.isEmpty) {
      return CommentModerationResult(
        originalText: comment,
        sanitizedText: comment,
        flaggedTerms: const [],
        toxicityScore: 0,
        shouldBlock: false,
        reason: 'empty_comment',
        source: 'dictionary',
      );
    }

    final dictionaryResult = await _sanitizeWithDictionary(comment);
    Map<String, dynamic>? aiInsights;

    try {
      aiInsights = await _analyzeWithGemini(trimmed, userId);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
            'CommentModerationService: Gemini analysis failed: $e\n$stack');
      }
    }

    final geminiToxicity = aiInsights?['toxicity'];
    final double toxicityScore = geminiToxicity is num
        ? geminiToxicity.toDouble().clamp(0, 1)
        : _estimateDictionaryToxicity(dictionaryResult.flaggedTerms.length);
    final shouldBlock = aiInsights?['should_block'] as bool? ??
        dictionaryResult.flaggedTerms.length >= 3;
    final reason = aiInsights?['reason'] as String? ??
        (dictionaryResult.flaggedTerms.isEmpty
            ? 'dictionary_clean'
            : 'dictionary_violation');

    return CommentModerationResult(
      originalText: comment,
      sanitizedText: dictionaryResult.sanitizedText,
      flaggedTerms: dictionaryResult.flaggedTerms,
      toxicityScore: toxicityScore,
      shouldBlock: shouldBlock,
      reason: reason,
      source: aiInsights == null ? 'dictionary' : 'dictionary+gemini',
    );
  }

  Future<void> _ensureDictionariesLoaded() async {
    if (_dictionariesLoaded) return;
    await Future.wait([
      _englishChecker.init(),
      _vietnameseChecker.init(),
    ]);
    _dictionariesLoaded = true;
  }

  Future<_DictionarySanitizationResult> _sanitizeWithDictionary(
      String comment) async {
    await _ensureDictionariesLoaded();
    final flagged = <String>{};

    for (final checker in [_englishChecker, _vietnameseChecker]) {
      flagged.addAll(checker.all(comment));
    }

    var sanitizedText = comment;
    for (final word in flagged) {
      if (word.isEmpty) continue;
      final pattern =
          RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      sanitizedText = sanitizedText.replaceAll(pattern, '***');
    }

    return _DictionarySanitizationResult(
      sanitizedText: sanitizedText,
      flaggedTerms: flagged.toList(),
    );
  }

  Future<Map<String, dynamic>?> _analyzeWithGemini(
      String comment, String? userId) async {
    final prompt = _buildAnalysisPrompt(comment, userId);
    final response = await _model.generateContent([Content.text(prompt)]);
    return _parseGeminiPayload(response.text);
  }

  String _buildAnalysisPrompt(String comment, String? userId) => '''
You are a safety reviewer for an e-commerce community. ONLY inspect the text and never rewrite or censor it.
- Detect harassment, hate, sexual content, threats, scams, or extreme negativity.
- Consider both English and Vietnamese language variations.
- You MUST respond with strictly valid JSON and nothing else.

JSON schema:
{
  "toxicity": <0.0-1.0>,
  "should_block": <true|false>,
  "reason": "<short explanation>"
}

User info (optional): ${userId ?? 'anonymous'}
Comment to review (read-only):
\"\"\"$comment\"\"\"
''';

  Map<String, dynamic>? _parseGeminiPayload(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final cleaned = raw
        .replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      try {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1) {
          final candidate = cleaned.substring(start, end + 1);
          return jsonDecode(candidate) as Map<String, dynamic>;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('CommentModerationService: Failed to parse JSON: $e');
        }
      }
    }
    return null;
  }

  double _estimateDictionaryToxicity(int count) {
    if (count <= 0) return 0;
    if (count == 1) return 0.35;
    if (count == 2) return 0.55;
    if (count == 3) return 0.75;
    return 0.9;
  }
}
