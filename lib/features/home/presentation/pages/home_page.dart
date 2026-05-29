import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../data/device_location_service.dart';
import '../../data/environment_api.dart';
import '../../data/environment_model.dart';
import '../../../../features/activity/data/activity_service.dart';
import '../../../../features/dashboard/data/burnout_score_api.dart';
import '../../../../features/activity/presentation/widgets/activity_summary_card.dart';
import '../../../../features/log/data/log_api.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../shared/notifications/notification_feed_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../widgets/burnout_card.dart';
import '../widgets/environmental_card.dart';
import '../widgets/info_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/weekly_analytics.dart';

enum _HomeLiveDataIssue { offline, unavailable }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const double _fallbackLatitude = 9.65;
  static const double _fallbackLongitude = 123.85;

  String _sleepValue = '--';
  String _sleepSubtitle = 'No log yet';
  String? _sleepQualityLabel;
  Color _sleepQualityColor = Colors.blue;
  String _hydrationValue = '--';
  String _hydrationSubtitle = 'No log yet';
  String? _hydrationLevel;
  Color _hydrationLevelColor = Colors.green;
  int _burnoutScore = 40;
  String _burnoutStatus = 'Baseline pending';
  BurnoutScoreSnapshot? _latestBurnoutScore;
  BurnoutPatternSummary? _burnoutPatternSummary;
  bool _isLoadingSummary = true;
  bool _isLoadingEnvironment = true;
  _HomeLiveDataIssue? _summaryIssue;
  bool _isUsingCachedEnvironment = false;
  String? _environmentError;
  EnvironmentSnapshot? _environmentSnapshot;
  int _refreshVersion = 0;
  int _burnoutLoadToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BurnoutScoreApi.refreshSignal.addListener(_handleBurnoutInputsChanged);
    ActivityService.instance.startTracking();
    _loadBurnoutBaseline();
    _loadLatestSummary();
    _loadEnvironment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BurnoutScoreApi.refreshSignal.removeListener(_handleBurnoutInputsChanged);
    super.dispose();
  }

  void _handleBurnoutInputsChanged() {
    _loadBurnoutBaseline();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ActivityService.instance.startTracking();
      _loadBurnoutBaseline();
      _loadLatestSummary(showLoader: false);
      _loadEnvironment(showLoader: false);
    }
  }

  Future<void> _refreshHome() async {
    setState(() {
      _refreshVersion++;
    });

    await Future.wait([
      ActivityService.instance.refresh(),
      _loadBurnoutBaseline(),
      _loadLatestSummary(showLoader: false),
      _loadEnvironment(showLoader: false),
      refreshAppBarStreak(),
      refreshNotificationFeed(),
    ]);
  }

  Future<void> _loadBurnoutBaseline() async {
    final loadToken = ++_burnoutLoadToken;
    final defaults = await OnboardingService.loadDefaults();
    BurnoutScoreSnapshot? latestScore;
    BurnoutPatternSummary? patternSummary;

    try {
      final results = await Future.wait<Object?>([
        BurnoutScoreApi.fetchLatestScore(),
        BurnoutScoreApi.fetchPatternSummary(),
      ]);
      latestScore = results[0] as BurnoutScoreSnapshot?;
      patternSummary = results[1] as BurnoutPatternSummary?;
      latestScore ??= patternSummary?.latestScore;
    } catch (_) {
      latestScore = null;
      patternSummary = null;
    }

    if (!mounted || loadToken != _burnoutLoadToken) return;

    setState(() {
      _latestBurnoutScore = latestScore;
      _burnoutPatternSummary = patternSummary;
      if (latestScore != null) {
        _burnoutScore = latestScore.overallScore.round();
        _burnoutStatus = _burnoutStatusForRisk(
          latestScore.riskLevel,
          latestScore.confidenceScore,
        );
      } else {
        _burnoutScore = defaults.burnoutScoreForDisplay;
        _burnoutStatus = _burnoutStatusForLevel(defaults.initialBurnoutLevel);
      }
    });
  }

  String _burnoutStatusForLevel(String? level) {
    switch (level?.trim().toLowerCase()) {
      case 'very low':
        return 'Very Low - Keep your routine steady';
      case 'low':
        return 'Low - Keep protecting your recovery';
      case 'moderate':
        return 'Moderate - Pay attention to recovery';
      case 'high':
        return 'High - Make room for support and rest';
      case 'very high':
        return 'Very High - Prioritize support and recovery';
      default:
        return 'Complete onboarding to set your baseline';
    }
  }

  String _burnoutStatusForRisk(String level, double confidenceScore) {
    final confidence = confidenceScore.round();
    switch (level) {
      case 'low':
        return 'Low - Current patterns look steady ($confidence% confidence)';
      case 'moderate':
        return 'Moderate - Watch recovery trends ($confidence% confidence)';
      case 'high':
        return 'High - Recovery support is recommended ($confidence% confidence)';
      case 'critical':
        return 'Critical - Prioritize support and rest ($confidence% confidence)';
      default:
        return 'Current score available ($confidence% confidence)';
    }
  }

  Future<void> _loadLatestSummary({bool showLoader = true}) async {
    if (!mounted) return;

    setState(() {
      if (showLoader) {
        _isLoadingSummary = true;
      }
      _summaryIssue = null;
    });

    try {
      final data = await LogApi.fetchLatestLog();
      final hasLog = data['has_log'] == true;
      final log = data['log'] as Map<String, dynamic>?;
      final summaryIssue = _summaryIssueFrom(data);

      if (!mounted) return;

      if (!hasLog || log == null) {
        setState(() {
          _sleepValue = '--';
          _hydrationValue = '--';
          _sleepSubtitle = 'No log yet';
          _hydrationSubtitle = 'No log yet';
          _sleepQualityLabel = null;
          _sleepQualityColor = Colors.blue;
          _hydrationLevel = null;
          _hydrationLevelColor = Colors.green;
          _isLoadingSummary = false;
          _summaryIssue = summaryIssue;
        });
        return;
      }

      final dateLabel = LogApi.formatLogDateLabel(log['log_date']);
      final hydrationStatus = LogApi.getHydrationStatus(
        log['hydration_liters'],
      );
      final sleepQuality = LogApi.parseInt(log['sleep_quality'], fallback: -1);

      setState(() {
        _sleepValue = LogApi.formatSleepHours(log['sleep_hours']);
        _sleepSubtitle = dateLabel;
        _sleepQualityLabel = _sleepQualityLabelFor(sleepQuality);
        _sleepQualityColor = _sleepQualityColorFor(sleepQuality);
        _hydrationValue = LogApi.formatHydrationLiters(log['hydration_liters']);
        _hydrationSubtitle = dateLabel;
        _hydrationLevel = hydrationStatus.shortLabel;
        _hydrationLevelColor = Color(hydrationStatus.colorValue);
        _isLoadingSummary = false;
        _summaryIssue = summaryIssue;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _sleepSubtitle = 'Summary unavailable';
        _hydrationSubtitle = _sleepSubtitle;
        _sleepQualityLabel = null;
        _sleepQualityColor = Colors.blue;
        _hydrationLevel = null;
        _hydrationLevelColor = Colors.green;
        _isLoadingSummary = false;
        _summaryIssue = _HomeLiveDataIssue.unavailable;
      });
    }
  }

  Future<void> _loadEnvironment({bool showLoader = true}) async {
    if (!mounted) return;

    setState(() {
      if (showLoader) {
        _isLoadingEnvironment = true;
      }
      _environmentError = null;
    });

    try {
      final coordinates = await DeviceLocationService.getCurrentCoordinates();
      final snapshot = await EnvironmentApi.fetchEnvironment(
        lat: coordinates?.latitude ?? _fallbackLatitude,
        lon: coordinates?.longitude ?? _fallbackLongitude,
      );

      if (!mounted) return;

      setState(() {
        _environmentSnapshot = snapshot;
        _isUsingCachedEnvironment = false;
        _environmentError = null;
        _isLoadingEnvironment = false;
      });
    } catch (error) {
      debugPrint('Environment load failed: $error');
      final cachedSnapshot = await EnvironmentApi.loadCachedSnapshot();
      if (!mounted) return;

      setState(() {
        _environmentSnapshot = cachedSnapshot;
        _isUsingCachedEnvironment = cachedSnapshot != null;
        final fallbackMessage =
            'Live environment data is unavailable right now.';
        _environmentError = cachedSnapshot == null
            ? kDebugMode
                  ? '$fallbackMessage\n$error'
                  : fallbackMessage
            : null;
        _isLoadingEnvironment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(context),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                pageBottomContentPadding(context, extra: 10.5),
              ),
              child: Column(
                children: [
                  if (_summaryIssue != null) ...[
                    RevealOnBuild(
                      child: _buildStatusBanner(context, _summaryIssue!),
                    ),
                    const SizedBox(height: 12),
                  ],
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 100),
                    child: GlassCard(
                      child: BurnoutCard(
                        score: _burnoutScore,
                        status: _burnoutStatus,
                        latestScore: _latestBurnoutScore,
                        patternSummary: _burnoutPatternSummary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 160),
                    child: Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            child: InfoCard(
                              icon: Icons.bedtime,
                              title: 'Sleep',
                              value: _sleepValue,
                              subtitle: _sleepSubtitle,
                              color: Colors.blue,
                              isLoading: _isLoadingSummary,
                              statusHint: _sleepQualityLabel,
                              statusColor: _sleepQualityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassCard(
                            child: InfoCard(
                              icon: Icons.opacity,
                              title: 'Hydration',
                              value: _hydrationValue,
                              subtitle: _hydrationSubtitle,
                              color: Colors.green,
                              isLoading: _isLoadingSummary,
                              statusHint: _hydrationLevel,
                              statusColor: _hydrationLevelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const RevealOnBuild(
                    delay: Duration(milliseconds: 220),
                    child: QuickActionsSection(),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 280),
                    child: GlassCard(
                      child: EnvironmentalCard(
                        snapshot: _environmentSnapshot,
                        isLoading: _isLoadingEnvironment,
                        isCached: _isUsingCachedEnvironment,
                        errorMessage: _environmentError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 340),
                    child: ValueListenableBuilder<ActivityTrackingState>(
                      valueListenable: ActivityService.instance.notifier,
                      builder: (context, activityState, _) {
                        if (!activityState.isStepTrackingSupported) {
                          return const SizedBox.shrink();
                        }

                        return ActivitySummaryCard(
                          state: activityState,
                          compact: true,
                          onRefresh: () => ActivityService.instance.refresh(),
                          onEditGoal: ActivityService.instance.updateGoalSteps,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 400),
                    child: HomeWeeklyAnalyticsCard(
                      key: ValueKey('home-weekly-$_refreshVersion'),
                    ),
                  ),
                  ValueListenableBuilder<ActivityTrackingState>(
                    valueListenable: ActivityService.instance.notifier,
                    builder: (context, activityState, _) {
                      if (activityState.isStepTrackingSupported) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          RevealOnBuild(
                            delay: const Duration(milliseconds: 460),
                            child: _buildDailyStepsUnsupportedNote(context),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _sleepQualityLabelFor(int value) {
    switch (value) {
      case 0:
        return 'Poor Quality';
      case 1:
        return 'Fair Quality';
      case 2:
        return 'Good Quality';
      case 3:
        return 'Very Good';
      case 4:
        return 'Excellent';
      default:
        return null;
    }
  }

  Color _sleepQualityColorFor(int value) {
    switch (value) {
      case 0:
        return const Color(0xFFDC2626);
      case 1:
        return const Color(0xFFF97316);
      case 2:
        return const Color(0xFF2563EB);
      case 3:
        return const Color(0xFF7C3AED);
      case 4:
        return const Color(0xFF16A34A);
      default:
        return Colors.blue;
    }
  }

  _HomeLiveDataIssue? _summaryIssueFrom(Map<String, dynamic> data) {
    if (data['is_offline'] != true) {
      return null;
    }

    return data['live_data_issue'] == LogApi.liveDataIssueOffline
        ? _HomeLiveDataIssue.offline
        : _HomeLiveDataIssue.unavailable;
  }

  Widget _buildStatusBanner(BuildContext context, _HomeLiveDataIssue issue) {
    final isOffline = issue == _HomeLiveDataIssue.offline;
    final accentColor = isOffline
        ? const Color(0xFF0F766E)
        : const Color(0xFF2563EB);
    final message = isOffline
        ? 'You appear to be offline.'
        : 'Live data is currently unavailable.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF102235).withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_outlined,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.2,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStepsUnsupportedNote(BuildContext context) {
    final accentColor = const Color(0xFF1EAD83);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pageBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.20
                    : 0.05,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk_rounded, size: 19, color: accentColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Daily steps is not supported on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
