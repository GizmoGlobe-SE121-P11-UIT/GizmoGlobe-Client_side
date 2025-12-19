// dart
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
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
    emit(state.copyWith(comment: comment));
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

      final bool eligibleForPoints =
          ((state.images.length >= 2) || (state.video != null && state.images.isNotEmpty)) &&
          state.comment.trim().isNotEmpty;

      if (eligibleForPoints) {
        try {
          await Database().addLoyalPoint(200);
        } catch (e) {
          if (kDebugMode) print('Failed to add loyal points: $e');
        }
      }

      emit(state.copyWith(processState: ProcessState.success));
    } catch (e) {
      emit(state.copyWith(
          processState: ProcessState.failure, error: 'Submit failed: ${e.toString()}'));
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
}
