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
  bool _isLoadingSummary = true;
  bool _isLoadingEnvironment = true;
  bool _isOfflineSummary = false;
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

    try {
      latestScore = await BurnoutScoreApi.fetchLatestScore();
    } catch (_) {
      latestScore = null;
    }

    if (!mounted || loadToken != _burnoutLoadToken) return;

    setState(() {
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
    switch (level) {
      case 'Low':
        return 'Low - Keep protecting your recovery';
      case 'Moderate':
        return 'Moderate - Pay attention to recovery';
      case 'High':
        return 'High - Make room for support and rest';
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
      _isOfflineSummary = false;
    });

    try {
      final data = await LogApi.fetchLatestLog();
      final hasLog = data['has_log'] == true;
      final log = data['log'] as Map<String, dynamic>?;
      final isOfflineSummary = data['is_offline'] == true;

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
          _isOfflineSummary = isOfflineSummary;
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
        _isOfflineSummary = isOfflineSummary;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _sleepSubtitle = 'Offline - summary unavailable';
        _hydrationSubtitle = _sleepSubtitle;
        _sleepQualityLabel = null;
        _sleepQualityColor = Colors.blue;
        _hydrationLevel = null;
        _hydrationLevelColor = Colors.green;
        _isLoadingSummary = false;
        _isOfflineSummary = true;
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  if (_isOfflineSummary) ...[
                    RevealOnBuild(child: _buildStatusBanner(context)),
                    const SizedBox(height: 12),
                  ],
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 100),
                    child: GlassCard(
                      child: BurnoutCard(
                        score: _burnoutScore,
                        status: _burnoutStatus,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        const SizedBox(width: 16),
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
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 220),
                    child: ValueListenableBuilder<ActivityTrackingState>(
                      valueListenable: ActivityService.instance.notifier,
                      builder: (context, activityState, _) {
                        return ActivitySummaryCard(
                          state: activityState,
                          onRefresh: () => ActivityService.instance.refresh(),
                          onEditGoal: ActivityService.instance.updateGoalSteps,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  const RevealOnBuild(
                    delay: Duration(milliseconds: 340),
                    child: QuickActionsSection(),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 400),
                    child: HomeWeeklyAnalyticsCard(
                      key: ValueKey('home-weekly-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 16),
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

  Widget _buildStatusBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Live summary data is unavailable right now. The app is showing your saved check-in data and will refresh automatically.',
              style: TextStyle(
                height: 1.4,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
