import 'package:flutter/material.dart';

import '../widgets/auth_chrome.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class AuthStartPage extends StatelessWidget {
  const AuthStartPage({super.key});

  static const _encouragingMessage =
      'Start small. Listen to your body, protect your rest, and build healthier rhythms one check-in at a time.';
  static const _disclaimer =
      'VitalySync provides wellness insights for awareness only and does not replace medical advice. If you feel unwell or unsafe, contact a qualified professional or local emergency services.';

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      illustrationAsset: authHealthyLifestyleAsset,
      bottomOverlayAssets: const [authHealthyLifestyleAsset, authWorkoutAsset],
      child: AuthGlassPanel(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthBrandHeader(
              title: 'Your gentle wellness companion',
              subtitle: _encouragingMessage,
              logoSize: 90,
            ),
            const SizedBox(height: 22),
            const AuthFinePrint(
              text: _disclaimer,
              icon: Icons.health_and_safety_rounded,
            ),
            const SizedBox(height: 22),
            AuthButton.primary(
              label: 'Log in',
              icon: Icons.login_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            AuthButton.secondary(
              label: 'Sign up',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
