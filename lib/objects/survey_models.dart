import 'package:cloud_firestore/cloud_firestore.dart';

enum SurveyQuestionType {
  singleChoice,
  multiChoice,
  shortText,
  longText,
  scale, // e.g., 1–5
}

SurveyQuestionType _parseQuestionType(String raw) {
  switch (raw) {
    case 'single':
    case 'singleChoice':
      return SurveyQuestionType.singleChoice;
    case 'multi':
    case 'multiChoice':
      return SurveyQuestionType.multiChoice;
    case 'shortText':
    case 'short':
      return SurveyQuestionType.shortText;
    case 'longText':
    case 'long':
      return SurveyQuestionType.longText;
    case 'scale':
      return SurveyQuestionType.scale;
    default:
      return SurveyQuestionType.singleChoice;
  }
}

String _questionTypeToString(SurveyQuestionType t) {
  switch (t) {
    case SurveyQuestionType.singleChoice:
      return 'singleChoice';
    case SurveyQuestionType.multiChoice:
      return 'multiChoice';
    case SurveyQuestionType.shortText:
      return 'shortText';
    case SurveyQuestionType.longText:
      return 'longText';
    case SurveyQuestionType.scale:
      return 'scale';
  }
}

class SurveyOption {
  final String id;
  final String label;
  final Map<String, dynamic>? tags; // optional mapping to product tags/weights
  final int? value; // for scale questions

  SurveyOption({
    required this.id,
    required this.label,
    this.tags,
    this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      if (tags != null) 'tags': tags,
      if (value != null) 'value': value,
    };
  }

  factory SurveyOption.fromMap(Map<String, dynamic> map) {
    return SurveyOption(
      id: map['id'] as String,
      label: map['label'] as String,
      tags: (map['tags'] as Map?)?.cast<String, dynamic>(),
      value: map['value'] as int?,
    );
  }
}

class SurveyQuestion {
  final String id;
  final String text;
  final SurveyQuestionType type;
  final List<SurveyOption> options;
  final int displayOrder;
  final String? helpText;
  final String version;

  SurveyQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.displayOrder,
    required this.version,
    this.helpText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': _questionTypeToString(type),
      'options': options.map((e) => e.toMap()).toList(),
      'displayOrder': displayOrder,
      'helpText': helpText,
      'version': version,
    };
  }

  factory SurveyQuestion.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SurveyQuestion(
      id: data['id'] as String? ?? doc.id,
      text: data['text'] as String,
      type: _parseQuestionType(data['type'] as String),
      options: ((data['options'] as List?) ?? [])
          .map((e) => SurveyOption.fromMap((e as Map).cast<String, dynamic>()))
          .toList(),
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
      helpText: data['helpText'] as String?,
      version: data['version'] as String? ?? 'v1',
    );
  }
}

class SurveyAnswer {
  final String questionId;
  final dynamic value; // String | List<String> | int

  SurveyAnswer({
    required this.questionId,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'value': value,
    };
  }
}

class SurveyResponse {
  final String? id;
  final String? userId; // nullable for anonymous
  final String version;
  final List<SurveyAnswer> answers;
  final DateTime createdAt;
  final String channel; // 'app', 'web', 'form'

  SurveyResponse({
    this.id,
    required this.userId,
    required this.version,
    required this.answers,
    required this.createdAt,
    required this.channel,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'version': version,
      'answers': answers.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'channel': channel,
    };
  }
}
