import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/config/api_config.dart';
import '../../onboarding/data/burnout_baseline_questions.dart';
import 'log_api.dart';

class WeeklyAssessmentApi {
  static Future<int> _userId() async {
    final id = await LogApi.getStoredUserId();
    if (id == null) throw Exception('Missing logged-in user');
    return id;
  }

  static Future<Map<String, dynamic>?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>> _post(
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.logs('/weekly-assessment')),
          headers: await ApiConfig.jsonHeaders(),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));
    Map<String, dynamic>? data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      // Authentication and validation failures can also have non-JSON bodies.
    }
    if (response.statusCode >= 400) {
      throw _WeeklyRequestError(
        data?['message']?.toString() ?? 'Unable to save weekly log',
        response.statusCode,
      );
    }
    if (data == null) throw const FormatException('Invalid weekly response');
    return data;
  }

  static final Map<int, Future<Map<String, dynamic>>> _loads = {};
  static final Map<int, Future<void>> _operations = {};

  static Future<T> _serialize<T>(int id, Future<T> Function() operation) async {
    final previous = _operations[id] ?? Future<void>.value();
    final result = previous.then((_) => operation());
    final finished = result.then<void>((_) {}, onError: (Object _) {});
    _operations[id] = finished;
    try {
      return await result;
    } finally {
      if (identical(_operations[id], finished)) _operations.remove(id);
    }
  }

  static Future<Map<String, dynamic>> load() async {
    final id = await _userId();
    if (_loads[id] != null) return _loads[id]!;
    final future = _serialize(id, () => _loadForUser(id));
    _loads[id] = future;
    try {
      return await future;
    } finally {
      _loads.remove(id);
    }
  }

  static Future<Map<String, dynamic>> _loadForUser(int userId) async {
    final key = 'weekly_assessment_cache_$userId';
    final pendingKey = 'weekly_assessment_pending_$userId';
    var pending = await _read(pendingKey) ?? <String, dynamic>{};
    String? syncError;
    for (final cycle in pending.keys.toList()..sort()) {
      try {
        await _post(Map<String, dynamic>.from(pending[cycle] as Map));
        pending.remove(cycle);
        await _write(pendingKey, pending);
      } on _WeeklyRequestError catch (error) {
        syncError = error.message;
        if (error.status >= 500 || error.status == 401) break;
      } catch (_) {
        break;
      }
    }
    Map<String, dynamic> data;
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.logs('/weekly-assessment')}?date=${LogApi.todayKey()}',
            ),
            headers: await ApiConfig.jsonHeaders(),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 400) {
        throw _WeeklyRequestError(
          'Unable to load weekly logs',
          response.statusCode,
        );
      }
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      data['_cached_for_date'] = LogApi.todayKey();
      await _write(key, data);
    } on _WeeklyRequestError catch (error) {
      if (error.status < 500) rethrow;
      data = await _read(key) ?? <String, dynamic>{};
      data['is_offline'] = true;
    } catch (_) {
      data = await _read(key) ?? <String, dynamic>{};
      data['is_offline'] = true;
    }
    if (data['_cached_for_date'] != LogApi.todayKey()) {
      data['today'] = null;
      data['completed_today'] = false;
      data['due_date'] = data['next_due_date'];
    }
    final due = data['due_date']?.toString();
    if (data['completed_today'] != true && due != null) {
      data['is_due'] = due.compareTo(LogApi.todayKey()) <= 0;
    }
    data['pending'] = pending;
    data['sync_error'] = syncError;
    return data;
  }

  static Future<bool> save(String dueDate, Map<String, int> answers) async {
    final userId = await _userId();
    final snapshot = Map<String, int>.from(answers);
    return _serialize(userId, () => _saveForUser(userId, dueDate, snapshot));
  }

  static Future<bool> _saveForUser(
    int userId,
    String dueDate,
    Map<String, int> answers,
  ) async {
    final payload = <String, dynamic>{
      'questionnaire_version': kWeeklyQuestionnaireVersion,
      'due_date': dueDate,
      'response_date': LogApi.todayKey(),
      'answers': answers,
    };
    final key = 'weekly_assessment_pending_$userId';
    final pending = await _read(key) ?? <String, dynamic>{};
    var online = true;
    try {
      await _post(payload);
      pending.remove(dueDate);
    } on _WeeklyRequestError catch (error) {
      if (error.status < 500) rethrow;
      online = false;
      pending[dueDate] = payload;
    } catch (_) {
      online = false;
      pending[dueDate] = payload;
    }
    await _write(key, pending);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weekly_assessment_draft_${userId}_$dueDate');
    return online;
  }

  static Future<Map<String, int>> draft(String dueDate) async {
    final id = await _userId();
    final pending = await _read('weekly_assessment_pending_$id');
    final queued = pending?[dueDate];
    final stored = await _read('weekly_assessment_draft_${id}_$dueDate');
    final answers =
        stored?['answers'] ?? (queued is Map ? queued['answers'] : null);
    return answers is Map ? Map<String, int>.from(answers) : {};
  }

  static Future<void> saveDraft(
    String dueDate,
    Map<String, int> answers,
  ) async {
    final id = await _userId();
    await _write('weekly_assessment_draft_${id}_$dueDate', {
      'questionnaire_version': kWeeklyQuestionnaireVersion,
      'answers': answers,
    });
  }

  static Future<void> _draftQueue = Future<void>.value();

  /// Keeps only the 11 weekly items with valid 1-5 answers.
  static Map<String, int> weeklyAnswersOnly(Object? raw) {
    if (raw is! Map) return {};
    return {
      for (final section in kBurnoutWeeklySections)
        for (final question in section.questions)
          if (raw[question.questionKey] case final num value
              when value >= 1 && value <= 5)
            question.questionKey: value.toInt(),
    };
  }

  /// Loads the weekly reflection shown below the daily check-in on weekly days.
  ///
  /// [fallbackDueDate] comes from the daily check-in schedule and is used when
  /// the weekly endpoint is unavailable.
  static Future<WeeklyReflectionState> loadReflection({
    String? fallbackDueDate,
  }) async {
    Map<String, dynamic>? data;
    try {
      data = await load();
    } catch (_) {
      // Fall back to the daily schedule so the questions can still be answered.
    }
    final completedToday = data?['completed_today'] == true;
    final isDue = data?['is_due'] == true;
    String? resolvedDueDate;
    if (completedToday || isDue) {
      resolvedDueDate = data?['due_date']?.toString();
    }
    final dueDate = resolvedDueDate ?? fallbackDueDate;
    if (dueDate == null) return const WeeklyReflectionState();

    final today = data?['today'];
    final answers = weeklyAnswersOnly(today is Map ? today['answers'] : null);
    try {
      answers.addAll(weeklyAnswersOnly(await draft(dueDate)));
    } catch (_) {
      // Drafts are optional.
    }
    final pending = data?['pending'];
    final queued = pending is Map && pending.containsKey(dueDate);
    return WeeklyReflectionState(
      dueDate: dueDate,
      answers: answers,
      isSaved: completedToday || queued,
    );
  }

  /// Persists draft answers in order so a slower write never overwrites a
  /// newer one.
  static Future<void> queueDraft(String dueDate, Map<String, int> answers) {
    final snapshot = Map<String, int>.from(answers);
    _draftQueue = _draftQueue
        .catchError((Object _) {})
        .then((_) => saveDraft(dueDate, snapshot));
    return _draftQueue.catchError((Object _) {});
  }

  /// Saves the inline weekly reflection. Returns false when queued offline.
  static Future<bool> saveReflection(WeeklyReflectionState state) async {
    final dueDate = state.dueDate;
    if (dueDate == null) return true;
    await _draftQueue.catchError((Object _) {});
    return save(dueDate, state.answers);
  }
}

/// Weekly reflection answers rendered inline below the daily check-in.
class WeeklyReflectionState {
  final String? dueDate;
  final Map<String, int> answers;
  final bool isSaved;

  const WeeklyReflectionState({
    this.dueDate,
    this.answers = const {},
    this.isSaved = false,
  });

  bool get isAvailable => dueDate != null;
  bool get isPending => isAvailable && !isSaved;
  bool get isAnswered => answers.length >= kWeeklyQuestionCount;

  WeeklyReflectionState withAnswer(String questionKey, int value) {
    return WeeklyReflectionState(
      dueDate: dueDate,
      answers: {...answers, questionKey: value},
      isSaved: isSaved,
    );
  }

  WeeklyReflectionState markSaved() {
    return WeeklyReflectionState(
      dueDate: dueDate,
      answers: answers,
      isSaved: true,
    );
  }
}

class _WeeklyRequestError implements Exception {
  final String message;
  final int status;
  const _WeeklyRequestError(this.message, this.status);
  @override
  String toString() => message;
}
