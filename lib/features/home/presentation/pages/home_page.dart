import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../data/device_location_service.dart';
import '../../data/environment_api.dart';
import '../../data/environment_model.dart';
import '../../../../features/log/data/log_api.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../widgets/BurnoutCard.dart';
import '../widgets/EnvironmentalCard.dart';
import '../widgets/InfoCard.dart';
import '../widgets/QuickActions.dart';
import '../widgets/WeeklyAnalytics.dart';

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
  String _hydrationValue = '--';
  String _hydrationSubtitle = 'No log yet';
  String? _hydrationLevel;
  Color _hydrationLevelColor = Colors.green;
  int _burnoutScore = 40;
  String _burnoutStatus = 'Baseline pending';
  bool _isLoadingSummary = true;
  bool _isLoadingEnvironment = true;
  bool _isOfflineSummary = false;
  bool _isDemoMode = false;
  bool _isUsingCachedEnvironment = false;
  String? _environmentError;
  EnvironmentSnapshot? _environmentSnapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBurnoutBaseline();
    _loadLatestSummary();
    _loadEnvironment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBurnoutBaseline();
      _loadLatestSummary(showLoader: false);
      _loadEnvironment(showLoader: false);
    }
  }

  Future<void> _loadBurnoutBaseline() async {
    final defaults = await OnboardingService.loadDefaults();

    if (!mounted) return;

    setState(() {
      _burnoutScore = defaults.burnoutScoreForDisplay;
      _burnoutStatus = _burnoutStatusForLevel(defaults.initialBurnoutLevel);
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

  Future<void> _loadLatestSummary({bool showLoader = true}) async {
    final session = await UserSessionController.instance.load();

    if (!mounted) return;

    setState(() {
      _isDemoMode = session.isDemoMode;
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
          _sleepSubtitle = _isDemoMode
              ? 'Start with a demo check-in'
              : 'No log yet';
          _hydrationSubtitle = _isDemoMode
              ? 'Start with a demo check-in'
              : 'No log yet';
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

      setState(() {
        _sleepValue = LogApi.formatSleepHours(log['sleep_hours']);
        _sleepSubtitle = dateLabel;
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
        _sleepSubtitle = _isDemoMode
            ? 'Demo summary unavailable'
            : 'Offline - summary unavailable';
        _hydrationSubtitle = _sleepSubtitle;
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
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              pageBottomContentPadding(context, extra: 26),
            ),
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
                  delay: Duration(milliseconds: 280),
                  child: QuickActionsSection(),
                ),
                const SizedBox(height: 12),
                RevealOnBuild(
                  delay: const Duration(milliseconds: 340),
                  child: WeeklyAnalyticsCard(
                    items: const [
                      WeeklyStatItem(
                        label: 'Average Sleep',
                        value: '6.8 hours',
                      ),
                      WeeklyStatItem(
                        label: 'Mood Trend',
                        value: 'Improving',
                        valueColor: Color(0xFF12A150),
                      ),
                      WeeklyStatItem(label: 'Exercise Days', value: '4 of 7'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    final message = _isDemoMode
        ? 'Demo mode is active. Local screens still work even when the backend is unavailable.'
        : 'You appear to be offline. The app can still show saved screens, but live summary data is unavailable right now.';

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
              message,
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
