import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/streak_api.dart';
import '../../data/streak_models.dart';
import '../widgets/streak_share_card.dart';
import 'streak_leaderboard_page.dart';

class PersonalStreakPage extends StatefulWidget {
  const PersonalStreakPage({super.key});

  @override
  State<PersonalStreakPage> createState() => _PersonalStreakPageState();
}

class _PersonalStreakPageState extends State<PersonalStreakPage> {
  late Future<StreakOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = StreakApi.fetchOverview();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = StreakApi.fetchOverview();
    });
    await _future;
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StreakLeaderboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: pagePrimaryTextColor(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My streak',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                tooltip: 'Leaderboard',
                onPressed: _openLeaderboard,
                style: IconButton.styleFrom(
                  backgroundColor: pageSurfaceColor(context),
                ),
                icon: Icon(
                  Icons.leaderboard_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        body: FutureBuilder<StreakOverview>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return AppSkeletonList(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  pageBottomContentPadding(context),
                ),
                cardHeights: const [280, 116, 164, 180],
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _StreakErrorState(onRetry: _refresh);
            }

            final overview = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  pageBottomContentPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RepaintBoundary(
                      child: StreakShareCard(
                        displayName: overview.displayName,
                        currentStreak: overview.streak.currentStreak,
                        longestStreak: overview.streak.longestStreak,
                        availableSavers: overview.savers.availableSavers,
                        protectedDayCount: overview.protectedDayCount,
                        isOffline: overview.isOffline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SaverPanel(overview: overview),
                    const SizedBox(height: 18),
                    _LeaderboardCta(onTap: _openLeaderboard),
                    const SizedBox(height: 18),
                    _RecentStreakEvents(events: overview.recentEvents),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SaverPanel extends StatelessWidget {
  final StreakOverview overview;

  const _SaverPanel({required this.overview});

  @override
  Widget build(BuildContext context) {
    final savers = overview.savers;
    final total = savers.baseSavers + savers.earnedSavers;
    final used = savers.usedSavers.clamp(0, total == 0 ? 1 : total);
    final progress = total <= 0 ? 0.0 : used / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFB800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A1F).withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak savers',
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Resets monthly. Earn more from milestones.',
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SaverNumber(
                  label: 'Available',
                  value: savers.availableSavers.toString(),
                ),
              ),
              Expanded(
                child: _SaverNumber(
                  label: 'Earned',
                  value: '+${savers.earnedSavers}',
                ),
              ),
              Expanded(
                child: _SaverNumber(
                  label: 'Used',
                  value: savers.usedSavers.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress.clamp(0, 1).toDouble(),
              backgroundColor: pageSubtleSurfaceColor(context),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF7A2F)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaverNumber extends StatelessWidget {
  final String label;
  final String value;

  const _SaverNumber({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: pageSecondaryTextColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardCta extends StatelessWidget {
  final VoidCallback onTap;

  const _LeaderboardCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: pageBorderColor(context)),
          boxShadow: pageCardShadow(context),
        ),
        child: Row(
          children: [
            Icon(
              Icons.leaderboard_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak leaderboard',
                    style: TextStyle(
                      color: pagePrimaryTextColor(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Compare global, local, role, and goal cohorts.',
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: pageSecondaryTextColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentStreakEvents extends StatelessWidget {
  final List<StreakEvent> events;

  const _RecentStreakEvents({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent streak activity',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              'Saver rewards and restore activity will appear here.',
              style: TextStyle(
                color: pageSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...events.map((event) => _EventRow(event: event)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final StreakEvent event;

  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final isGrant = event.type == 'grant';
    final color = isGrant ? const Color(0xFF16A34A) : const Color(0xFFFF8A1F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGrant ? Icons.add_rounded : Icons.shield_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _eventLabel(event),
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _eventLabel(StreakEvent event) {
    final amount = event.amount == 1 ? '1 saver' : '${event.amount} savers';
    switch (event.reason) {
      case 'first_7_day_streak':
        return 'Earned $amount for a 7-day streak.';
      case 'monthly_10_checkins':
        return 'Earned $amount for 10 check-ins this month.';
      case 'weekly_goal_guardian':
        return 'Earned $amount for weekly goal consistency.';
      case 'manual_restore':
        return 'Used $amount to protect ${event.protectedDate ?? 'a missed day'}.';
      default:
        return '${event.type == 'grant' ? 'Earned' : 'Used'} $amount.';
    }
  }
}

class _StreakErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _StreakErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              color: pageSecondaryTextColor(context),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load your streak right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
