import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
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
      final nextSingle = <String, String>{};
      final nextMulti = <String, List<String>>{};
      for (final q in questionsData) {
        final String qId = q['id'] as String;
        final String qText = q['text'] as String;
        final String type = (q['type'] as String?) ?? 'singleChoice';
        final List<dynamic> options = (q['options'] as List).toList();
        final dynamic rawValue = raw[qText];

        if (type == 'multiChoice') {
          final List<dynamic> rawList = rawValue is List
              ? rawValue
              : rawValue is String
                  ? [rawValue]
                  : const [];
          final matched = <String>[];
          for (final dynamic value in rawList) {
            final match = _matchOptionId(options, value);
            if (match != null) {
              matched.add(match);
            }
          }
          if (matched.isNotEmpty) {
            nextMulti[qId] = matched;
          }
        } else {
          if (rawValue is! String) continue;
          final optId = _matchOptionId(options, rawValue);
          if (optId != null) {
            nextSingle[qId] = optId;
          }
        }
      }
      if (nextSingle.isNotEmpty || nextMulti.isNotEmpty) {
        emit(state.copyWith(
          singleAnswers: nextSingle.isNotEmpty
              ? nextSingle
              : state.singleAnswers,
          multiAnswers:
              nextMulti.isNotEmpty ? nextMulti : state.multiAnswers,
        ));
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

  void toggleMulti(String questionId, String optionId) {
    final next = Map<String, List<String>>.from(state.multiAnswers);
    final list = List<String>.from(next[questionId] ?? const []);
    if (list.contains(optionId)) {
      list.remove(optionId);
    } else {
      list.add(optionId);
    }
    if (list.isEmpty) {
      next.remove(questionId);
    } else {
      next[questionId] = list;
    }
    emit(state.copyWith(multiAnswers: next, error: null));
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
        final String type = (q['type'] as String?) ?? 'singleChoice';
        final List<dynamic> options = (q['options'] as List).toList();

        if (type == 'multiChoice') {
          final selectedIds = state.multiAnswers[qId] ?? const [];
          if (selectedIds.isEmpty) continue;
          final labels = <String>[];
          for (final id in selectedIds) {
            final label = _matchOptionLabel(options, id) ?? id;
            labels.add(label);
          }
          raw[qText] = labels;
        } else {
          final String? selectedId = state.singleAnswers[qId];
          if (selectedId == null) continue;
          final String label =
              _matchOptionLabel(options, selectedId) ?? selectedId;
          raw[qText] = label;
        }
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

      // Update local database profile immediately so recommendations update
      Database().userSurveyProfile = raw;

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

String? _matchOptionId(List<dynamic> options, dynamic value) {
  for (final dynamic o in options) {
    if (o is Map) {
      final m = Map<String, dynamic>.from(o);
      if (m['label'] == value) {
        return m['id'] as String?;
      }
    }
  }
  return null;
}

String? _matchOptionLabel(List<dynamic> options, String id) {
  for (final dynamic o in options) {
    if (o is Map) {
      final m = Map<String, dynamic>.from(o);
      if (m['id'] == id) {
        return m['label'] as String?;
      }
    }
  }
  return null;
}
