import 'package:flutter/material.dart';

import '../../../../features/activity/data/activity_service.dart';
import '../../../../features/activity/presentation/widgets/activity_summary_card.dart';
import '../../data/burnout_score_api.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../widgets/burnout_risk_trend_card.dart';
import '../widgets/dashboard_header_card.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/mood_volatility_card.dart';
import '../widgets/sleep_pattern_card.dart';
import '../widgets/symptom_frequency_card.dart';
import '../widgets/weekly_performance_card.dart';
import '../widgets/wellness_index_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  BurnoutPatternSummary? _burnoutPatternSummary;
  bool _isLoadingBurnoutPatterns = true;

  @override
  void initState() {
    super.initState();
    _loadBurnoutPatterns();
  }

  Future<void> _loadBurnoutPatterns() async {
    setState(() {
      _isLoadingBurnoutPatterns = true;
    });

    try {
      final summary = await BurnoutScoreApi.fetchPatternSummary();
      if (!mounted) return;

      setState(() {
        _burnoutPatternSummary = summary;
        _isLoadingBurnoutPatterns = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _burnoutPatternSummary = null;
        _isLoadingBurnoutPatterns = false;
      });
    }
  }

  String _burnoutRiskValue() {
    final score = _burnoutPatternSummary?.latestScore;
    if (_isLoadingBurnoutPatterns) {
      return '--';
    }

    return score == null ? '--' : score.overallScore.round().toString();
  }

  String _burnoutRiskSubtitle() {
    final summary = _burnoutPatternSummary;
    if (_isLoadingBurnoutPatterns) {
      return 'Loading trend';
    }
    if (summary == null || summary.latestScore == null) {
      return 'No score history yet';
    }

    final sevenDay = summary.windowForDays(7);
    final delta = sevenDay?.deltaFromStart;
    if (delta == null) {
      return summary.adaptiveState.label;
    }

    final prefix = delta > 0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(1)} over 7 days';
  }

  Color _burnoutTrendColor() {
    final trend = _burnoutPatternSummary?.windowForDays(7)?.trendDirection;
    if (trend == 'falling') {
      return Colors.green;
    }
    if (trend == 'rising') {
      return Colors.red;
    }

    return const Color(0xFF64748B);
  }

  IconData _burnoutTrendIcon() {
    final trend = _burnoutPatternSummary?.windowForDays(7)?.trendDirection;
    if (trend == 'falling') {
      return Icons.trending_down;
    }
    if (trend == 'rising') {
      return Icons.trending_up;
    }

    return Icons.trending_flat;
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
                const RevealOnBuild(child: DashboardHeaderCard()),
                const SizedBox(height: 16),
                RevealOnBuild(
                  delay: const Duration(milliseconds: 70),
                  child: Row(
                    children: [
                      DashboardStatCard(
                        title: "Burnout Risk",
                        value: _burnoutRiskValue(),
                        subtitle: _burnoutRiskSubtitle(),
                        subtitleColor: _burnoutTrendColor(),
                        icon: _burnoutTrendIcon(),
                        iconColor: _burnoutTrendColor(),
                      ),
                      const SizedBox(width: 12),
                      const DashboardStatCard(
                        title: "Avg Sleep",
                        value: "7.1h",
                        subtitle: "+0.3h from last week",
                        subtitleColor: Colors.green,
                        icon: Icons.trending_down,
                        iconColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RevealOnBuild(
                  delay: Duration(milliseconds: 130),
                  child: ValueListenableBuilder<ActivityTrackingState>(
                    valueListenable: ActivityService.instance.notifier,
                    builder: (context, activityState, _) {
                      return WeeklyStepAnalyticsCard(
                        state: activityState,
                        compact: true,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                RevealOnBuild(
                  delay: const Duration(milliseconds: 190),
                  child: BurnoutRiskTrendCard(
                    summary: _burnoutPatternSummary,
                    isLoading: _isLoadingBurnoutPatterns,
                    onRefresh: _loadBurnoutPatterns,
                  ),
                ),
                const SizedBox(height: 16),
                const RevealOnBuild(
                  delay: Duration(milliseconds: 250),
                  child: SleepPatternCard(),
                ),
                const SizedBox(height: 16),
                const RevealOnBuild(
                  delay: Duration(milliseconds: 310),
                  child: WellnessIndexCard(),
                ),
                const SizedBox(height: 16),
                const RevealOnBuild(
                  delay: Duration(milliseconds: 370),
                  child: MoodVolatilityCard(),
                ),
                const SizedBox(height: 16),
                const RevealOnBuild(
                  delay: Duration(milliseconds: 430),
                  child: SymptomFrequencyCard(),
                ),
                const SizedBox(height: 16),
                const RevealOnBuild(
                  delay: Duration(milliseconds: 490),
                  child: WeeklyPerformanceCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
