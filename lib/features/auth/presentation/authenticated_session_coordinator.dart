import 'package:flutter/material.dart';

import '../../../app/main_navigation.dart';
import '../../log/data/log_api.dart';
import '../../onboarding/data/onboarding_api.dart';
import '../../onboarding/presentation/pages/onboarding_page.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../../../shared/preferences/user_session.dart';

Future<void> completeAuthenticatedSession(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final authToken = data['access_token']?.toString().trim();
  final rawUser = data['user'];
  if (authToken == null || authToken.isEmpty || rawUser is! Map) {
    throw const FormatException('Session response was incomplete.');
  }

  final user = Map<String, dynamic>.from(rawUser);
  final userId = int.tryParse(user['user_id']?.toString() ?? '');
  if (userId == null || userId <= 0) {
    throw const FormatException('Session user was invalid.');
  }

  await UserSessionController.instance.saveUser(user, authToken: authToken);
  await LogApi.persistServerStreakSnapshot(
    data['streak'] is Map
        ? Map<String, dynamic>.from(data['streak'] as Map)
        : null,
  );

  final onboardingCompleted = user['onboarding_completed'] == true;
  if (onboardingCompleted) {
    try {
      final summary = await OnboardingApi.fetchSummary(userId);
      await OnboardingService.saveDefaultsFromSummary(summary);
    } catch (_) {
      // Existing cached defaults remain usable when summary refresh is offline.
    }
  }

  if (!context.mounted) {
    return;
  }
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => onboardingCompleted
          ? const MainNavigation()
          : OnboardingPage(userId: userId),
    ),
    (route) => false,
  );
}
