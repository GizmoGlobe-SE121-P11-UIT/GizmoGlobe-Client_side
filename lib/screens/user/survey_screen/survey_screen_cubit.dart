import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/survey_service.dart';
import 'survey_screen_state.dart';
import 'survey_data.dart';

class SurveyScreenCubit extends Cubit<SurveyScreenState> {
  SurveyScreenCubit({SurveyService? service})
      : _service = service ?? SurveyService(),
        super(const SurveyScreenState());

  final SurveyService _service;

  List<Map<String, dynamic>> get questionsData =>
      List<Map<String, dynamic>>.from(kSurveyQuestionsData)
        ..sort((a, b) =>
            (a['displayOrder'] as int).compareTo(b['displayOrder'] as int));

  int get total => questionsData.length;

  /// Load existing selections from Firestore (current user only) and prefill state
  Future<void> loadExistingSelections() async {
    try {
      final raw = await _service.getCurrentUserRaw();
      if (raw == null) return;
      final next = <String, String>{};
      for (final q in questionsData) {
        final String qId = q['id'] as String;
        final String qText = q['text'] as String;
        final dynamic rawValue = raw[qText];
        if (rawValue is! String) continue;
        // Find matching option id by label
        final List<dynamic> options = (q['options'] as List).toList();
        String? optId;
        for (final dynamic o in options) {
          if (o is Map) {
            final m = Map<String, dynamic>.from(o);
            if (m['label'] == rawValue) {
              optId = m['id'] as String?;
              break;
            }
          }
        }
        if (optId != null) {
          next[qId] = optId;
        }
      }
      if (next.isNotEmpty) {
        emit(state.copyWith(singleAnswers: next));
      }
    } catch (_) {
      // ignore errors, leave state as-is
    }
  }

  void selectSingle(String questionId, String optionId) {
    final next = Map<String, String>.from(state.singleAnswers);
    next[questionId] = optionId;
    emit(state.copyWith(singleAnswers: next, error: null));
  }

  void next() {
    if (state.currentIndex < total - 1) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
    }
  }

  void back() {
    if (state.currentIndex > 0) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

  Future<void> submit() async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, error: null));
    try {
      // Build "form-like" raw: question text -> option label, plus Excel timestamp
      final Map<String, dynamic> raw = {};
      for (final q in questionsData) {
        final String qId = q['id'] as String;
        final String qText = q['text'] as String;
        final String? selectedId = state.singleAnswers[qId];
        if (selectedId == null) continue;
        final List<dynamic> options = (q['options'] as List).toList();
        String? labelValue;
        for (final dynamic o in options) {
          if (o is Map) {
            final m = Map<String, dynamic>.from(o);
            if (m['id'] == selectedId) {
              labelValue = m['label'] as String?;
              break;
            }
          }
        }
        final String label = labelValue ?? selectedId;
        raw[qText] = label;
      }
      // Excel serial number for current time (days since 1899-12-30)
      final DateTime now = DateTime.now();
      final double excelSerial =
          now.millisecondsSinceEpoch / 86400000.0 + 25569.0;
      raw['Dấu thời gian'] = excelSerial;

      final responseData = <String, dynamic>{
        'submittedAt': Timestamp.fromDate(now),
        'channel': 'app',
        'version': 'v1',
        'raw': raw,
      };

      await _service.submitRaw(responseData);
      emit(state.copyWith(submitting: false));
    } catch (e, st) {
      // ignore: avoid_print
      print('Survey submit exception: $e');
      // ignore: avoid_print
      print(st);
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}
