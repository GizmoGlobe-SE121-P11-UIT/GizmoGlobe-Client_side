import 'package:equatable/equatable.dart';

class SurveyScreenState extends Equatable {
  final int currentIndex;
  final Map<String, String> singleAnswers; // questionId -> optionId
  final Map<String, List<String>> multiAnswers; // questionId -> optionIds
  final bool submitting;
  final String? error;

  const SurveyScreenState({
    this.currentIndex = 0,
    this.singleAnswers = const {},
    this.multiAnswers = const {},
    this.submitting = false,
    this.error,
  });

  SurveyScreenState copyWith({
    int? currentIndex,
    Map<String, String>? singleAnswers,
    Map<String, List<String>>? multiAnswers,
    bool? submitting,
    String? error,
  }) {
    return SurveyScreenState(
      currentIndex: currentIndex ?? this.currentIndex,
      singleAnswers: singleAnswers ?? this.singleAnswers,
      multiAnswers: multiAnswers ?? this.multiAnswers,
      submitting: submitting ?? this.submitting,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [currentIndex, singleAnswers, multiAnswers, submitting, error];
}
