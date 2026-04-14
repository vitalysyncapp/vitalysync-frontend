import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bar.dart';
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                DashboardHeaderCard(),
                SizedBox(height: 16),

                Row(
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

                SizedBox(height: 16),
                BurnoutRiskTrendCard(),
                SizedBox(height: 16),
                SleepPatternCard(),
                SizedBox(height: 16),
                WellnessIndexCard(),
                SizedBox(height: 16),
                MoodVolatilityCard(),
                SizedBox(height: 16),
                SymptomFrequencyCard(),
                SizedBox(height: 16),
                WeeklyPerformanceCard(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
