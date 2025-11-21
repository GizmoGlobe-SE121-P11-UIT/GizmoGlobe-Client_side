import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'comment_moderation_service.dart';

enum CommentFilterStatus { initial, loading, success, failure }

class CommentFilterState extends Equatable {
  const CommentFilterState({
    this.status = CommentFilterStatus.initial,
    this.originalComment = '',
    this.sanitizedComment = '',
    this.flaggedTerms = const [],
    this.toxicityScore = 0,
    this.shouldBlock = false,
    this.reason = '',
    this.errorMessage,
  });

  final CommentFilterStatus status;
  final String originalComment;
  final String sanitizedComment;
  final List<String> flaggedTerms;
  final double toxicityScore;
  final bool shouldBlock;
  final String reason;
  final String? errorMessage;

  CommentFilterState copyWith({
    CommentFilterStatus? status,
    String? originalComment,
    String? sanitizedComment,
    List<String>? flaggedTerms,
    double? toxicityScore,
    bool? shouldBlock,
    String? reason,
    String? errorMessage,
  }) {
    return CommentFilterState(
      status: status ?? this.status,
      originalComment: originalComment ?? this.originalComment,
      sanitizedComment: sanitizedComment ?? this.sanitizedComment,
      flaggedTerms: flaggedTerms ?? this.flaggedTerms,
      toxicityScore: toxicityScore ?? this.toxicityScore,
      shouldBlock: shouldBlock ?? this.shouldBlock,
      reason: reason ?? this.reason,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        originalComment,
        sanitizedComment,
        flaggedTerms,
        toxicityScore,
        shouldBlock,
        reason,
        errorMessage,
      ];
}

/// Cubit that exposes the moderation service via a simple Bloc-friendly API.
class CommentFilterCubit extends Cubit<CommentFilterState> {
  CommentFilterCubit({CommentModerationService? service})
      : _service = service ?? CommentModerationService(),
        super(const CommentFilterState());

  final CommentModerationService _service;

  Future<void> filterComment(String comment, {String? userId}) async {
    if (comment.trim().isEmpty) {
      emit(state.copyWith(
        status: CommentFilterStatus.failure,
        errorMessage: 'Comment cannot be empty.',
      ));
      return;
    }

    emit(state.copyWith(
      status: CommentFilterStatus.loading,
      originalComment: comment,
      errorMessage: null,
    ));

    try {
      final result = await _service.filterComment(comment, userId: userId);
      emit(state.copyWith(
        status: CommentFilterStatus.success,
        sanitizedComment: result.sanitizedText,
        flaggedTerms: result.flaggedTerms,
        toxicityScore: result.toxicityScore,
        shouldBlock: result.shouldBlock,
        reason: result.reason,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CommentFilterStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void reset() {
    emit(const CommentFilterState());
  }
}
