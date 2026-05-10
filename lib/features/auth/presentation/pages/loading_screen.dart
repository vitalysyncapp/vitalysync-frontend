import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/main_navigation.dart';
import '../../../../features/log/data/log_api.dart';
import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../shared/notifications/local_notification_service.dart';
import '../../../../shared/notifications/notification_payload_router.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/animated_gradient_background.dart';
import 'login_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final session = await UserSessionController.instance.load();
    final email = session.email;
    final userId = session.userId;
    final isDemoMode = session.isDemoMode;
    var onboardingCompleted = session.onboardingCompleted;

    if ((email != null && userId != null) || isDemoMode) {
      try {
        await LogApi.syncStreakFromBackend();
      } catch (_) {
        // Keep the cached streak if the refresh fails during boot.
      }

      if (!isDemoMode && userId != null && userId > 0) {
        try {
          final summary = await OnboardingApi.fetchSummary(userId);
          onboardingCompleted = summary['onboarding_completed'] == true;
          if (onboardingCompleted) {
            await OnboardingService.saveDefaultsFromSummary(summary);
          }
          await UserSessionController.instance.updateOnboardingCompleted(
            onboardingCompleted,
          );
        } catch (_) {
          // Fall back to the locally cached onboarding state.
        }
      }

      if (!mounted) return;

      final launchPayload = LocalNotificationService.instance
          .consumePendingLaunchPayload();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => (isDemoMode || onboardingCompleted)
              ? MainNavigation(
                  initialIndex: tabIndexForNotificationPayload(launchPayload),
                  openNutritionLogOnStart: shouldOpenNutritionLog(
                    launchPayload,
                  ),
                )
              : OnboardingPage(userId: userId!),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
