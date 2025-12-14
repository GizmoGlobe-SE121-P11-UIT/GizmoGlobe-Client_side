import 'dart:io';
import '../../../../enums/processing/process_state_enum.dart';

class RateOrderState {
  final int rating;
  final String comment;
  final List<File> images;
  final File? video;
  final ProcessState processState;
  final String? error;

  RateOrderState({
    required this.rating,
    required this.comment,
    required this.images,
    required this.video,
    required this.processState,
    this.error,
  });

  factory RateOrderState.initial() => RateOrderState(
    rating: 0,
    comment: '',
    images: const [],
    video: null,
    processState: ProcessState.idle,
    error: null,
  );

  RateOrderState copyWith({
    int? rating,
    String? comment,
    List<File>? images,
    File? video,
    ProcessState? processState,
    String? error,
  }) {
    return RateOrderState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      video: video ?? this.video,
      processState: processState ?? this.processState,
      error: error,
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
