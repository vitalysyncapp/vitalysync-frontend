import 'dart:convert';
import 'dart:math';

import '../../onboarding/models/onboarding_question.dart';

const cbiAssessmentEnabled = bool.fromEnvironment(
  'CBI_ASSESSMENT_ENABLED',
  defaultValue: true,
);

Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

class AssessmentItem {
  final String id;
  final String text;
  final bool required;
  final String type;

  const AssessmentItem(this.id, this.text, this.required, this.type);
}

class AssessmentDefinition {
  final Map<String, dynamic> _json;
  final List<AssessmentItem> items;
  final List<LikertOption> options;

  AssessmentDefinition._(this._json, this.items, this.options);

  factory AssessmentDefinition.fromJson(Map<String, dynamic> json) {
    final data = _copy(json);
    final items = (data['items'] as List)
        .map((raw) {
          final item = raw as Map;
          return AssessmentItem(
            item['question_id'] as String,
            item['text'] as String,
            item['required'] as bool,
            item['type'] as String,
          );
        })
        .toList(growable: false);
    final options = (data['response_options'] as List)
        .map((raw) {
          final option = raw as Map;
          return LikertOption(
            value: option['value'] as int,
            label: option['label'] as String,
          );
        })
        .toList(growable: false);
    if (data['language'] != 'en' ||
        data['translation_allowed'] != false ||
        items.length != 10 ||
        items.map((item) => item.id).toSet().length != 10 ||
        items.where((item) => item.required && item.type == 'cbi').length !=
            6 ||
        items
                .where((item) => !item.required && item.type == 'context')
                .length !=
            4 ||
        options.length != 5 ||
        List.generate(5, (i) => options[i].value != i + 1).any((bad) => bad) ||
        jsonEncode(data['presentation_order']) !=
            jsonEncode(items.map((item) => item.id).toList())) {
      throw const FormatException('Unsupported assessment definition.');
    }
    for (final key in identityKeys) {
      if (data[key] is! String || (data[key] as String).isEmpty) {
        throw const FormatException('Incomplete assessment definition.');
      }
    }
    return AssessmentDefinition._(
      data,
      List.unmodifiable(items),
      List.unmodifiable(options),
    );
  }

  static const identityKeys = [
    'instrument',
    'instrument_version',
    'definition_version',
    'scoring_version',
    'context_version',
    'language',
  ];
  String get version => _json['definition_version'] as String;
  String get title => _json['title'] as String;
  String get explanation => _json['explanation'] as String;
  String get contextExplanation => _json['context_explanation'] as String;
  List<String> get attributions => (_json['sources'] as List)
      .map((source) => '${source['citation']} ${source['url']}')
      .toList();
  Map<String, dynamic> toJson() => _copy(_json);
  Map<String, dynamic> get identity => {
    for (final key in identityKeys) key: _json[key],
  };

  bool isComplete(Map<String, int> answers) => items
      .where((item) => item.required)
      .every(
        (item) => (answers[item.id] ?? 0) >= 1 && (answers[item.id] ?? 0) <= 5,
      );
}

class AssessmentSubmission {
  final Map<String, dynamic> _payload;
  AssessmentSubmission.fromJson(Map<String, dynamic> json)
    : _payload = _copy(json);

  factory AssessmentSubmission.create(
    AssessmentDefinition definition,
    Map<String, int> answers, {
    DateTime? now,
  }) {
    if (!definition.isComplete(answers)) {
      throw const FormatException('Answer all six CBI questions.');
    }
    if (answers.entries.any(
      (entry) =>
          !definition.items.any((item) => item.id == entry.key) ||
          entry.value < 1 ||
          entry.value > 5,
    )) {
      throw const FormatException('Invalid assessment answers.');
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    final completion = DateTime.fromMillisecondsSinceEpoch(
      (now ?? DateTime.now()).millisecondsSinceEpoch,
      isUtc: true,
    );
    return AssessmentSubmission.fromJson({
      ...definition.identity,
      'submission_id': id,
      'completed_at': completion.toIso8601String(),
      'answers': [
        for (final item in definition.items)
          if (answers.containsKey(item.id))
            {'question_id': item.id, 'response': answers[item.id]},
      ],
    });
  }
  String get id => _payload['submission_id'] as String;
  DateTime get completedAt =>
      DateTime.parse(_payload['completed_at'] as String);
  Map<String, dynamic> toJson() => _copy(_payload);
}

class AssessmentRecord {
  final Map<String, dynamic> _json;
  AssessmentRecord.fromJson(Map<String, dynamic> json) : _json = _copy(json);
  String get id => _json['assessment_id'] as String;
  String get submissionId => _json['submission_id'] as String;
  String get version => _json['definition_version'] as String;
  DateTime get completedAt => DateTime.parse(_json['completed_at'] as String);
  String get displayScore =>
      (_json['result'] as Map)['display_score'] as String;
  Map<String, dynamic> toJson() => _copy(_json);
}

class AssessmentHistory {
  final List<AssessmentRecord> assessments;
  final String? nextCursor;
  const AssessmentHistory(this.assessments, this.nextCursor);
}
