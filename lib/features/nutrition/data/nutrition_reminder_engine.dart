import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import '../../../shared/notifications/local_notification_service.dart';
import '../../../shared/preferences/app_preferences.dart';
import '../../../shared/preferences/user_session.dart';
import 'nutrition_analyzer.dart';
import 'nutrition_api.dart';
import 'nutrition_coach.dart';
import 'nutrition_insight_store.dart';

enum NutritionReminderType {
  morningBreakfast,
  missedLogging,
  patternSuggestion,
  inactivityReengagement,
}

class NutritionReminderDecision {
  final NutritionReminderType type;
  final String title;
  final String body;
  final NutritionConfidence confidence;
  final bool wasSent;

  const NutritionReminderDecision({
    required this.type,
    required this.title,
    required this.body,
    required this.confidence,
    required this.wasSent,
  });
}

class NutritionReminderEvaluation {
  final NutritionAnalysis analysis;
  final NutritionInsight? insight;
  final NutritionReminderDecision? notificationDecision;

  const NutritionReminderEvaluation({
    required this.analysis,
    required this.insight,
    required this.notificationDecision,
  });
}

class NutritionReminderEngine {
  NutritionReminderEngine._();

  static const Duration _assistantInsightCacheMaxAge = Duration(minutes: 45);

  static final NutritionReminderEngine instance = NutritionReminderEngine._();

  final NutritionInsightStore _store = NutritionInsightStore.instance;

  Future<NutritionReminderEvaluation?> evaluate({
    bool allowNotification = true,
    bool updateStoredInsight = true,
  }) async {
    final now = DateTime.now();
    final session = await UserSessionController.instance.load();
    if (session.userId == null) {
      return null;
    }

    await AppPreferencesController.instance.load();
    final prefs = AppPreferencesController.instance.notifier.value;
    final window = await _loadSevenDayWindow(now);
    if (!window.hasReliableData) {
      return null;
    }

    final analysis = NutritionAnalyzer.analyze(days: window.days, now: now);
    final insight = updateStoredInsight
        ? await _generateAndStoreInsight(analysis, now)
        : await _store.readLastInsight();
    final decision =
        allowNotification &&
            prefs.notificationsEnabled &&
            prefs.mealReminderEnabled
        ? await _maybeSendNotification(analysis, now)
        : null;

    return NutritionReminderEvaluation(
      analysis: analysis,
      insight: insight,
      notificationDecision: decision,
    );
  }

