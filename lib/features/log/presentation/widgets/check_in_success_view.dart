import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import 'package:vitalysync/l10n/localized_text.dart';

const _streakFireAnimationPath = 'assets/animations/streak_fire.json';
const _healthyHeartAnimationPath = 'assets/animations/healthy_heart.json';

class CheckInSuccessView extends StatelessWidget {
  final bool isOffline;
  final bool hasPendingSync;
  final int pendingSyncCount;
  final int currentStreak;
  final VoidCallback onRedo;

  const CheckInSuccessView({
    super.key,
    required this.isOffline,
    required this.hasPendingSync,
    required this.pendingSyncCount,
    required this.currentStreak,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RevealOnBuild(
      duration: const Duration(milliseconds: 620),
      beginOffset: const Offset(0, 0.025),
      child: Center(
        key: const ValueKey('success_screen'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              key: const ValueKey('check-in-success-card'),
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF182A3D), Color(0xFF102534)]
                      : const [Color(0xFFFFFFFF), Color(0xFFF1FCF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(
                    0xFF1FB489,
                  ).withValues(alpha: isDark ? 0.22 : 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.26 : 0.075,
                    ),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: const Color(
                      0xFF1FB489,
                    ).withValues(alpha: isDark ? 0.08 : 0.06),
                    blurRadius: 30,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SuccessAnimation(),
                  const SizedBox(height: 18),
                  LocalizedText(
                    isOffline ? 'Check-in saved offline' : 'Check-in saved!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.45,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LocalizedText(
                    hasPendingSync
                        ? 'Your daily wellness log is saved on this device. It will sync automatically when internet access is available again.'
                        : 'Your daily wellness log has been recorded. Come back tomorrow for your next check-in, or redo today\'s entry if you need to update it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: pageSecondaryTextColor(context),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SuccessStreakBadge(currentStreak: currentStreak),
                  if (hasPendingSync) ...[
                    const SizedBox(height: 12),
                    _PendingSyncBanner(pendingSyncCount: pendingSyncCount),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: onRedo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pagePrimaryTextColor(context),
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.035)
                            : Colors.white.withValues(alpha: 0.72),
                        side: BorderSide(color: pageBorderColor(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const LocalizedText(
                        'Redo today\'s log',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessAnimation extends StatelessWidget {
  const _SuccessAnimation();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF173D4D), Color(0xFF173344)]
                      : const [Color(0xFFE4FAF2), Color(0xFFE0F2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1FB489).withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF1FB489,
                    ).withValues(alpha: isDark ? 0.22 : 0.16),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Lottie.asset(
                _healthyHeartAnimationPath,
                width: 86,
                height: 86,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.favorite_rounded,
                    size: 48,
                    color: Color(0xFF1FB489),
                  );
                },
              ),
            ),
            Positioned(
              right: 4,
              bottom: 6,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1FB489),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessStreakBadge extends StatelessWidget {
  final int currentStreak;

  const _SuccessStreakBadge({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final streakText = currentStreak == 1
        ? '1 day streak'
        : '$currentStreak day streak';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFFFF8A1F).withValues(alpha: 0.16),
                  const Color(0xFFFBBF24).withValues(alpha: 0.07),
                ]
              : const [Color(0xFFFFF7ED), Color(0xFFFFFBEB)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF8A1F).withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A1F).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            _streakFireAnimationPath,
            width: 46,
            height: 46,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.local_fire_department_rounded,
              size: 46,
              color: Color(0xFFFF8A1F),
            ),
          ),
          const SizedBox(height: 3),
          LocalizedText(
            streakText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFF7C2D12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSyncBanner extends StatelessWidget {
  final int pendingSyncCount;

  const _PendingSyncBanner({required this.pendingSyncCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2563EB).withValues(alpha: 0.12)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF60A5FA).withValues(alpha: 0.28)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: LocalizedText(
              '$pendingSyncCount pending check-in${pendingSyncCount == 1 ? '' : 's'} will upload in the background.',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFF1E3A8A),
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
