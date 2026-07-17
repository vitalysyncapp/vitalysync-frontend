import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StreakShareCard extends StatelessWidget {
  final String displayName;
  final int currentStreak;
  final int longestStreak;
  final int availableSavers;
  final int protectedDayCount;
  final int? globalRank;
  final int? localRank;
  final bool isOffline;

  const StreakShareCard({
    super.key,
    required this.displayName,
    required this.currentStreak,
    required this.longestStreak,
    required this.availableSavers,
    required this.protectedDayCount,
    this.globalRank,
    this.localRank,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleGlobalRank = _topHundredRank(globalRank);
    final visibleLocalRank = _topHundredRank(localRank);
    final hasRankBadges = visibleGlobalRank != null || visibleLocalRank != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF086F83,
            ).withValues(alpha: isDark ? 0.32 : 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      Color(0xFF102A43),
                      Color(0xFF086F83),
                      Color(0xFF0E8E9B),
                    ]
                  : const [
                      Color(0xFF075E75),
                      Color(0xFF1193AE),
                      Color(0xFF45B8D8),
                    ],
              stops: const [0, 0.56, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -54,
                right: -42,
                child: Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.09),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -74,
                bottom: -112,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFB547).withValues(alpha: 0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final identity = _StreakIdentity(
                        displayName: displayName,
                        isOffline: isOffline,
                      );

                      if (!hasRankBadges) return identity;

                      final badges = _RankBadges(
                        globalRank: visibleGlobalRank,
                        localRank: visibleLocalRank,
                        direction: constraints.maxWidth >= 290
                            ? Axis.vertical
                            : Axis.horizontal,
                      );

                      if (constraints.maxWidth >= 290) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: identity),
                            const SizedBox(width: 10),
                            badges,
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          identity,
                          const SizedBox(height: 10),
                          badges,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currentStreak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          height: 0.86,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -3,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAY${currentStreak == 1 ? '' : 'S'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'STREAK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD166),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Keep your momentum going',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 300 ? 3 : 1;
                      final itemWidth = columns == 3
                          ? (constraints.maxWidth - 16) / 3
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ShareMetric(
                            width: itemWidth,
                            icon: Icons.emoji_events_outlined,
                            label: 'Best',
                            value: '$longestStreak days',
                          ),
                          _ShareMetric(
                            width: itemWidth,
                            icon: Icons.shield_outlined,
                            label: 'Savers',
                            value: '$availableSavers left',
                          ),
                          _ShareMetric(
                            width: itemWidth,
                            icon: Icons.auto_fix_high_rounded,
                            label: 'Protected',
                            value: '$protectedDayCount days',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.monitor_heart_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VitalySync',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakIdentity extends StatelessWidget {
  final String displayName;
  final bool isOffline;

  const _StreakIdentity({required this.displayName, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9F1C).withValues(alpha: 0.24),
                blurRadius: 18,
              ),
            ],
          ),
          child: Semantics(
            label: 'Animated burning fire',
            child: ExcludeSemantics(
              child: Lottie.asset(
                'assets/animations/streak_fire.json',
                animate: !MediaQuery.disableAnimationsOf(context),
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isOffline ? 'VitalySync streak snapshot' : 'VitalySync streak',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankBadges extends StatelessWidget {
  final int? globalRank;
  final int? localRank;
  final Axis direction;

  const _RankBadges({
    required this.globalRank,
    required this.localRank,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('personal-streak-ranks'),
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        direction: direction,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: [
          if (globalRank case final rank?)
            _RankBadge(
              key: const ValueKey('personal-streak-global-rank'),
              label: 'Global',
              rank: rank,
              icon: Icons.public_rounded,
              accent: const Color(0xFFFFD166),
            ),
          if (localRank case final rank?)
            _RankBadge(
              key: const ValueKey('personal-streak-local-rank'),
              label: 'Local',
              rank: rank,
              icon: Icons.location_on_rounded,
              accent: const Color(0xFFB9FBC0),
            ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final String label;
  final int rank;
  final IconData icon;
  final Color accent;

  const _RankBadge({
    super.key,
    required this.label,
    required this.rank,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label streak rank $rank',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 13),
              const SizedBox(width: 4),
              Text(
                '$label #$rank',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int? _topHundredRank(int? rank) {
  return rank != null && rank >= 1 && rank <= 100 ? rank : null;
}

class _ShareMetric extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _ShareMetric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.17),
              Colors.white.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFFE29A), size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
