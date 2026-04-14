import 'package:flutter/material.dart';

import '../../../../features/log/data/log_api.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/BurnoutCard.dart';
import '../widgets/EnvironmentalCard.dart';
import '../widgets/InfoCard.dart';
import '../widgets/QuickActions.dart';
import '../widgets/SmartNudge.dart';
import '../widgets/WeeklyAnalytics.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String _sleepValue = '--';
  String _sleepSubtitle = 'No log yet';
  String _hydrationValue = '--';
  String _hydrationSubtitle = 'No log yet';
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLatestSummary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLatestSummary(showLoader: false);
    }
  }

  Future<void> _loadLatestSummary({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoadingSummary = true;
      });
    }

    try {
      final data = await LogApi.fetchLatestLog();
      final hasLog = data['has_log'] == true;
      final log = data['log'] as Map<String, dynamic>?;

      if (!mounted) return;

      if (!hasLog || log == null) {
        setState(() {
          _sleepValue = '--';
          _sleepSubtitle = 'No log yet';
          _hydrationValue = '--';
          _hydrationSubtitle = 'No log yet';
          _isLoadingSummary = false;
        });
        return;
      }

      final dateLabel = LogApi.formatLogDateLabel(log['log_date']);

      setState(() {
        _sleepValue = LogApi.formatSleepHours(log['sleep_hours']);
        _sleepSubtitle = dateLabel;
        _hydrationValue = LogApi.formatHydrationLiters(log['hydration_liters']);
        _hydrationSubtitle = dateLabel;
        _isLoadingSummary = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 229, 241, 255),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                GlassCard(
                  child: const BurnoutCard(
                    score: 41,
                    status: 'Moderate - Pay attention to recovery',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: const EnvironmentalCard(
                    weather: 'Sunny, 28Â°C',
                    weatherStatus: 'Good',
                    airQuality: 'AQI 152',
                    airStatus: 'Unhealthy',
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: const SmartNudgeCard(
                    message: "Today's Smart Nudge",
                  ),
                ),
                const SizedBox(height: 16),
                const QuickActionsSection(),
                const SizedBox(height: 12),
                WeeklyAnalyticsCard(
                  items: const [
                    WeeklyStatItem(
                      label: 'Average Sleep',
                      value: '6.8 hours',
                    ),
                    WeeklyStatItem(
                      label: 'Mood Trend',
                      value: 'â†‘ Improving',
                      valueColor: Color(0xFF12A150),
                    ),
                    WeeklyStatItem(
                      label: 'Exercise Days',
                      value: '4 of 7',
                    ),
                  ],
                  onViewAll: () {
                    // navigate to analytics page
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
