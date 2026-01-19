import 'package:universal_io/io.dart';
import 'dart:typed_data';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../services/comment_moderation/comment_moderation_service.dart';

class RateOrderState {
  final int rating;
  final String comment;
  final List<File> images;
  final List<Uint8List> imageBytes; // For web compatibility
  final List<String> imageExtensions; // Store file extensions for web
  final File? video;
  final Uint8List? videoBytes; // For web compatibility
  final String? videoExtension; // Store video extension for web
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
    required this.imageBytes,
    required this.imageExtensions,
    required this.video,
    this.videoBytes,
    this.videoExtension,
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
        imageBytes: const [],
        imageExtensions: const [],
        video: null,
        videoBytes: null,
        videoExtension: null,
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
    List<Uint8List>? imageBytes,
    List<String>? imageExtensions,
    File? video,
    Uint8List? videoBytes,
    String? videoExtension,
    ProcessState? processState,
    String? error,
    CommentSentiment? sentiment,
    double? sentimentScore,
    bool? isAnalyzing,
    bool? isContentVerified,
    String? verificationMessage,
    bool clearVideo = false,
  }) {
    return RateOrderState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      imageBytes: imageBytes ?? this.imageBytes,
      imageExtensions: imageExtensions ?? this.imageExtensions,
      video: clearVideo ? null : (video ?? this.video),
      videoBytes: clearVideo ? null : (videoBytes ?? this.videoBytes),
      videoExtension: clearVideo ? null : (videoExtension ?? this.videoExtension),
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
    // Use bytes for accurate cross-platform calculation
    for (final bytes in imageBytes) {
      sum += bytes.length;
    }
    if (videoBytes != null) {
      sum += videoBytes!.length;
    }
    return sum;
  }
}
