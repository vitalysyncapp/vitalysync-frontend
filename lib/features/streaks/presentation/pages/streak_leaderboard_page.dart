import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/streak_api.dart';
import '../../data/streak_models.dart';

const _streakFireAnimationPath = 'assets/animations/streak_fire.json';
const _healthyHeartAnimationPath = 'assets/animations/healthy_heart.json';

class StreakLeaderboardPage extends StatefulWidget {
  const StreakLeaderboardPage({super.key});

  @override
  State<StreakLeaderboardPage> createState() => _StreakLeaderboardPageState();
}

class _StreakLeaderboardPageState extends State<StreakLeaderboardPage> {
  static const _sections = <_LeaderboardOption>[
    _LeaderboardOption('global', 'Global', Icons.public_rounded),
    _LeaderboardOption('area', 'Local', Icons.location_on_outlined),
    _LeaderboardOption('role', 'Role', Icons.badge_outlined),
    _LeaderboardOption('wellness', 'Goal', Icons.flag_outlined),
  ];

  static const _metrics = <_LeaderboardOption>[
    _LeaderboardOption(
      'current',
      'Current',
      Icons.local_fire_department_rounded,
    ),
    _LeaderboardOption('month', 'Month', Icons.calendar_month_rounded),
    _LeaderboardOption('longest', 'Best', Icons.emoji_events_outlined),
  ];

  String _section = 'global';
  String _metric = 'current';
  late Future<StreakLeaderboard> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StreakLeaderboard> _load() {
    return StreakApi.fetchLeaderboard(section: _section, metric: _metric);
  }

  void _selectSection(String section) {
    if (section == _section) return;
    setState(() {
      _section = section;
      _future = _load();
    });
  }

