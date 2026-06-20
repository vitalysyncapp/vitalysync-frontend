import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/main_navigation.dart';
import '../../../../features/log/data/log_api.dart';
import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../features/tutorial/services/core_tutorial_service.dart';
import '../../../../shared/notifications/local_notification_service.dart';
import '../../../../shared/notifications/notification_payload_router.dart';
import '../../../../shared/preferences/session_reset_service.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/animated_gradient_background.dart';
import 'auth_start_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _onboardingRefreshTimeout = Duration(seconds: 3);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final session = await UserSessionController.instance.load();
    final email = session.email;
    final userId = session.userId;
    final signedInUserId = userId ?? 0;
    final onboardingCompleted = session.onboardingCompleted;
    final hasSignedInAccount =
        session.isLoggedIn &&
        session.hasAuthToken &&
        email?.trim().isNotEmpty == true &&
        signedInUserId > 0;

    if (hasSignedInAccount) {
      unawaited(_refreshStartupData(signedInUserId));

      if (!mounted) return;

      final launchPayload = LocalNotificationService.instance
          .consumePendingLaunchPayload();
      final showTutorialOnStart =
          onboardingCompleted &&
          await CoreTutorialService.instance.shouldShowForUser(signedInUserId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => onboardingCompleted
              ? MainNavigation(
                  initialIndex: tabIndexForNotificationPayload(launchPayload),
                  openNutritionLogOnStart: shouldOpenNutritionLog(
                    launchPayload,
                  ),
                  tutorialUserId: signedInUserId,
                  showTutorialOnStart: showTutorialOnStart,
                )
              : OnboardingPage(userId: signedInUserId),
        ),
      );
      return;
    }

    if (session.isLoggedIn || session.hasAuthToken || userId != null) {
      try {
        await SessionResetService.instance.resetForLogout();
      } catch (error, stackTrace) {
        debugPrint('Unable to fully reset invalid startup session: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthStartPage()),
    );
  }

  Future<void> _refreshStartupData(int userId) async {
    await Future.wait([
      _refreshStreakFromBackend(),
      _refreshOnboardingSummary(userId),
    ]);
  }

  Future<void> _refreshStreakFromBackend() async {
    try {
      await LogApi.syncStreakFromBackend();
    } catch (_) {
      // Keep cached streak data if startup refresh fails.
    }
  }

  Future<void> _refreshOnboardingSummary(int userId) async {
    try {
      final summary = await OnboardingApi.fetchSummary(
        userId,
      ).timeout(_onboardingRefreshTimeout);
      final currentSession = await UserSessionController.instance.load();
      if (currentSession.userId != userId || !currentSession.hasAuthToken) {
        return;
      }

      final onboardingCompleted = summary['onboarding_completed'] == true;
      if (onboardingCompleted) {
        await OnboardingService.saveDefaultsFromSummary(summary);
      }
      await UserSessionController.instance.updateOnboardingCompleted(
        onboardingCompleted,
      );
    } catch (_) {
      // Keep cached onboarding state if startup refresh is slow or unavailable.
    }
  }

  Widget glassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(padding: const EdgeInsets.all(30), child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedGradientBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: glassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 110,
                      maxHeight: 110,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'VitalySync',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : const Color.fromARGB(221, 43, 0, 88),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 18),
                  Text(
                    'VitalySync provides wellness insights only and does not replace medical advice.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.78)
                          : const Color(0xFF475569),
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
