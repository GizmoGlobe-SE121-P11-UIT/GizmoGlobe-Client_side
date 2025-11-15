import 'package:equatable/equatable.dart';

class SurveyScreenState extends Equatable {
  final int currentIndex;
  final Map<String, String> singleAnswers; // questionId -> optionId
  final bool submitting;
  final String? error;

  const SurveyScreenState({
    this.currentIndex = 0,
    this.singleAnswers = const {},
    this.submitting = false,
    this.error,
  });

  SurveyScreenState copyWith({
    int? currentIndex,
    Map<String, String>? singleAnswers,
    bool? submitting,
    String? error,
  }) {
    return SurveyScreenState(
      currentIndex: currentIndex ?? this.currentIndex,
      singleAnswers: singleAnswers ?? this.singleAnswers,
      submitting: submitting ?? this.submitting,
      error: error,
    );
  }

  @override
  List<Object?> get props => [currentIndex, singleAnswers, submitting, error];
}