  void _selectMetric(String metric) {
    if (metric == _metric) return;
    setState(() {
      _metric = metric;
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
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
            'Streak leaderboard',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: FutureBuilder<StreakLeaderboard>(
          future: _future,
          builder: (context, snapshot) {
            final Widget leaderboardContent;
            if (snapshot.connectionState != ConnectionState.done) {
              leaderboardContent = const AppSkeletonList(
                key: ValueKey('leaderboard-loading'),
                padding: EdgeInsets.zero,
                cardHeights: [160, 74, 74, 74, 74],
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              leaderboardContent = _LeaderboardError(
                key: const ValueKey('leaderboard-error'),
                onRetry: _refresh,
              );
            } else {
              leaderboardContent = _LeaderboardContent(
                key: ValueKey('$_section-$_metric'),
                leaderboard: snapshot.data!,
                metric: _metric,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  pageBottomContentPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LeaderboardHero(metric: _metric),
                    const SizedBox(height: 14),
                    _OptionChips(
                      options: _sections,
                      selected: _section,
                      onSelected: _selectSection,
                    ),
                    const SizedBox(height: 10),
                    _OptionChips(
                      options: _metrics,
                      selected: _metric,
                      onSelected: _selectMetric,
                      compact: true,
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.025),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: leaderboardContent,
                    ),
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

class _LeaderboardOption {
  final String value;
  final String label;
  final IconData icon;

  const _LeaderboardOption(this.value, this.label, this.icon);
}

class _LeaderboardHero extends StatelessWidget {
  final String metric;

  const _LeaderboardHero({required this.metric});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final subtitle = switch (metric) {
      'month' => 'Ranked by check-ins and protected days this month.',
      'longest' => 'Ranked by all-time best streak.',
      _ => 'Ranked by active streaks and privacy-safe profiles.',
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 174),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF137C8B), Color(0xFF26A69A), Color(0xFF61C7E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D8CA8).withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -42,
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: -10,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.94,
                  child: Lottie.asset(
                    _streakFireAnimationPath,
                    width: 128,
                    height: 128,
                    fit: BoxFit.contain,
                    repeat: !reduceMotion,
                    animate: !reduceMotion,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFFC857),
                        size: 82,
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 104, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_2_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Streak league',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Small wins.\nStrong streaks.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChips extends StatelessWidget {
  final List<_LeaderboardOption> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool compact;

  const _OptionChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              selected: selected == option.value,
              onSelected: (_) => onSelected(option.value),
              avatar: Icon(
                option.icon,
                size: compact ? 16 : 18,
                color: selected == option.value
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              label: Text(option.label),
              labelStyle: TextStyle(
                color: selected == option.value
                    ? Colors.white
                    : pagePrimaryTextColor(context),
                fontWeight: FontWeight.w800,
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: pageSurfaceColor(context),
              side: BorderSide(color: pageBorderColor(context)),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 6 : 9,
              ),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  final StreakLeaderboard leaderboard;
  final String metric;

  const _LeaderboardContent({
    super.key,
    required this.leaderboard,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    if (!leaderboard.available) {
      return _EmptyLeaderboard(
        icon: Icons.lock_outline_rounded,
        title: '${leaderboard.sectionLabel} is not available yet',
        message:
            'This section unlocks after VitalySync has enough profile or location context for your account.',
      );
    }

    if (leaderboard.rows.isEmpty) {
      return _EmptyLeaderboard(
        icon: Icons.local_fire_department_outlined,
        animationAsset: _healthyHeartAnimationPath,
        title: 'No rankings yet',
        message: 'Check in today to start showing up in this section.',
      );
    }

    final topRows = leaderboard.rows.take(3).toList();
    final remaining = leaderboard.rows.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionSummary(leaderboard: leaderboard),
        const SizedBox(height: 14),
        _Podium(rows: topRows, metric: metric),
        const SizedBox(height: 14),
        ...remaining.map((row) => _RankRow(row: row, metric: metric)),
      ],
    );
  }
}

class _SectionSummary extends StatelessWidget {
  final StreakLeaderboard leaderboard;

  const _SectionSummary({required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    final currentUserRank = leaderboard.currentUserRank;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF38BDF8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              currentUserRank == null ? '--' : '#$currentUserRank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUserRank == null
                      ? '${leaderboard.sectionLabel} leaderboard'
                      : 'Your ${leaderboard.sectionLabel} position',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${leaderboard.rows.length} ranked streak${leaderboard.rows.length == 1 ? '' : 's'} - Privacy-safe profiles',
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified_user_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<StreakLeaderboardRow> rows;
  final String metric;

  const _Podium({required this.rows, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top streaks',
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Consistency worth celebrating',
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final orderedRows = <StreakLeaderboardRow>[
                if (rows.length > 1) rows[1],
                rows.first,
                if (rows.length > 2) rows[2],
              ];

              if (constraints.maxWidth < 300) {
                return Column(
                  children: orderedRows
                      .map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PodiumTile(row: row, metric: metric),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < orderedRows.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: orderedRows[index].rank == 1 ? 0 : 24,
                        ),
                        child: _PodiumTile(
                          row: orderedRows[index],
                          metric: metric,
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final StreakLeaderboardRow row;
  final String metric;
  final bool compact;

  const _PodiumTile({
    required this.row,
    required this.metric,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(row.avatarColor);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final crownColor = row.rank == 1
        ? const Color(0xFFFACC15)
        : row.rank == 2
        ? const Color(0xFFCBD5E1)
        : const Color(0xFFF59E0B);

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 14,
        compact ? 10 : 14,
        compact ? 8 : 14,
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: row.rank == 1
            ? LinearGradient(
                colors: [
                  const Color(0xFFFACC15).withValues(alpha: 0.18),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: row.rank == 1
            ? null
            : row.isCurrentUser
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : pageSubtleSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: row.rank == 1
              ? const Color(0xFFFACC15).withValues(alpha: 0.42)
              : row.isCurrentUser
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
              : pageBorderColor(context),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: crownColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  row.rank == 1
                      ? Icons.workspace_premium_rounded
                      : Icons.emoji_events_rounded,
                  color: crownColor,
                  size: 15,
                ),
                const SizedBox(width: 3),
                Text(
                  '#${row.rank}',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 7 : 10),
          if (row.rank == 1)
            SizedBox(
              width: compact ? 66 : 76,
              height: compact ? 66 : 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Lottie.asset(
                      _streakFireAnimationPath,
                      fit: BoxFit.contain,
                      repeat: !reduceMotion,
                      animate: !reduceMotion,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF8A3D).withValues(alpha: 0.5),
                          size: compact ? 56 : 64,
                        );
                      },
                    ),
                  ),
                  _InitialsAvatar(
                    row: row,
                    color: color,
                    size: compact ? 40 : 46,
                    ringColor: Colors.white,
                  ),
                ],
              ),
            )
          else
            _InitialsAvatar(row: row, color: color, size: compact ? 42 : 48),
          SizedBox(height: compact ? 7 : 10),
          Text(
            row.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12.5 : null,
            ),
          ),
          if (row.isCurrentUser) ...[
            const SizedBox(height: 3),
            Text(
              'You',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _scoreLabel(row.score, metric),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 13 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final StreakLeaderboardRow row;
  final String metric;

  const _RankRow({required this.row, required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(row.avatarColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: row.isCurrentUser
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: row.isCurrentUser
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.32)
              : pageBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${row.rank}',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _InitialsAvatar(row: row, color: color, size: 42),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.protectedDayCount} protected day${row.protectedDayCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _scoreLabel(row.score, metric),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final StreakLeaderboardRow row;
  final Color color;
  final double size;
  final Color? ringColor;

  const _InitialsAvatar({
    required this.row,
    required this.color,
    required this.size,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ringColor == null
            ? null
            : Border.all(color: ringColor!, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        row.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  final IconData icon;
  final String? animationAsset;
  final String title;
  final String message;

  const _EmptyLeaderboard({
    required this.icon,
    this.animationAsset,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        children: [
          if (animationAsset != null)
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Lottie.asset(
                animationAsset!,
                fit: BoxFit.contain,
                repeat: !reduceMotion,
                animate: !reduceMotion,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    icon,
                    color: pageSecondaryTextColor(context),
                    size: 42,
                  );
                },
              ),
            )
          else
            Icon(icon, color: pageSecondaryTextColor(context), size: 42),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _LeaderboardError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: pageSecondaryTextColor(context),
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'Unable to load rankings',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              height: 1.35,
              fontWeight: FontWeight.w600,
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
    );
  }
}

String _scoreLabel(int score, String metric) {
  final unit = switch (metric) {
    'month' => score == 1 ? 'check-in' : 'check-ins',
    _ => score == 1 ? 'day' : 'days',
  };
  return '$score $unit';
}

Color _parseColor(String value) {
  final normalized = value.replaceAll('#', '').trim();
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return const Color(0xFF1D8CA8);
  }
  return Color(0xFF000000 | parsed);
}
