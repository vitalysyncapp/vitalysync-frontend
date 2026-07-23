import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

const _saverOrange = Color(0xFFFF7A2F);
const _saverAmber = Color(0xFFFFB800);

Future<void> showStreakSaverInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (context) => const _StreakSaverInfoDialog(),
  );
}

class _StreakSaverInfoDialog extends StatelessWidget {
  const _StreakSaverInfoDialog();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 380;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = math.min(680.0, math.max(340.0, screenSize.height - 40));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 22,
        vertical: 20,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF102033) : Colors.white,
              border: Border.all(color: pageBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(isCompact: isCompact),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 20,
                      18,
                      isCompact ? 16 : 20,
                      16,
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HowItWorksCard(),
                        SizedBox(height: 20),
                        _SectionLabel(label: 'WAYS TO EARN'),
                        SizedBox(height: 10),
                        _RewardRow(
                          icon: Icons.calendar_month_rounded,
                          reward: '3',
                          title: 'Monthly refresh',
                          description:
                              'Get 3 savers at the start of each month.',
                        ),
                        SizedBox(height: 9),
                        _RewardRow(
                          icon: Icons.local_fire_department_rounded,
                          reward: '+1',
                          title: 'Build your first streak',
                          description:
                              'Earn 1 when you reach your first 7-day streak.',
                        ),
                        SizedBox(height: 9),
                        _RewardRow(
                          icon: Icons.fact_check_rounded,
                          reward: '+1',
                          title: 'Check in consistently',
                          description:
                              'Earn 1 after 10 check-ins in a calendar month.',
                        ),
                        SizedBox(height: 9),
                        _RewardRow(
                          icon: Icons.verified_rounded,
                          reward: '+1',
                          title: 'Meet your goals',
                          description:
                              'Earn 1 when you meet a wellness goal on 4 days in a week.',
                        ),
                        SizedBox(height: 14),
                        _ResetNotice(),
                      ],
                    ),
                  ),
                ),
                _DialogFooter(isCompact: isCompact),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final bool isCompact;

  const _DialogHeader({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isCompact ? 16 : 20, 17, 8, 17),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_saverOrange, _saverAmber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How streak savers work',
                  maxLines: 2,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 18 : 20,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A little backup for real-life days',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('streak-saver-dialog-close'),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _saverOrange.withValues(alpha: isDark ? 0.12 : 0.075),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _saverOrange.withValues(alpha: isDark ? 0.26 : 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _saverOrange.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: _saverOrange,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'A streak saver can protect one missed day. When you next log, '
              'you can choose whether to use enough savers to keep your streak.',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: pageSecondaryTextColor(context),
        fontSize: 11.5,
        letterSpacing: 1.15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final String reward;
  final String title;
  final String description;

  const _RewardRow({
    required this.icon,
    required this.reward,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _saverOrange.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _saverOrange, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 12.2,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_saverOrange, _saverAmber],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              reward,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetNotice extends StatelessWidget {
  const _ResetNotice();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const color = Color(0xFF0F9F75);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.13 : 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.refresh_rounded, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Your saver balance resets each month, so unused and earned '
              'savers do not carry over.',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final bool isCompact;

  const _DialogFooter({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 20,
        12,
        isCompact ? 16 : 20,
        isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context).withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: pageBorderColor(context))),
      ),
      child: ElevatedButton.icon(
        key: const ValueKey('streak-saver-dialog-done'),
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.check_rounded, size: 19),
        label: const Text('Got it'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          backgroundColor: _saverOrange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
