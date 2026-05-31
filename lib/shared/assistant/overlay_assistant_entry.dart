import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_theme.dart';
import '../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../features/activity/data/activity_service.dart';
import '../../features/exercise/data/exercise_goal_service.dart';
import '../../features/exercise/data/exercise_recommendation_model.dart';
import '../../features/exercise/data/exercise_recommendation_service.dart';
import '../../features/home/data/environment_model.dart';
import '../../features/nutrition/data/nutrition_coach.dart';
import '../../features/nutrition/data/nutrition_reminder_engine.dart';
import '../preferences/app_preferences.dart';
import '../preferences/user_session.dart';
import 'floating_smart_nudge_assistant.dart';
import 'overlay_assistant_controller.dart';

Future<void> runOverlayAssistantApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferencesController.instance.load();
  final prefs = AppPreferencesController.instance.notifier.value;
  final session = await UserSessionController.instance.load();
  if (!prefs.assistantOverlayEnabled ||
      !session.isLoggedIn ||
      !session.hasAuthToken ||
      session.userId == null) {
    await OverlayAssistantController.instance.disableForLogout();
    runApp(const SizedBox.shrink());
    return;
  }

  unawaited(ActivityService.instance.startTracking());
  unawaited(ExerciseGoalService.instance.start());
  runApp(const _OverlayAssistantApp());
}

enum _OverlayAssistantMode { bubble, panel, reminderPreview, generatedPreview }

class _OverlayAssistantApp extends StatelessWidget {
  const _OverlayAssistantApp();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: AppPreferencesController.instance.notifier,
      builder: (context, prefs, _) {
        Intl.defaultLocale = prefs.locale.languageCode;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: prefs.locale,
          supportedLocales: const [Locale('en'), Locale('fil')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: prefs.themeMode,
          theme: buildVitalySyncLightTheme(),
          darkTheme: buildVitalySyncDarkTheme(),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(prefs.textScaleFactor),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const _OverlayAssistantShell(),
        );
      },
    );
  }
}

class _OverlayAssistantShell extends StatefulWidget {
  const _OverlayAssistantShell();

  @override
  State<_OverlayAssistantShell> createState() => _OverlayAssistantShellState();
}

class _OverlayAssistantShellState extends State<_OverlayAssistantShell> {
  static const MethodChannel _channel = MethodChannel(
    'vitalysync/assistant_overlay/window',
  );
  static const Duration _generatedPreviewInterval = Duration(minutes: 20);
  static const String _smartPreviewKey = 'overlay_preview_smart_key';
  static const String _nutritionPreviewKey = 'overlay_preview_nutrition_key';
  static const String _exercisePreviewKey = 'overlay_preview_exercise_key';

  final ExerciseRecommendationService _recommendationService =
      const ExerciseRecommendationService();