  Future<NutritionInsight?> assistantInsightForToday({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final staleCachedInsight = await _store.readAssistantInsightForToday(
      now: now,
    );

    if (!forceRefresh) {
      final cached = await _store.readAssistantInsightForToday(
        now: now,
        maxAge: _assistantInsightCacheMaxAge,
        allowStale: false,
      );
      if (cached != null) {
        final status = await _store.readFeedbackStatus(cached.id);
        if (status != 'dismissed') {
          return cached;
        }
      }
    }

    try {
      final backendInsight = await _fetchBackendAssistantInsight(now: now);
      if (backendInsight != null) {
        final status = await _store.readFeedbackStatus(backendInsight.id);
        if (status == 'dismissed') {
          return null;
        }

        await _store.markAssistantShownToday(now: now);
        await _store.rememberMessage(backendInsight.message, at: now);
        await _store.saveAssistantInsightForToday(backendInsight, now: now);
        return backendInsight;
      }
    } catch (_) {
      if (staleCachedInsight != null) {
        final status = await _store.readFeedbackStatus(staleCachedInsight.id);
        if (status != 'dismissed') {
          return staleCachedInsight;
        }
      }

      // Fall back to local deterministic nutrition signals when the API is not reachable.
    }

    final evaluation = await evaluate(allowNotification: false);
    final analysis = evaluation?.analysis;
    final lastInsight = evaluation?.insight ?? await _store.readLastInsight();

    if (analysis == null) {
      if (lastInsight == null || !_isSameDate(lastInsight.generatedAt, now)) {
        return null;
      }

      if (!await _store.canUseMessage(lastInsight.message, now: now)) {
        return null;
      }

      final insight = lastInsight.copyWith(
        title: 'Nutrition check-in',
        source: 'nutrition_assistant',
        generatedAt: now,
      );
      await _store.markAssistantShownToday(now: now);
      await _store.rememberMessage(insight.message, at: now);
      await _store.saveAssistantInsightForToday(insight, now: now);
      return insight;
    }

    final candidates = NutritionCoach.buildAssistantCandidates(
      analysis: analysis,
      baseInsight: lastInsight,
      now: now,
    );
    for (final candidate in candidates) {
      if (await _store.canUseMessage(candidate.message, now: now)) {
        await _store.markAssistantShownToday(now: now);
        await _store.rememberMessage(candidate.message, at: now);
        await _store.saveAssistantInsightForToday(candidate, now: now);
        return candidate;
      }
    }

    final cached = await _store.readAssistantInsightForToday(now: now);
    if (cached != null) {
      return cached;
    }

    if (lastInsight != null && lastInsight.message.trim().isNotEmpty) {
      final insight = lastInsight.copyWith(
        id: 'assistant_${lastInsight.id}',
        title: 'Nutrition check-in',
        source: 'nutrition_assistant',
        generatedAt: now,
      );
      await _store.saveAssistantInsightForToday(insight, now: now);
      return insight;
    }

    return null;
  }

  Future<NutritionInsight?> _fetchBackendAssistantInsight({
    required DateTime now,
  }) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (userId == null) {
      return null;
    }

    final uri = Uri.parse(ApiConfig.nutrition('/assistant-nudge')).replace(
      queryParameters: {
        'user_id': userId.toString(),
        'date': _dateKey(now),
        'ai': 'true',
      },
    );
    final response = await http
        .get(uri, headers: await ApiConfig.acceptJsonHeaders())
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Nutrition nudge unavailable');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return null;
    }

    final data = Map<String, dynamic>.from(decoded);
    if ((data['message']?.toString() ?? '').trim().isEmpty) {
      return null;
    }

