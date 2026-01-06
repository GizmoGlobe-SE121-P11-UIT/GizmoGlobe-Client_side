// dart
import 'dart:io';
import 'package:bloc/bloc.dart';
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

    final total = _computeBytes(state.images, state.video);
    if (total > maxTotalBytes) {
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

        // Check sentiment-rating mismatch
        if (moderationResult.hasSentimentAnalysis &&
            moderationResult.isSentimentMismatch(state.rating)) {
          // Get localized sentiment label
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

  /// Step 2: Submit rating to Firebase
  Future<void> submitRating(String productId, BuildContext context) async {
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
        rating: state.rating,
        comment: (state.comment.trim().isEmpty) ? null : state.comment,
        images: state.images.isEmpty ? null : state.images,
        video: state.video,
        sentiment: state.sentiment?.name, // Only save sentiment name, not score
      );

      emit(state.copyWith(processState: ProcessState.success));

      if (context.mounted) {
        SnackbarService.showSuccessAboveOverlay(
          overlay,
          title: 'Success',
          message: 'Your rating has been submitted successfully!',
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
      final newFiles = picked.map((x) => File(x.path)).toList();
      final combined = List<File>.from(state.images)..addAll(newFiles);

      if (combined.length > maxImages) {
        emit(state.copyWith(error: 'Maximum $maxImages images allowed.'));
        return;
      }

      final total = _computeBytes(combined, state.video);
      if (total > maxTotalBytes) {
        emit(state.copyWith(error: 'Total size must be <= 10 MB.'));
        return;
      }

      emit(state.copyWith(images: combined, error: null));
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
      final videoFile = File(picked.path);
      final total = _computeBytes(state.images, videoFile);
      if (total > maxTotalBytes) {
        emit(state.copyWith(error: 'Total size must be <= 10 MB.'));
        return;
      }
      emit(state.copyWith(video: videoFile, error: null));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick video.'));
    }
  }

  void removeImageAt(int index) {
    final newImages = List<File>.from(state.images)..removeAt(index);
    emit(state.copyWith(images: newImages, error: null));
  }

  void removeVideo() {
    emit(state.copyWith(video: null, error: null));
  }

  Future<void> submit(String productId) async {
    if (state.rating < 1 || state.rating > 5) {
      emit(state.copyWith(error: 'Please provide a rating.'));
      return;
    }

    final total = _computeBytes(state.images, state.video);
    if (total > maxTotalBytes) {
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
        images: state.images.isEmpty ? null : state.images,
        video: state.video,
      );

      final bool eligibleForPoints = ((state.images.length >= 2) ||
              (state.video != null && state.images.isNotEmpty)) &&
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

  int _computeBytes(List<File> images, File? video) {
    var sum = 0;
    for (final f in images) {
      try {
        sum += f.lengthSync();
      } catch (_) {}
    }
    if (video != null) {
      try {
        sum += video.lengthSync();
      } catch (_) {}
    }
    return sum;
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
