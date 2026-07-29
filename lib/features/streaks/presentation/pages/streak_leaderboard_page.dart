import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../profile/data/profile_avatar.dart';
import '../../data/streak_api.dart';
import '../../data/streak_models.dart';

const _streakFireAnimationPath = 'assets/animations/streak_fire.json';
const _healthyHeartAnimationPath = 'assets/animations/healthy_heart.json';
final _defaultLeaderboardAvatarPath = suggestedProfileAvatarAsset(null, null);

typedef StreakLeaderboardLoader =
    Future<StreakLeaderboard> Function({
      required String section,
      required String metric,
      required int limit,
    });

class StreakLeaderboardPage extends StatefulWidget {
  const StreakLeaderboardPage({super.key, this.loadLeaderboard});

  final StreakLeaderboardLoader? loadLeaderboard;

  @override
  State<StreakLeaderboardPage> createState() => _StreakLeaderboardPageState();
}

class _StreakLeaderboardPageState extends State<StreakLeaderboardPage> {
  static const _sections = <_LeaderboardOption>[
    _LeaderboardOption('global', 'Global', Icons.public_rounded),
    _LeaderboardOption('area', 'Local', Icons.location_on_outlined),
    _LeaderboardOption('role', 'Role', Icons.badge_outlined),
  ];

  static const _metrics = <_LeaderboardOption>[
    _LeaderboardOption(
      'current',
      'Current',
      Icons.local_fire_department_rounded,
    ),
    _LeaderboardOption('longest', 'Best', Icons.emoji_events_outlined),
  ];

  String _section = 'global';
  String _metric = 'current';
  late Future<StreakLeaderboard> _future;
  UserSessionSnapshot _session = UserSessionSnapshot.empty;

  @override
  void initState() {
    super.initState();
    _future = _load();
    unawaited(_loadSessionProfile());
  }