    return NutritionInsight.fromJson(data);
  }

  Future<NutritionInsight?> _generateAndStoreInsight(
    NutritionAnalysis analysis,
    DateTime now,
  ) async {
    final candidates = NutritionCoach.buildCandidates(
      analysis: analysis,
      now: now,
    );

    for (final candidate in candidates) {
      if (await _store.canUseMessage(candidate.message, now: now)) {
        await _store.saveInsight(candidate);
        return candidate;
      }
    }

    return _store.readLastInsight();
  }

  Future<NutritionReminderDecision?> _maybeSendNotification(
    NutritionAnalysis analysis,
    DateTime now,
  ) async {
    final candidate = _selectReminderCandidate(analysis, now);
    if (candidate == null) {
      return null;
    }

    if (await _store.hasSentNutritionPushToday(now: now)) {
      return NutritionReminderDecision(
        type: candidate.type,
        title: candidate.title,
        body: candidate.messages.first,
        confidence: candidate.confidence,
        wasSent: false,
      );
    }

    final body = await _firstFreshMessage(candidate.messages, now);
    if (body == null) {
      return NutritionReminderDecision(
        type: candidate.type,
        title: candidate.title,
        body: candidate.messages.first,
        confidence: candidate.confidence,
        wasSent: false,
      );
    }

    await LocalNotificationService.instance.showNutritionReminderNow(
      title: candidate.title,
      body: body,
      payload: 'nutrition_log:${candidate.type.name}',
      notificationType: 'nutrition_${candidate.type.name}',
      metadata: {
        'confidence': candidate.confidence.label,
        'reminder_type': candidate.type.name,
      },
    );
    await _store.markNutritionPushSentToday(now: now);
    await _store.rememberMessage(body, at: now);

    return NutritionReminderDecision(
      type: candidate.type,
      title: candidate.title,
      body: body,
      confidence: candidate.confidence,
      wasSent: true,
    );
  }

  _ReminderCandidate? _selectReminderCandidate(
    NutritionAnalysis analysis,
    DateTime now,
  ) {
    if (_isMorningWindow(now) && !analysis.breakfastLoggedToday) {
      return const _ReminderCandidate(
        type: NutritionReminderType.morningBreakfast,
        title: 'Meal reminder',
        messages: [
          'Good morning 🌤️ Just a small reminder—having breakfast can help keep your energy steady today. Want to log it?',
          'Good morning. A small breakfast log can help keep today\'s nutrition picture clearer.',
        ],
        confidence: NutritionConfidence.low,
      );
    }

    if (analysis.missingBreakfastDays >= 2) {
      return _ReminderCandidate(
        type: NutritionReminderType.patternSuggestion,
        title: 'Nutrition pattern',
        messages: const [
          'Breakfast is missing from a few recent logs. A light morning meal might help maintain your energy.',
          'A few recent logs do not include breakfast. Something light in the morning may support steadier energy.',
        ],
        confidence: analysis.missingBreakfastDays >= 4
            ? NutritionConfidence.high
            : NutritionConfidence.medium,
      );
    }

    if (analysis.inactiveLoggingDays >= 2) {
      return const _ReminderCandidate(
        type: NutritionReminderType.inactivityReengagement,
        title: 'Meal logging check-in',
        messages: [
          'It’s been a while since your last meal log. Want to start tracking again?',
          'Meal logging has been quiet for a bit. You can restart with just one quick entry.',
        ],
        confidence: NutritionConfidence.high,
      );
    }

    if (analysis.noMealsLoggedToday && now.hour >= 13) {
      return const _ReminderCandidate(
        type: NutritionReminderType.missedLogging,
        title: 'Meal log reminder',
        messages: [
          'No meals logged today yet. You can quickly add one whenever you’re ready.',
          'No meal logs are in for today yet. A quick entry is enough when you’re ready.',
        ],
        confidence: NutritionConfidence.low,
      );
    }

    return null;
  }

  Future<String?> _firstFreshMessage(
    List<String> messages,
    DateTime now,
  ) async {
    for (final message in messages) {
      if (await _store.canUseMessage(message, now: now)) {
        return message;
      }
    }

    return null;
  }

  Future<_NutritionWindow> _loadSevenDayWindow(DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final snapshots = <NutritionDaySnapshot>[];
    var successfulLoads = 0;

    for (var offset = 6; offset >= 0; offset -= 1) {
      final date = today.subtract(Duration(days: offset));
      final result = await _loadDay(date);
      snapshots.add(result.snapshot);
      if (result.wasLoaded) {
        successfulLoads += 1;
      }
    }

    return _NutritionWindow(
      days: snapshots,
      hasReliableData: successfulLoads == 7,
    );
  }

  Future<_LoadedNutritionDay> _loadDay(DateTime date) async {
    try {
      final summary = await NutritionApi.fetchDaily(date: _dateKey(date));
      return _LoadedNutritionDay(
        snapshot: NutritionDaySnapshot(date: date, summary: summary),
        wasLoaded: true,
      );
    } catch (_) {
      return _LoadedNutritionDay(
        snapshot: NutritionDaySnapshot(
          date: date,
          summary: DailyNutritionSummary.empty(),
        ),
        wasLoaded: false,
      );
    }
  }

  bool _isMorningWindow(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    return minutes >= 6 * 60 && minutes <= 10 * 60;
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _dateKey(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().substring(0, 10);
  }
}

class _ReminderCandidate {
  final NutritionReminderType type;
  final String title;
  final List<String> messages;
  final NutritionConfidence confidence;

  const _ReminderCandidate({
    required this.type,
    required this.title,
    required this.messages,
    required this.confidence,
  });
}

class _NutritionWindow {
  final List<NutritionDaySnapshot> days;
  final bool hasReliableData;

  const _NutritionWindow({required this.days, required this.hasReliableData});
}

class _LoadedNutritionDay {
  final NutritionDaySnapshot snapshot;
  final bool wasLoaded;

  const _LoadedNutritionDay({required this.snapshot, required this.wasLoaded});
}
