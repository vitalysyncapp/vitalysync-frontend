import 'package:flutter/material.dart';

import '../../../../features/activity/data/activity_service.dart';
import '../../../../features/activity/presentation/widgets/activity_summary_card.dart';
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

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

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
                const RevealOnBuild(
                  delay: Duration(milliseconds: 70),
                  child: Row(
                    children: [
                      DashboardStatCard(
                        title: "Burnout Risk",
                        value: "42",
                        subtitle: "+7 from last week",
                        subtitleColor: Colors.red,
                        icon: Icons.trending_up,
                        iconColor: Colors.red,
                      ),
                      SizedBox(width: 12),
                      DashboardStatCard(
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
                        onRefresh: () => ActivityService.instance.refresh(),
                        onEditGoal: ActivityService.instance.updateGoalSteps,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const RevealOnBuild(
                  delay: Duration(milliseconds: 190),
                  child: BurnoutRiskTrendCard(),
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