  @override
  void didUpdateWidget(StreakLeaderboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadLeaderboard != widget.loadLeaderboard) {
      _future = _load();
    }
  }

  Future<StreakLeaderboard> _load() {
    final loader = widget.loadLeaderboard ?? StreakApi.fetchLeaderboard;
    return loader(section: _section, metric: _metric, limit: 50);
  }

  Future<void> _loadSessionProfile() async {
    final session = await UserSessionController.instance.load();
    if (!mounted) return;
    setState(() => _session = session);
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
    final nextFuture = _load();
    setState(() {
      _future = nextFuture;
    });

    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder owns the visible error state.
    }
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                cardHeights: [72, 72, 72, 72, 72],
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              leaderboardContent = _LeaderboardError(
                key: const ValueKey('leaderboard-error'),
                error: snapshot.error,
                onRetry: _refresh,
              );
            } else {
              leaderboardContent = _LeaderboardContent(
                key: ValueKey('$_section-$_metric'),
                leaderboard: snapshot.data!,
                metric: _metric,
                currentUserSession: _session,
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
                    const SizedBox(height: 16),
                    _OptionChips(
                      key: const ValueKey('leaderboard-section-options'),
                      semanticLabel: 'Leaderboard section',
                      options: _sections,
                      selected: _section,
                      onSelected: _selectSection,
                    ),
                    const SizedBox(height: 10),
                    _OptionChips(
                      key: const ValueKey('leaderboard-metric-options'),
                      semanticLabel: 'Streak category',
                      options: _metrics,
                      selected: _metric,
                      onSelected: _selectMetric,
                      compact: true,
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
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
  const _LeaderboardOption(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class _LeaderboardHero extends StatelessWidget {
  const _LeaderboardHero({required this.metric});

  final String metric;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final subtitle = metric == 'longest'
        ? 'Best-ever streak rankings.'
        : 'Active streak rankings.';

    return Container(
      key: const ValueKey('leaderboard-hero'),
      constraints: const BoxConstraints(minHeight: 128),
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
              right: -26,
              top: -42,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: -7,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.94,
                  child: Lottie.asset(
                    _streakFireAnimationPath,
                    width: 92,
                    height: 92,
                    fit: BoxFit.contain,
                    repeat: !reduceMotion,
                    animate: !reduceMotion,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFFC857),
                        size: 62,
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 82, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Small wins.\nStrong streaks.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
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
  const _OptionChips({
    super.key,
    required this.semanticLabel,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final String semanticLabel;
  final List<_LeaderboardOption> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            ChoiceChip(
              key: ValueKey('leaderboard-option-${option.value}'),
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
                horizontal: compact ? 12 : 14,
                vertical: compact ? 6 : 8,
              ),
              showCheckmark: false,
            ),
        ],
      ),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  const _LeaderboardContent({
    super.key,
    required this.leaderboard,
    required this.metric,
    required this.currentUserSession,
  });

  final StreakLeaderboard leaderboard;
  final String metric;
  final UserSessionSnapshot currentUserSession;

  @override
  Widget build(BuildContext context) {
    if (!leaderboard.available) {
      return _EmptyLeaderboard(
        icon: Icons.lock_outline_rounded,
        title: '${leaderboard.sectionLabel} is not available yet',
        message:
            'Add matching location or role details to join this leaderboard.',
      );
    }

    if (leaderboard.rows.isEmpty) {
      return const _EmptyLeaderboard(
        icon: Icons.local_fire_department_outlined,
        animationAsset: _healthyHeartAnimationPath,
        title: 'No rankings yet',
        message: 'Check in today to start showing up in this section.',
      );
    }

    final orderedRows =
        leaderboard.rows
            .where((row) => row.rank >= 1 && row.rank <= 50)
            .toList()
          ..sort((left, right) => left.rank.compareTo(right.rank));
    final podiumRows = orderedRows.where((row) => row.rank <= 3).toList();
    final remainingRows = orderedRows.where((row) => row.rank >= 4).toList();

    return Column(
      key: const ValueKey('leaderboard-list'),
      children: [
        if (podiumRows.isNotEmpty)
          _TopThreePodium(
            rows: podiumRows,
            metric: metric,
            currentUserSession: currentUserSession,
          ),
        if (podiumRows.isNotEmpty && remainingRows.isNotEmpty)
          const SizedBox(height: 16),
        if (remainingRows.isNotEmpty)
          _RankedLeaderboardList(
            rows: remainingRows,
            metric: metric,
            currentUserSession: currentUserSession,
          ),
      ],
    );
  }
}

class _TopThreePodium extends StatelessWidget {
  const _TopThreePodium({
    required this.rows,
    required this.metric,
    required this.currentUserSession,
  });

  final List<StreakLeaderboardRow> rows;
  final String metric;
  final UserSessionSnapshot currentUserSession;

  List<StreakLeaderboardRow> get _displayRows {
    final rowsByRank = {for (final row in rows) row.rank: row};
    return [
      for (final rank in const [2, 1, 3]) ?rowsByRank[rank],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('leaderboard-podium'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFB800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Top 3 streaks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  metric == 'longest' ? 'Best' : 'Current',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final displayRows = _displayRows;
              final gaps = 6.0 * (displayRows.length - 1);
              final tileWidth =
                  ((constraints.maxWidth - gaps) / displayRows.length)
                      .clamp(72.0, 118.0)
                      .toDouble();

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < displayRows.length; index++) ...[
                    if (index > 0) const SizedBox(width: 6),
                    SizedBox(
                      width: tileWidth,
                      child: _TopThreeTile(
                        row: displayRows[index],
                        metric: metric,
                        currentUserSession: currentUserSession,
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

class _TopThreeTile extends StatelessWidget {
  const _TopThreeTile({
    required this.row,
    required this.metric,
    required this.currentUserSession,
  });

  final StreakLeaderboardRow row;
  final String metric;
  final UserSessionSnapshot currentUserSession;

  @override
  Widget build(BuildContext context) {
    final accent = _podiumAccent(context, row.rank);
    final isWinner = row.rank == 1;
    final isCurrentUser = _isCurrentUser(row, currentUserSession);
    final score = _scoreLabel(row.score);
    final streakKind = metric == 'longest' ? 'Best streak' : 'Current streak';
    final tileHeight = switch (row.rank) {
      1 => 158.0,
      2 => 142.0,
      _ => 136.0,
    };
    final avatarSize = isWinner ? 56.0 : 49.0;

    return Semantics(
      container: true,
      label: 'Rank ${row.rank}, ${row.displayName}, $score, $streakKind',
      child: Container(
        key: ValueKey('leaderboard-podium-user-${row.userId}'),
        height: tileHeight,
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 10),
        decoration: BoxDecoration(
          gradient: isWinner
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFFB800).withValues(alpha: 0.2),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isWinner ? null : pageSubtleSurfaceColor(context),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isCurrentUser
                ? Theme.of(context).colorScheme.primary
                : accent.withValues(alpha: 0.58),
            width: isCurrentUser ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWinner) ...[
              Icon(Icons.workspace_premium_rounded, color: accent, size: 21),
              const SizedBox(height: 2),
            ],
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _LeaderboardAvatar(
                  key: ValueKey('leaderboard-avatar-${row.userId}'),
                  row: row,
                  currentUserSession: currentUserSession,
                  size: avatarSize,
                  borderColor: accent,
                ),
                Positioned(
                  bottom: -6,
                  child: Container(
                    key: ValueKey('leaderboard-podium-rank-${row.userId}'),
                    constraints: const BoxConstraints(minWidth: 21),
                    height: 21,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: pageSurfaceColor(context),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${row.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              row.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  score,
                  maxLines: 1,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedLeaderboardList extends StatelessWidget {
  const _RankedLeaderboardList({
    required this.rows,
    required this.metric,
    required this.currentUserSession,
  });

  final List<StreakLeaderboardRow> rows;
  final String metric;
  final UserSessionSnapshot currentUserSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('leaderboard-ranked-list'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _LeaderboardListRow(
              row: rows[index],
              metric: metric,
              currentUserSession: currentUserSession,
            ),
            if (index < rows.length - 1)
              Divider(
                key: ValueKey('leaderboard-divider-${rows[index].rank}'),
                height: 1,
                indent: 42,
                color: pageBorderColor(context),
              ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardListRow extends StatelessWidget {
  const _LeaderboardListRow({
    required this.row,
    required this.metric,
    required this.currentUserSession,
  });

  final StreakLeaderboardRow row;
  final String metric;
  final UserSessionSnapshot currentUserSession;

  @override
  Widget build(BuildContext context) {
    final streakKind = metric == 'longest' ? 'Best streak' : 'Current streak';
    final score = _scoreLabel(row.score);
    final primary = Theme.of(context).colorScheme.primary;
    final isCurrentUser = _isCurrentUser(row, currentUserSession);

    return Semantics(
      container: true,
      label: 'Rank ${row.rank}, ${row.displayName}, $score, $streakKind',
      child: Container(
        key: ValueKey('leaderboard-number-row-${row.userId}'),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isCurrentUser
              ? Border.all(color: primary.withValues(alpha: 0.28))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              key: ValueKey('leaderboard-number-marker-${row.userId}'),
              width: 31,
              child: Text(
                '${row.rank}',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCurrentUser
                      ? primary
                      : pageSecondaryTextColor(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 7),
            _LeaderboardAvatar(
              key: ValueKey('leaderboard-avatar-${row.userId}'),
              row: row,
              currentUserSession: currentUserSession,
              size: 43,
              borderColor: _avatarColor(row.avatarColor),
            ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCurrentUser ? '$streakKind - You' : streakKind,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 82),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  score,
                  maxLines: 1,
                  style: TextStyle(
                    color: isCurrentUser
                        ? primary
                        : pagePrimaryTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardAvatar extends StatelessWidget {
  const _LeaderboardAvatar({
    super.key,
    required this.row,
    required this.currentUserSession,
    required this.size,
    required this.borderColor,
  });

  final StreakLeaderboardRow row;
  final UserSessionSnapshot currentUserSession;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final avatarAsset = _leaderboardAvatarAsset(row, currentUserSession);

    return Semantics(
      image: true,
      label: 'Avatar for ${row.displayName}',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor,
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: avatarAsset.isNotEmpty
            ? ExcludeSemantics(
                child: _DefaultAvatar(
                  semanticLabel: 'Avatar for ${row.displayName}',
                  assetPath: avatarAsset,
                  size: size - 5,
                ),
              )
            : ExcludeSemantics(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    row.initials,
                    maxLines: 1,
                    style: TextStyle(
                      color: borderColor,
                      fontSize: size * 0.29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({
    required this.semanticLabel,
    required this.assetPath,
    this.size = 48,
  });

  final String semanticLabel;
  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: size * 0.62,
              );
            },
          ),
        ),
      ),
    );
  }
}

String _leaderboardAvatarAsset(
  StreakLeaderboardRow row,
  UserSessionSnapshot currentUserSession,
) {
  final rowGender = row.gender?.trim() ?? '';
  final rowUserType = row.userType?.trim() ?? '';
  final rowAvatarAsset = row.avatarAsset.trim();
  final hasSessionProfile =
      currentUserSession.gender?.trim().isNotEmpty == true &&
      currentUserSession.userType?.trim().isNotEmpty == true;

  if (_isCurrentUser(row, currentUserSession) && hasSessionProfile) {
    return suggestedProfileAvatarAsset(
      currentUserSession.gender,
      currentUserSession.userType,
    );
  }

  if (rowGender.isNotEmpty && rowUserType.isNotEmpty) {
    return suggestedProfileAvatarAsset(rowGender, rowUserType);
  }

  return rowAvatarAsset.isNotEmpty
      ? rowAvatarAsset
      : _defaultLeaderboardAvatarPath;
}

bool _isCurrentUser(
  StreakLeaderboardRow row,
  UserSessionSnapshot currentUserSession,
) {
  final currentUserId = currentUserSession.userId;
  return row.isCurrentUser ||
      (currentUserId != null && row.userId == currentUserId);
}

Color _avatarColor(String value) {
  final hex = value.trim().replaceFirst('#', '');
  try {
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  } catch (_) {
    // Use the leaderboard default below.
  }

  return const Color(0xFF1D8CA8);
}

Color _podiumAccent(BuildContext context, int rank) {
  return switch (rank) {
    1 => const Color(0xFFFFB800),
    2 => const Color(0xFF0EA5E9),
    3 => const Color(0xFF10B981),
    _ => Theme.of(context).colorScheme.primary,
  };
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard({
    required this.icon,
    this.animationAsset,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String? animationAsset;
  final String title;
  final String message;

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
  const _LeaderboardError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final message = _leaderboardErrorMessage(error);

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
            _leaderboardErrorIcon(error),
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
            message,
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

String _scoreLabel(int score) {
  return '$score ${score == 1 ? 'day' : 'days'}';
}

IconData _leaderboardErrorIcon(Object? error) {
  if (error is StreakApiException) {
    if (error.isAuthError) {
      return Icons.lock_outline_rounded;
    }

    if (!error.isNetworkError) {
      return Icons.cloud_off_outlined;
    }
  }

  return Icons.wifi_off_rounded;
}

String _leaderboardErrorMessage(Object? error) {
  if (error is StreakApiException) {
    return error.message;
  }

  final message = error?.toString().replaceFirst('Exception: ', '').trim();

  return message?.isNotEmpty == true
      ? message!
      : 'Unable to reach the VitalySync API right now.';
}
