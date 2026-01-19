// Use universal_io for cross-platform File support (web + mobile)
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/services/comment_moderation/comment_moderation_service.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../enums/processing/process_state_enum.dart';
import 'rate_order_state.dart';

class RateOrderCubit extends Cubit<RateOrderState> {
  static const int maxImages = 5;
  static const int maxTotalBytes = 10 * 1024 * 1024; // 10 MB
  final ImagePicker _picker = ImagePicker();

  RateOrderCubit() : super(RateOrderState.initial());

  void setRating(int rating) {
    emit(state.copyWith(rating: rating, error: null));
  }

  void setComment(String comment) {
    emit(state.copyWith(
      comment: comment,
      isContentVerified: false, // Reset verification when comment changes
      verificationMessage: null,
      sentiment: null, // Clear sentiment when editing
      sentimentScore: null,
    ));
  }

  /// Step 1: Check content for profanity and sentiment
  Future<void> checkContent(BuildContext context) async {
    final overlay = Overlay.of(context);

    if (state.rating < 1 || state.rating > 5) {
      SnackbarService.showErrorAboveOverlay(
        overlay,
        title: S.of(context).ratingRequired,
        message: S.of(context).pleaseProvideRating,
      );
      return;
    }

    if (state.totalBytes > maxTotalBytes) {
      SnackbarService.showErrorAboveOverlay(
        overlay,
        title: S.of(context).fileSizeLimit,
        message: S.of(context).totalSizeMustBe10MB,
      );
      return;
    }

    // Check for bad words and sentiment in comment if comment is not empty
    if (state.comment.trim().isNotEmpty) {
      emit(state.copyWith(isAnalyzing: true));
      try {
        final moderationService = CommentModerationService();
        final moderationResult = await moderationService.filterComment(
          state.comment,
          userId: Database().userID,
        );

        // Block if contains profanity
        if (moderationResult.shouldBlock || moderationResult.hasFlaggedTerms) {
          emit(state.copyWith(isAnalyzing: false));
          SnackbarService.showErrorAboveOverlay(
            overlay,
            title: S.of(context).inappropriateContent,
            message: S.of(context).commentContainsInappropriateLanguage,
          );
          return;
        }

        // Save sentiment first so it can be displayed
        emit(state.copyWith(
          sentiment: moderationResult.sentiment,
          sentimentScore: moderationResult.sentimentScore,
          isAnalyzing: false,
        ));

        final hasSentiment = moderationResult.sentiment != null;
        final bool allowNeutralThreeToFive =
            moderationResult.sentiment == CommentSentiment.neutral &&
                state.rating >= 3;
        final bool mismatchFromService =
            moderationResult.hasSentimentAnalysis &&
                moderationResult.isSentimentMismatch(state.rating) &&
                !allowNeutralThreeToFive;
        final bool mismatchHeuristic = hasSentiment &&
            _isHeuristicSentimentMismatch(
                moderationResult.sentiment!, state.rating) &&
            !allowNeutralThreeToFive;
        final bool mismatchTextOnly =
            !hasSentiment && state.rating >= 4 && _looksNegative(state.comment);

        if (mismatchFromService || mismatchHeuristic || mismatchTextOnly) {
          final sentimentLabel =
              _getSentimentLabel(context, moderationResult.sentiment);

          SnackbarService.showErrorAboveOverlay(
            overlay,
            title: S.of(context).ratingMismatch,
            message: S
                .of(context)
                .ratingMismatchMessage(sentimentLabel, state.rating),
          );
          return;
        }

        // Content passed all checks!
        emit(state.copyWith(
          isAnalyzing: false,
          isContentVerified: true,
          verificationMessage: 'Content verified! You can now submit.',
        ));
      } catch (e) {
        emit(state.copyWith(isAnalyzing: false));

        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => InformationDialog(
              dialogName: DialogName.failure,
              title: 'Verification Failed',
              content: 'Unable to verify comment content. Please try again.',
            ),
          );
        }
      }
    } else {
      // No comment, mark as verified
      emit(state.copyWith(
        isContentVerified: true,
        verificationMessage: 'Ready to submit!',
      ));
    }
  }

  bool _isHeuristicSentimentMismatch(CommentSentiment sentiment, int rating) {
    // Simple guardrail if service did not flag mismatch.
    if (rating >= 4) {
      // Neutral is acceptable for 3–5 stars (per product feedback UX),
      // so only block clearly negative/mixed sentiments for high ratings.
      return sentiment == CommentSentiment.negative ||
          sentiment == CommentSentiment.mixed;
    }
    if (rating <= 2) {
      return sentiment == CommentSentiment.positive ||
          sentiment == CommentSentiment.mixed;
    }
    return false;
  }

  bool _looksNegative(String text) {
    final lower = text.toLowerCase();
    const negatives = [
      'bad',
      'terrible',
      'awful',
      'poor',
      'hate',
      'broken',
      'scam',
      'fraud',
      'trash',
      'worst',
      'không tốt',
      'tệ',
      'rác',
      'dở',
      'kém',
    ];
    return negatives.any(lower.contains);
  }

  /// Step 2: Submit rating to Firebase
  Future<void> submitRating(
    String productId,
    BuildContext context, {
    String? invoiceId,
  }) async {
    final overlay = Overlay.of(context);

    // Must be verified first
    if (!state.isContentVerified) {
      await checkContent(context);
      return;
    }

    emit(state.copyWith(processState: ProcessState.loading));
    try {
      await Firebase().submitOrderRating(
        userID: Database().userID,
        productId: productId,
        invoiceId: invoiceId,
        rating: state.rating,
        comment: (state.comment.trim().isEmpty) ? null : state.comment,
        images: kIsWeb ? null : (state.images.isEmpty ? null : state.images),
        video: kIsWeb ? null : state.video,
        imageBytes: state.imageBytes.isEmpty ? null : state.imageBytes,
        imageExtensions:
            state.imageExtensions.isEmpty ? null : state.imageExtensions,
        videoBytes: state.videoBytes,
        videoExtension: state.videoExtension,
        sentiment: state.sentiment?.name, // Only save sentiment name, not score
      );

      emit(state.copyWith(processState: ProcessState.success));

      if (context.mounted) {
        SnackbarService.showSuccessAboveOverlay(
          overlay,
          title: S.of(context).success,
          message: S.of(context).ratingSubmitSuccess,
        );
      }
    } catch (e) {
      emit(state.copyWith(processState: ProcessState.failure));

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => InformationDialog(
            dialogName: DialogName.failure,
            title: 'Submit Failed',
            content: 'Failed to submit rating: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;

      // Read bytes first to check size before adding
      final newBytes = await Future.wait(
        picked.map((xFile) => xFile.readAsBytes()),
      );

      final combinedBytes = List<Uint8List>.from(state.imageBytes)
        ..addAll(newBytes);

      if (combinedBytes.length > maxImages) {
        emit(state.copyWith(error: 'Maximum $maxImages images allowed.'));
        return;
      }

      // Calculate total size using bytes
      var totalSize = 0;
      for (final b in combinedBytes) {
        totalSize += b.length;
      }
      if (state.videoBytes != null) {
        totalSize += state.videoBytes!.length;
      }

      if (totalSize > maxTotalBytes) {
        emit(state.copyWith(error: 'Total size must be <= 10 MB.'));
        return;
      }

      // Store file extensions for web upload
      final newExtensions = picked.map((x) {
        final ext = x.path.split('.').last.toLowerCase();
        return ext.isNotEmpty ? ext : 'jpg';
      }).toList();
      final combinedExtensions = List<String>.from(state.imageExtensions)
        ..addAll(newExtensions);

      final newFiles = picked.map((x) => File(x.path)).toList();
      final combinedFiles = List<File>.from(state.images)..addAll(newFiles);

      emit(state.copyWith(
        images: combinedFiles,
        imageBytes: combinedBytes,
        imageExtensions: combinedExtensions,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick images.'));
    }
  }

  Future<void> pickVideo() async {
    try {
      if (state.video != null) {
        emit(state.copyWith(error: 'Only one video allowed.'));
        return;
      }
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      // Read bytes for web compatibility
      final videoBytes = await picked.readAsBytes();

      // Calculate total size using bytes
      var totalSize = videoBytes.length;
      for (final b in state.imageBytes) {
        totalSize += b.length;
      }

      if (totalSize > maxTotalBytes) {
        emit(state.copyWith(error: 'Total size must be <= 10 MB.'));
        return;
      }

      // Get extension
      final ext = picked.path.split('.').last.toLowerCase();
      final videoExtension = ext.isNotEmpty ? ext : 'mp4';

      // On web, don't create File object from blob URL path
      // On mobile, create File object for compatibility
      final videoFile = kIsWeb ? null : File(picked.path);

      emit(state.copyWith(
        video: videoFile,
        videoBytes: videoBytes,
        videoExtension: videoExtension,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick video.'));
    }
  }

  void removeImageAt(int index) {
    final newImages = List<File>.from(state.images)..removeAt(index);
    final newBytes = List<Uint8List>.from(state.imageBytes)..removeAt(index);
    final newExtensions = List<String>.from(state.imageExtensions)
      ..removeAt(index);
    emit(state.copyWith(
      images: newImages,
      imageBytes: newBytes,
      imageExtensions: newExtensions,
      error: null,
    ));
  }

  void removeVideo() {
    emit(state.copyWith(clearVideo: true, error: null));
  }

  Future<void> submit(String productId) async {
    if (state.rating < 1 || state.rating > 5) {
      emit(state.copyWith(error: 'Please provide a rating.'));
      return;
    }

    if (state.totalBytes > maxTotalBytes) {
      emit(state.copyWith(error: 'Total size must be <= 10 MB.'));
      return;
    }

    emit(state.copyWith(processState: ProcessState.loading, error: null));
    try {
      await Firebase().submitOrderRating(
        userID: Database().userID,
        productId: productId,
        rating: state.rating,
        comment: (state.comment.trim().isEmpty) ? null : state.comment,
        images: kIsWeb ? null : (state.images.isEmpty ? null : state.images),
        video: kIsWeb ? null : state.video,
        imageBytes: state.imageBytes.isEmpty ? null : state.imageBytes,
        imageExtensions:
            state.imageExtensions.isEmpty ? null : state.imageExtensions,
        videoBytes: state.videoBytes,
        videoExtension: state.videoExtension,
        sentiment: state.sentiment?.name, // Save sentiment if available
      );

      final bool eligibleForPoints = ((state.imageBytes.length >= 2) ||
              (state.videoBytes != null && state.imageBytes.isNotEmpty)) &&
          state.comment.trim().isNotEmpty;

      if (eligibleForPoints) {
        try {
          await Database().addLoyalPoint(200);
        } catch (e) {
          rethrow;
        }
      }

      emit(state.copyWith(processState: ProcessState.success));
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure,
          error: 'Submit failed: ${e.toString()}'));
    }
  }

  String _getSentimentLabel(BuildContext context, CommentSentiment? sentiment) {
    switch (sentiment) {
      case CommentSentiment.positive:
        return S.of(context).sentimentPositive;
      case CommentSentiment.negative:
        return S.of(context).sentimentNegative;
      case CommentSentiment.neutral:
        return S.of(context).sentimentNeutral;
      case CommentSentiment.mixed:
        return S.of(context).sentimentMixed;
      default:
        return 'unknown';
    }
  }
}
