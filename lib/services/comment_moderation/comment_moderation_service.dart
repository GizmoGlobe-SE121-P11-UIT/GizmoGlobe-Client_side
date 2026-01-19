import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_profanity_words_checker/flutter_profanity_words_checker.dart'
    as profanity;
import 'package:google_generative_ai/google_generative_ai.dart';

import 'custom_bad_words.dart';

/// Sentiment of a comment
enum CommentSentiment {
  positive,
  neutral,
  negative,
  mixed,
}

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
    this.sentiment,
    this.sentimentScore,
    this.sentimentExplanation,
  });

  final String originalText;
  final String sanitizedText;
  final List<String> flaggedTerms;
  final double toxicityScore;
  final bool shouldBlock;
  final String reason;
  final String source;

  // Sentiment analysis fields
  final CommentSentiment? sentiment;
  final double? sentimentScore; // -1.0 (very negative) to 1.0 (very positive)
  final String? sentimentExplanation;

  bool get wasModified => originalText.trim() != sanitizedText.trim();
  bool get hasFlaggedTerms => flaggedTerms.isNotEmpty;
  bool get hasSentimentAnalysis => sentiment != null;

  /// Check if sentiment matches the given rating (1-5 stars)
  bool isSentimentMismatch(int rating) {
    if (sentiment == null) return false;

    // High rating (4-5 stars) should have positive sentiment
    if (rating >= 4 && sentiment == CommentSentiment.negative) return true;

    // Low rating (1-2 stars) should have negative sentiment
    if (rating <= 2 && sentiment == CommentSentiment.positive) return true;

    return false;
  }
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
              if (key != null && key.isNotEmpty) {
                try {
                  return GenerativeModel(
                      model: 'gemini-3.0-flash', apiKey: key);
                } catch (e) {
                  return null;
                }
              }
              return null;
            })(),
        _englishChecker = englishChecker ??
            profanity.FlutterProfanityChecker(language: profanity.Language.en),
        _vietnameseChecker = vietnameseChecker ??
            profanity.FlutterProfanityChecker(language: profanity.Language.vi);

  final GenerativeModel? _model;
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
    } catch (e) {
      // Gemini analysis failed
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

    // Extract sentiment analysis
    CommentSentiment? sentiment;
    double? sentimentScore;
    String? sentimentExplanation;

    if (aiInsights != null) {
      final sentimentStr = aiInsights['sentiment'] as String?;
      if (sentimentStr != null) {
        sentiment = _parseSentiment(sentimentStr);
      }

      final scoreValue = aiInsights['sentiment_score'];
      if (scoreValue is num) {
        sentimentScore = scoreValue.toDouble().clamp(-1.0, 1.0);
      }

      sentimentExplanation = aiInsights['sentiment_explanation'] as String?;
    }

    return CommentModerationResult(
      originalText: comment,
      sanitizedText: dictionaryResult.sanitizedText,
      flaggedTerms: dictionaryResult.flaggedTerms,
      toxicityScore: toxicityScore,
      shouldBlock: shouldBlock,
      reason: reason,
      source: aiInsights == null ? 'dictionary' : 'dictionary+gemini',
      sentiment: sentiment,
      sentimentScore: sentimentScore,
      sentimentExplanation: sentimentExplanation,
    );
  }

  Future<void> _ensureDictionariesLoaded() async {
    if (_dictionariesLoaded) return;
    try {
      await Future.wait([
        _englishChecker.init(),
        _vietnameseChecker.init(),
      ]);
      _dictionariesLoaded = true;
    } catch (e) {
      // Mark as loaded anyway to prevent repeated attempts
      _dictionariesLoaded = true;
    }
  }

  Future<_DictionarySanitizationResult> _sanitizeWithDictionary(
      String comment) async {
    try {
      await _ensureDictionariesLoaded();
      final flagged = <String>{};

      // Check package dictionaries
      for (final checker in [_englishChecker, _vietnameseChecker]) {
        try {
          flagged.addAll(checker.all(comment));
        } catch (e) {
          // Error checking profanity
        }
      }

      // Check custom bad words
      final customBadWordsFound = CustomBadWords.findBadWords(comment);
      flagged.addAll(customBadWordsFound);

      var sanitizedText = comment;
      for (final word in flagged) {
        if (word.isEmpty) continue;
        try {
          final pattern =
              RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
          sanitizedText = sanitizedText.replaceAll(pattern, '***');
        } catch (e) {
          // Error sanitizing word
        }
      }

      return _DictionarySanitizationResult(
        sanitizedText: sanitizedText,
        flaggedTerms: flagged.toList(),
      );
    } catch (e) {
      // Return original text if dictionary filtering fails
      return _DictionarySanitizationResult(
        sanitizedText: comment,
        flaggedTerms: const [],
      );
    }
  }

  Future<Map<String, dynamic>?> _analyzeWithGemini(
      String comment, String? userId) async {
    final model = _model;
    if (model == null) {
      return null;
    }
    try {
      final prompt = _buildAnalysisPrompt(comment, userId);
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseGeminiPayload(response.text);
    } catch (e) {
      return null;
    }
  }

  String _buildAnalysisPrompt(String comment, String? userId) => '''
You are a safety and sentiment reviewer for an e-commerce product review system. ONLY inspect the text and never rewrite or censor it.

Tasks:
1. **Safety Check**: Detect harassment, hate, sexual content, threats, scams, or extreme negativity.
2. **Sentiment Analysis**: Analyze the emotional tone and overall sentiment of the comment.
3. Consider both English and Vietnamese language variations.

You MUST respond with strictly valid JSON and nothing else.

JSON schema:
{
  "toxicity": <0.0-1.0>,
  "should_block": <true|false>,
  "reason": "<short explanation for blocking or not>",
  "sentiment": "<positive|neutral|negative|mixed>",
  "sentiment_score": <-1.0 to 1.0, where -1.0 is very negative, 0 is neutral, 1.0 is very positive>,
  "sentiment_explanation": "<brief explanation of the sentiment>"
}

Guidelines for sentiment:
- "positive": Comment expresses satisfaction, praise, or positive experience
- "negative": Comment expresses dissatisfaction, criticism, or negative experience  
- "neutral": Comment is factual without strong emotion either way
- "mixed": Comment contains both positive and negative sentiments

User info (optional): ${userId ?? 'anonymous'}
Comment to review (read-only):
"""$comment"""
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
        // Failed to parse JSON
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

  CommentSentiment _parseSentiment(String sentimentStr) {
    final normalized = sentimentStr.toLowerCase().trim();
    switch (normalized) {
      case 'positive':
        return CommentSentiment.positive;
      case 'negative':
        return CommentSentiment.negative;
      case 'mixed':
        return CommentSentiment.mixed;
      case 'neutral':
      default:
        return CommentSentiment.neutral;
    }
  }
}
