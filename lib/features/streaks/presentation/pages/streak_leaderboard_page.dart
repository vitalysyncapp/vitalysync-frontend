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
const _defaultLeaderboardAvatarPath = 'assets/images/user.png';

typedef StreakLeaderboardLoader =
    Future<StreakLeaderboard> Function({
      required String section,
      required String metric,
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
    return loader(section: _section, metric: _metric);
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
        ? 'Ranked by each user\'s all-time best streak.'
        : 'Ranked by active streaks and privacy-safe profiles.';

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

    final orderedRows = [...leaderboard.rows]
      ..sort((left, right) => left.rank.compareTo(right.rank));
    final podiumRows = orderedRows
        .where((row) => row.rank >= 1 && row.rank <= 5)
        .toList();
    final remainingRows = orderedRows
        .where((row) => row.rank < 1 || row.rank > 5)
        .toList();

    return Column(
      key: const ValueKey('leaderboard-list'),
      children: [
        if (podiumRows.isNotEmpty)
          _TopFivePodium(
            rows: podiumRows,
            metric: metric,
            currentUserSession: currentUserSession,
          ),
        if (podiumRows.isNotEmpty && remainingRows.isNotEmpty)
          const SizedBox(height: 14),
        for (final row in remainingRows)
          _LeaderboardRow(
            row: row,
            metric: metric,
            currentUserSession: currentUserSession,
            presentation: row.rank >= 6 && row.rank <= 10
                ? _RankPresentation.medal
                : _RankPresentation.number,
          ),
      ],
    );
  }
}

class _TopFivePodium extends StatelessWidget {
  const _TopFivePodium({
    required this.rows,
    required this.metric,
    required this.currentUserSession,
  });

  final List<StreakLeaderboardRow> rows;
  final String metric;
  final UserSessionSnapshot currentUserSession;

