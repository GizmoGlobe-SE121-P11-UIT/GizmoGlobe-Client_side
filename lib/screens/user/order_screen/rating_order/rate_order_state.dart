import 'dart:io';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../services/comment_moderation/comment_moderation_service.dart';

class RateOrderState {
  final int rating;
  final String comment;
  final List<File> images;
  final File? video;
  final ProcessState processState;
  final String? error;

  // Sentiment analysis fields
  final CommentSentiment? sentiment;
  final double? sentimentScore;
  final bool isAnalyzing;

  // Two-step verification fields
  final bool isContentVerified;
  final String? verificationMessage;

  RateOrderState({
    required this.rating,
    required this.comment,
    required this.images,
    required this.video,
    required this.processState,
    this.error,
    this.sentiment,
    this.sentimentScore,
    this.isAnalyzing = false,
    this.isContentVerified = false,
    this.verificationMessage,
  });

  factory RateOrderState.initial() => RateOrderState(
        rating: 0,
        comment: '',
        images: const [],
        video: null,
        processState: ProcessState.idle,
        error: null,
        sentiment: null,
        sentimentScore: null,
        isAnalyzing: false,
        isContentVerified: false,
        verificationMessage: null,
      );

  RateOrderState copyWith({
    int? rating,
    String? comment,
    List<File>? images,
    File? video,
    ProcessState? processState,
    String? error,
    CommentSentiment? sentiment,
    double? sentimentScore,
    bool? isAnalyzing,
    bool? isContentVerified,
    String? verificationMessage,
  }) {
    return RateOrderState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      video: video ?? this.video,
      processState: processState ?? this.processState,
      error: error,
      sentiment: sentiment ?? this.sentiment,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isContentVerified: isContentVerified ?? this.isContentVerified,
      verificationMessage: verificationMessage,
    );
  }

  int get totalBytes {
    var sum = 0;
    for (final f in images) {
      try {
        sum += f.lengthSync();
      } catch (_) {}
    }
    if (video != null) {
      try {
        sum += video!.lengthSync();
      } catch (_) {}
    }
    return sum;
  }
}
