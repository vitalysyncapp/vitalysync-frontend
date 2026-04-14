import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/BurnoutCard.dart';
import '../widgets/EnvironmentalCard.dart';
import '../widgets/InfoCard.dart';
import '../widgets/QuickActions.dart';
import '../widgets/SmartNudge.dart';
import '../widgets/WeeklyAnalytics.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

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
                        child: const InfoCard(
                          icon: Icons.bedtime,
                          title: 'Sleep',
                          value: '6.5h',
                          subtitle: 'Last night',
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassCard(
                        child: const InfoCard(
                          icon: Icons.opacity,
                          title: 'Hydration',
                          value: '1.2L',
                          subtitle: 'Today',
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: const EnvironmentalCard(
                    weather: 'Sunny, 28°C',
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
                      value: '↑ Improving',
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