  List<StreakLeaderboardRow> _inRankOrder(List<int> ranks) {
    final rowsByRank = {for (final row in rows) row.rank: row};
    return [for (final rank in ranks) ?rowsByRank[rank]];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('leaderboard-podium'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
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
                child: Text(
                  'Top 5 streaks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 560) {
                return _PodiumLine(
                  rows: _inRankOrder(const [4, 2, 1, 3, 5]),
                  metric: metric,
                  currentUserSession: currentUserSession,
                  maxWidth: constraints.maxWidth,
                  maxTileWidth: 108,
                  spacing: 8,
                );
              }

              final upperRows = _inRankOrder(const [2, 1, 3]);
              final lowerRows = _inRankOrder(const [4, 5]);

              return Column(
                children: [
                  if (upperRows.isNotEmpty)
                    _PodiumLine(
                      rows: upperRows,
                      metric: metric,
                      currentUserSession: currentUserSession,
                      maxWidth: constraints.maxWidth,
                      maxTileWidth: 118,
                      spacing: 8,
                    ),
                  if (upperRows.isNotEmpty && lowerRows.isNotEmpty)
                    const SizedBox(height: 10),
                  if (lowerRows.isNotEmpty)
                    _PodiumLine(
                      rows: lowerRows,
                      metric: metric,
                      currentUserSession: currentUserSession,
                      maxWidth: constraints.maxWidth,
                      maxTileWidth: 138,
                      spacing: 8,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PodiumLine extends StatelessWidget {
  const _PodiumLine({
    required this.rows,
    required this.metric,
    required this.currentUserSession,
    required this.maxWidth,
    required this.maxTileWidth,
    required this.spacing,
  });

  final List<StreakLeaderboardRow> rows;
  final String metric;
  final UserSessionSnapshot currentUserSession;
  final double maxWidth;
  final double maxTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final gaps = spacing * (rows.length - 1);
    final availableTileWidth = (maxWidth - gaps) / rows.length;
    final tileWidth = availableTileWidth.clamp(64.0, maxTileWidth).toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          SizedBox(
            width: tileWidth,
            child: Padding(
              padding: EdgeInsets.only(top: _podiumTopInset(rows[index].rank)),
              child: _PodiumTile(
                row: rows[index],
                metric: metric,
                currentUserSession: currentUserSession,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({
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
    final avatarSize = switch (row.rank) {
      1 => 48.0,
      2 || 3 => 43.0,
      _ => 40.0,
    };
    final pedestalHeight = switch (row.rank) {
      1 => 30.0,
      2 => 26.0,
      3 => 23.0,
      _ => 20.0,
    };
    final score = _scoreLabel(row.score);
    final streakKind = metric == 'longest' ? 'Best streak' : 'Current streak';

    return Semantics(
      container: true,
      label: 'Rank ${row.rank}, ${row.displayName}, $score, $streakKind',
      child: Container(
        key: ValueKey('leaderboard-podium-user-${row.userId}'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: isWinner
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFACC15).withValues(alpha: 0.2),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isWinner ? null : pageSubtleSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: row.isCurrentUser
                ? Theme.of(context).colorScheme.primary
                : accent.withValues(alpha: 0.5),
            width: row.isCurrentUser ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 7),
              child: Column(
                children: [
                  Icon(
                    isWinner
                        ? Icons.workspace_premium_rounded
                        : Icons.leaderboard_rounded,
                    color: accent,
                    size: isWinner ? 23 : 19,
                  ),
                  const SizedBox(height: 5),
                  _DefaultAvatar(
                    key: ValueKey('leaderboard-default-avatar-${row.userId}'),
                    semanticLabel: 'Default avatar for ${row.displayName}',
                    assetPath: _leaderboardAvatarAsset(row, currentUserSession),
                    size: avatarSize,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    row.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pagePrimaryTextColor(context),
                      fontSize: row.rank <= 3 ? 12.5 : 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        score,
                        maxLines: 1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: pedestalHeight,
              alignment: Alignment.center,
              color: accent.withValues(alpha: isWinner ? 0.3 : 0.2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${row.rank}',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 12,
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

enum _RankPresentation { medal, number }

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.row,
    required this.metric,
    required this.currentUserSession,
    required this.presentation,
  });

  final StreakLeaderboardRow row;
  final String metric;
  final UserSessionSnapshot currentUserSession;
  final _RankPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final isBest = metric == 'longest';
    final streakKind = isBest ? 'Best streak' : 'Current streak';
    final score = _scoreLabel(row.score);

    return Semantics(
      container: true,
      label: 'Rank ${row.rank}, ${row.displayName}, $score, $streakKind',
      child: Container(
        key: ValueKey(
          presentation == _RankPresentation.medal
              ? 'leaderboard-medal-row-${row.userId}'
              : 'leaderboard-number-row-${row.userId}',
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: row.isCurrentUser
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: row.isCurrentUser
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.34)
                : pageBorderColor(context),
          ),
          boxShadow: pageCardShadow(context),
        ),
        child: Row(
          children: [
            _RankMarker(row: row, presentation: presentation),
            const SizedBox(width: 8),
            _DefaultAvatar(
              key: ValueKey('leaderboard-default-avatar-${row.userId}'),
              semanticLabel: 'Default avatar for ${row.displayName}',
              assetPath: _leaderboardAvatarAsset(row, currentUserSession),
              size: 44,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                row.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
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
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 15,
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

class _RankMarker extends StatelessWidget {
  const _RankMarker({required this.row, required this.presentation});

  final StreakLeaderboardRow row;
  final _RankPresentation presentation;

  @override
  Widget build(BuildContext context) {
    if (presentation == _RankPresentation.medal) {
      return Container(
        key: ValueKey('leaderboard-medal-marker-${row.userId}'),
        width: 40,
        height: 46,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.military_tech_rounded,
              color: Color(0xFFF59E0B),
              size: 23,
            ),
            Text(
              '${row.rank}',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 9.5,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      key: ValueKey('leaderboard-number-marker-${row.userId}'),
      width: 40,
      child: Text(
        '${row.rank}',
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: pagePrimaryTextColor(context),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({
    super.key,
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
  final currentUserId = currentUserSession.userId;
  final isCurrentUser =
      row.isCurrentUser ||
      (currentUserId != null && row.userId == currentUserId);
  if (!isCurrentUser) return _defaultLeaderboardAvatarPath;

  return suggestedProfileAvatarAsset(
    currentUserSession.gender,
    currentUserSession.userType,
  );
}

double _podiumTopInset(int rank) {
  return switch (rank) {
    1 => 0,
    2 => 14,
    3 => 22,
    4 => 18,
    _ => 26,
  };
}

Color _podiumAccent(BuildContext context, int rank) {
  return switch (rank) {
    1 => const Color(0xFFF5B700),
    2 => const Color(0xFF94A3B8),
    3 => const Color(0xFFC26A2E),
    4 => Theme.of(context).colorScheme.primary,
    _ => const Color(0xFF38A7C4),
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
