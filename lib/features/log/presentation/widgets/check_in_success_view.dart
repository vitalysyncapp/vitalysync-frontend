import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/theme/app_page_style.dart';

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
    return Center(
      key: const ValueKey('success_screen'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _SuccessAnimation(),
            const SizedBox(height: 18),
            Text(
              isOffline ? 'Check-in saved offline' : 'Check-in saved!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: pagePrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasPendingSync
                  ? 'Your daily wellness log is saved on this device. It will sync automatically when internet access is available again.'
                  : 'Your daily wellness log has been recorded. Come back tomorrow for your next check-in, or redo today\'s entry if you need to update it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: pageSecondaryTextColor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _SuccessStreakBadge(currentStreak: currentStreak),
            if (hasPendingSync) ...[
              const SizedBox(height: 12),
              _PendingSyncBanner(pendingSyncCount: pendingSyncCount),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onRedo,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Redo today\'s log',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessAnimation extends StatelessWidget {
  const _SuccessAnimation();

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFFE0F2FE),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                    blurRadius: 14,
                    spreadRadius: 1,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFFF8A1F).withValues(alpha: 0.12)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A1F).withValues(alpha: 0.34),
        ),
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
          Text(
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pendingSyncCount pending check-in${pendingSyncCount == 1 ? '' : 's'} will upload in the background.',
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
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
