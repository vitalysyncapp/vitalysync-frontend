import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/streak_api.dart';
import '../../data/streak_models.dart';
import '../widgets/streak_saver_info_dialog.dart';
import '../widgets/streak_share_card.dart';
import 'streak_leaderboard_page.dart';
import 'package:vitalysync/l10n/localized_text.dart';

typedef StreakOverviewLoader =
    Future<StreakOverview> Function({bool forceRefresh});

class PersonalStreakPage extends StatefulWidget {
  const PersonalStreakPage({
    super.key,
    this.loadOverview,
    this.loadLeaderboard,
    this.tutorialHeaderKey,
  });

  final StreakOverviewLoader? loadOverview;
  final StreakLeaderboardLoader? loadLeaderboard;
  final Key? tutorialHeaderKey;

  @override
  State<PersonalStreakPage> createState() => _PersonalStreakPageState();
}

class _PersonalStreakPageState extends State<PersonalStreakPage> {
  late Future<StreakOverview> _overviewFuture;
  late Future<_StreakRanks> _rankFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
    _rankFuture = _loadRanks();
  }

  @override
  void didUpdateWidget(PersonalStreakPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadOverview != widget.loadOverview) {
      _overviewFuture = _loadOverview();
    }
    if (oldWidget.loadLeaderboard != widget.loadLeaderboard) {
      _rankFuture = _loadRanks();
    }
  }

  Future<StreakOverview> _loadOverview({bool forceRefresh = false}) {
    return (widget.loadOverview ?? StreakApi.fetchOverview)(
      forceRefresh: forceRefresh,
    );
  }

  Future<StreakLeaderboard> _loadLeaderboard(
    String section, {
    bool forceRefresh = false,
  }) {
    final loader = widget.loadLeaderboard ?? StreakApi.fetchLeaderboard;
    return loader(
      section: section,
      metric: 'current',
      limit: 100,
      forceRefresh: forceRefresh,
    );
  }

  Future<_StreakRanks> _loadRanks({bool forceRefresh = false}) async {
    Future<StreakLeaderboard?> loadSafely(String section) async {
      try {
        return await _loadLeaderboard(section, forceRefresh: forceRefresh);
      } catch (_) {
        return null;
      }
    }

    final leaderboards = await Future.wait([
      loadSafely('global'),
      loadSafely('area'),
    ]);

    return _StreakRanks.fromLeaderboards(
      global: leaderboards[0],
      local: leaderboards[1],
    );
  }

  Future<void> _refresh() async {
    final nextOverview = _loadOverview(forceRefresh: true);
    final nextRanks = _loadRanks(forceRefresh: true);
    setState(() {
      _overviewFuture = nextOverview;
      _rankFuture = nextRanks;
    });

    try {
      await Future.wait<Object>([nextOverview, nextRanks]);
    } catch (_) {
      // FutureBuilder owns the visible error state.
    }
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StreakLeaderboardPage(loadLeaderboard: widget.loadLeaderboard),
      ),
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
          title: KeyedSubtree(
            key: widget.tutorialHeaderKey,
            child: LocalizedText(
              'My streak',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                tooltip: 'Leaderboard'.localizedCopy(context),
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
          future: _overviewFuture,
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
              return _StreakErrorState(
                error: snapshot.error,
                onRetry: _refresh,
              );
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
                      child: FutureBuilder<_StreakRanks>(
                        future: _rankFuture,
                        builder: (context, rankSnapshot) {
                          final ranks =
                              rankSnapshot.data ?? const _StreakRanks();

                          return StreakShareCard(
                            displayName: overview.displayName,
                            currentStreak: overview.streak.currentStreak,
                            longestStreak: overview.streak.longestStreak,
                            availableSavers: overview.savers.availableSavers,
                            protectedDayCount: overview.protectedDayCount,
                            globalRank: ranks.globalRank,
                            localRank: ranks.localRank,
                            isOffline: overview.isOffline,
                          );
                        },
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

class _StreakRanks {
  final int? globalRank;
  final int? localRank;

  const _StreakRanks({this.globalRank, this.localRank});

  factory _StreakRanks.fromLeaderboards({
    required StreakLeaderboard? global,
    required StreakLeaderboard? local,
  }) {
    return _StreakRanks(
      globalRank: _topHundredRank(global),
      localRank: _topHundredRank(local),
    );
  }

  static int? _topHundredRank(StreakLeaderboard? leaderboard) {
    if (leaderboard?.available != true) return null;

    final rank = leaderboard?.currentUserRank;
    return rank != null && rank >= 1 && rank <= 100 ? rank : null;
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
                    LocalizedText(
                      'Streak savers',
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    LocalizedText(
                      'Resets monthly. Earn more from milestones.',
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('streak-saver-help'),
                tooltip: 'How streak savers work'.localizedCopy(context),
                visualDensity: VisualDensity.compact,
                onPressed: () => showStreakSaverInfoDialog(context),
                icon: const Icon(Icons.help_outline_rounded, size: 21),
                color: pageSecondaryTextColor(context),
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
        LocalizedText(
          value,
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        LocalizedText(
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
                  LocalizedText(
                    'Streak leaderboard',
                    style: TextStyle(
                      color: pagePrimaryTextColor(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  LocalizedText(
                    'Compare global, local, and role streaks.',
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
          LocalizedText(
            'Recent streak activity',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            LocalizedText(
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
            child: LocalizedText(
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
  final Object? error;
  final Future<void> Function() onRetry;

  const _StreakErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = _streakErrorMessage(error);

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
            LocalizedText(
              'Unable to load your streak right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            LocalizedText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pageSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const LocalizedText('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _streakErrorMessage(Object? error) {
  if (error is StreakApiException) {
    return error.message;
  }

  final message = error?.toString().replaceFirst('Exception: ', '').trim();

  return message?.isNotEmpty == true
      ? message!
      : 'Unable to reach the VitalySync API right now.';
}