  _OverlayAssistantMode _mode = _OverlayAssistantMode.bubble;
  bool _isOpeningApp = false;
  Timer? _generatedPreviewTimer;
  List<ExerciseRecommendationModel> _recommendations = const [];
  List<AdaptiveNudgeRecommendation> _adaptiveNudges = const [];
  NutritionInsight? _nutritionInsight;
  Future<List<AdaptiveNudgeRecommendation>>? _adaptiveNudgeLoadFuture;
  Future<NutritionInsight?>? _nutritionInsightLoadFuture;
  bool _hasLoadedAdaptiveNudges = false;
  bool _hasLoadedNutritionInsight = false;
  String _reminderTitle = '';
  String _reminderBody = '';
  String _generatedPreviewKind = 'smart';
  String _generatedPreviewTitle = '';
  String _generatedPreviewBody = '';

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleNativeMethodCall);
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 6),
        () => _evaluateGeneratedPreviews(),
      ),
    );
    _generatedPreviewTimer = Timer.periodic(
      _generatedPreviewInterval,
      (_) => unawaited(_evaluateGeneratedPreviews(forceRefresh: true)),
    );
  }

  @override
  void dispose() {
    _generatedPreviewTimer?.cancel();
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (!mounted) {
      return null;
    }

    switch (call.method) {
      case 'setOverlayMode':
        final modeName = call.arguments?.toString() ?? 'bubble';
        setState(() {
          _mode = switch (modeName) {
            'panel' => _OverlayAssistantMode.panel,
            'reminder' => _OverlayAssistantMode.reminderPreview,
            'generated' => _OverlayAssistantMode.generatedPreview,
            _ => _OverlayAssistantMode.bubble,
          };
        });
        break;
      case 'showReminderPreview':
        final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});
        setState(() {
          _reminderTitle = args['title']?.toString() ?? 'Reminder';
          _reminderBody = args['body']?.toString() ?? '';
          _mode = _OverlayAssistantMode.reminderPreview;
        });
        break;
      case 'showGeneratedPreview':
        final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});
        setState(() {
          _generatedPreviewKind = args['kind']?.toString() ?? 'smart';
          _generatedPreviewTitle = args['title']?.toString() ?? 'Smart nudge';
          _generatedPreviewBody = args['body']?.toString() ?? '';
          _mode = _OverlayAssistantMode.generatedPreview;
        });
        break;
    }

    return null;
  }

  Future<void> _collapsePanel() async {
    if (_isOpeningApp) {
      return;
    }

    setState(() {
      _mode = _OverlayAssistantMode.bubble;
    });
    await OverlayAssistantController.instance.collapseOverlay();
  }

  void _openAppTo(String payload) {
    _isOpeningApp = true;
    unawaited(
      OverlayAssistantController.instance
          .openApp(payload: payload)
          .whenComplete(() async {
            await Future<void>.delayed(const Duration(seconds: 2));
            if (!mounted) {
              return;
            }
            _isOpeningApp = false;
          }),
    );
  }

  Future<List<ExerciseRecommendationModel>> _loadRecommendations() async {
    await ActivityService.instance.startTracking(refreshFromBackend: false);
    final recommendations = await _recommendationService.loadRecommendations();
    if (mounted) {
      setState(() {
        _recommendations = recommendations;
      });
    }
    return recommendations;
  }

  Future<List<AdaptiveNudgeRecommendation>> _loadAdaptiveNudges({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _adaptiveNudgeLoadFuture != null) {
      return _adaptiveNudgeLoadFuture!;
    }

    late final Future<List<AdaptiveNudgeRecommendation>> loadFuture;
    loadFuture = _loadAdaptiveNudgesInternal(forceRefresh: forceRefresh)
        .whenComplete(() {
          if (identical(_adaptiveNudgeLoadFuture, loadFuture)) {
            _adaptiveNudgeLoadFuture = null;
          }
        });
    _adaptiveNudgeLoadFuture = loadFuture;
    return loadFuture;
  }

  Future<List<AdaptiveNudgeRecommendation>> _loadAdaptiveNudgesInternal({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await AdaptiveNudgeApi.fetchAssistantRecommendations(
        limit: 3,
        forceRefresh: forceRefresh,
      );
      final recommendations = prioritizeAssistantNudges(
        response.recommendations,
      );
      if (mounted) {
        setState(() {
          _adaptiveNudges = recommendations;
          _hasLoadedAdaptiveNudges = true;
        });
      }
      return recommendations;
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLoadedAdaptiveNudges = true;
        });
      }
      return _adaptiveNudges;
    }
  }

  Future<NutritionInsight?> _loadNutritionInsight({bool forceRefresh = false}) {
    if (!forceRefresh && _nutritionInsightLoadFuture != null) {
      return _nutritionInsightLoadFuture!;
    }

    late final Future<NutritionInsight?> loadFuture;
    loadFuture = _loadNutritionInsightInternal(forceRefresh: forceRefresh)
        .whenComplete(() {
          if (identical(_nutritionInsightLoadFuture, loadFuture)) {
            _nutritionInsightLoadFuture = null;
          }
        });
    _nutritionInsightLoadFuture = loadFuture;
    return loadFuture;
  }

  Future<NutritionInsight?> _loadNutritionInsightInternal({
    bool forceRefresh = false,
  }) async {
    try {
      final insight = await NutritionReminderEngine.instance
          .assistantInsightForToday(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _nutritionInsight = insight;
          _hasLoadedNutritionInsight = true;
        });
      }
      return insight;
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLoadedNutritionInsight = true;
        });
      }
      return _nutritionInsight;
    }
  }

  Future<EnvironmentSnapshot?> _loadEnvironmentSnapshot() {
    return _recommendationService.loadEnvironmentSnapshot();
  }

  Future<void> _evaluateGeneratedPreviews({bool forceRefresh = false}) async {
    if (!mounted || _mode != _OverlayAssistantMode.bubble) {
      return;
    }

    if (await _maybePreviewSmartNudge(forceRefresh: forceRefresh)) {
      return;
    }
    if (await _maybePreviewNutritionNudge(forceRefresh: forceRefresh)) {
      return;
    }
    await _maybePreviewExerciseRecommendation();
  }

  Future<bool> _maybePreviewSmartNudge({required bool forceRefresh}) async {
    final nudges = await _loadAdaptiveNudges(forceRefresh: forceRefresh);
    if (!mounted || _mode != _OverlayAssistantMode.bubble || nudges.isEmpty) {
      return false;
    }

    final nudge = nudges.first;
    if (_isFallbackNudge(nudge)) {
      return false;
    }

    final key = _smartNudgeKey(nudge);
    if (!await _shouldShowPreview(_smartPreviewKey, key)) {
      return false;
    }

    final wasShown = await OverlayAssistantController.instance
        .showGeneratedPreview(
          kind: 'smart',
          title: _shortPreviewText(nudge.title, maxChars: 34).isEmpty
              ? 'Smart nudge'
              : _shortPreviewText(nudge.title, maxChars: 34),
          body: _shortPreviewText(nudge.message, maxChars: 108),
        );
    if (!wasShown) {
      return false;
    }

    await _rememberPreviewKey(_smartPreviewKey, key);
    return true;
  }

  Future<bool> _maybePreviewNutritionNudge({required bool forceRefresh}) async {
    final insight = await _loadNutritionInsight(forceRefresh: forceRefresh);
    if (!mounted ||
        _mode != _OverlayAssistantMode.bubble ||
        insight == null ||
        insight.message.trim().isEmpty) {
      return false;
    }

    final key = _nutritionInsightKey(insight);
    if (!await _shouldShowPreview(_nutritionPreviewKey, key)) {
      return false;
    }

    final wasShown = await OverlayAssistantController.instance
        .showGeneratedPreview(
          kind: 'nutrition',
          title: _shortPreviewText(insight.title, maxChars: 34).isEmpty
              ? 'Nutrition nudge'
              : _shortPreviewText(insight.title, maxChars: 34),
          body: _shortPreviewText(insight.message, maxChars: 108),
        );
    if (!wasShown) {
      return false;
    }

    await _rememberPreviewKey(_nutritionPreviewKey, key);
    return true;
  }

  Future<bool> _maybePreviewExerciseRecommendation() async {
    final recommendations = await _loadRecommendations();
    if (!mounted ||
        _mode != _OverlayAssistantMode.bubble ||
        recommendations.isEmpty) {
      return false;
    }

    final recommendation = recommendations.firstWhere(
      (item) => !item.isNoneToday,
      orElse: () => recommendations.first,
    );
    if (recommendation.isNoneToday) {
      return false;
    }

    final key = _exerciseRecommendationKey(recommendation);
    if (!await _shouldShowPreview(_exercisePreviewKey, key)) {
      return false;
    }

    final wasShown = await OverlayAssistantController.instance
        .showGeneratedPreview(
          kind: 'exercise',
          title: _shortPreviewText(recommendation.exerciseName, maxChars: 34),
          body: _shortPreviewText(
            '${recommendation.targetLabel}. ${recommendation.reason}',
            maxChars: 108,
          ),
        );
    if (!wasShown) {
      return false;
    }

    await _rememberPreviewKey(_exercisePreviewKey, key);
    return true;
  }

  Future<bool> _shouldShowPreview(String storageKey, String contentKey) async {
    if (contentKey.trim().isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKey) != contentKey;
  }

  Future<void> _rememberPreviewKey(String storageKey, String contentKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, contentKey);
  }

  bool _isFallbackNudge(AdaptiveNudgeRecommendation nudge) {
    return nudge.triggerReason == 'Local fallback' ||
        nudge.metadata['local_fallback'] == true;
  }

  String _smartNudgeKey(AdaptiveNudgeRecommendation nudge) {
    return [
      nudge.nudgeEventId?.toString() ?? 'no_event',
      nudge.nudgeType,
      nudge.title,
      nudge.message,
    ].join('|');
  }

  String _nutritionInsightKey(NutritionInsight insight) {
    return [
      insight.id,
      insight.source,
      insight.generatedAt.toIso8601String().substring(0, 10),
      insight.message,
    ].join('|');
  }

  String _exerciseRecommendationKey(ExerciseRecommendationModel item) {
    return [item.exerciseName, item.targetLabel, item.reason].join('|');
  }

  String _shortPreviewText(String value, {required int maxChars}) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty || clean.length <= maxChars) {
      return clean;
    }

    final sentenceMatch = RegExp(r'^(.+?[.!?])(?:\s|$)').firstMatch(clean);
    final firstSentence = sentenceMatch?.group(1)?.trim();
    if (firstSentence != null && firstSentence.length <= maxChars) {
      return firstSentence;
    }

    final clipped = clean.substring(0, maxChars).trimRight();
    final lastSpace = clipped.lastIndexOf(' ');
    final safeClip = lastSpace > maxChars * 0.58
        ? clipped.substring(0, lastSpace)
        : clipped;
    return '$safeClip...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: switch (_mode) {
          _OverlayAssistantMode.panel => SafeArea(
            key: const ValueKey('overlay-panel'),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AssistantExperiencePanel(
                  message:
                      "You're doing well today. Log sleep and hydration to keep your streak going.",
                  emoji: '\u{1F499}',
                  onRefreshRecommendations: _loadRecommendations,
                  onRefreshAdaptiveNudges: _loadAdaptiveNudges,
                  onRefreshNutritionInsight: _loadNutritionInsight,
                  onRefreshEnvironment: _loadEnvironmentSnapshot,
                  recommendations: _recommendations,
                  adaptiveNudges: _adaptiveNudges,
                  nutritionInsight: _nutritionInsight,
                  hasLoadedAdaptiveNudges: _hasLoadedAdaptiveNudges,
                  hasLoadedNutritionInsight: _hasLoadedNutritionInsight,
                  onLogMealRequested: () => _openAppTo('nutrition_log'),
                  onLogPageRequested: () => _openAppTo('hydration'),
                  useSafeAreaPadding: false,
                  onClose: _collapsePanel,
                ),
              ),
            ),
          ),
          _OverlayAssistantMode.reminderPreview => SafeArea(
            key: const ValueKey('overlay-reminder-preview'),
            child: Center(
              child: _ReminderPreviewCard(
                title: _reminderTitle,
                body: _reminderBody,
              ),
            ),
          ),
          _OverlayAssistantMode.generatedPreview => SafeArea(
            key: const ValueKey('overlay-generated-preview'),
            child: Center(
              child: _GeneratedPreviewCard(
                kind: _generatedPreviewKind,
                title: _generatedPreviewTitle,
                body: _generatedPreviewBody,
              ),
            ),
          ),
          _OverlayAssistantMode.bubble => const Center(
            key: ValueKey('overlay-bubble'),
            child: SizedBox(
              width: 58,
              height: 58,
              child: AssistantFloatingBubbleVisual(),
            ),
          ),
        },
      ),
    );
  }
}

class _ReminderPreviewCard extends StatelessWidget {
  const _ReminderPreviewCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF162338).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF123047);
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF475569);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1EAD83).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF1EAD83),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isEmpty ? 'Reminder' : title.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  if (body.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      body.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bodyColor,
                        height: 1.3,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedPreviewCard extends StatelessWidget {
  const _GeneratedPreviewCard({
    required this.kind,
    required this.title,
    required this.body,
  });

  final String kind;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = switch (kind) {
      'nutrition' => const Color(0xFF16A34A),
      'exercise' => const Color(0xFF2563EB),
      _ => const Color(0xFF8B5CF6),
    };
    final icon = switch (kind) {
      'nutrition' => Icons.restaurant_menu_rounded,
      'exercise' => Icons.directions_walk_rounded,
      _ => Icons.auto_awesome_rounded,
    };
    final fallbackTitle = switch (kind) {
      'nutrition' => 'Nutrition nudge',
      'exercise' => 'Exercise idea',
      _ => 'Smart nudge',
    };
    final surfaceColor = isDark
        ? const Color(0xFF162338).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF123047);
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF475569);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isEmpty ? fallbackTitle : title.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  if (body.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      body.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bodyColor,
                        height: 1.3,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
