import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/main_navigation.dart';
import '../../../../features/log/data/log_api.dart';
import '../../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../shared/config/api_config.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../widgets/auth_chrome.dart';
import 'forgot_password_page.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  final String loginUrl = ApiConfig.auth('/login');

  @override
  void initState() {
    super.initState();
    _prefillCachedEmail();
  }

  Future<void> _prefillCachedEmail() async {
    final cachedEmail = await UserSessionController.instance
        .loadLastLoginEmail();
    if (!mounted || cachedEmail == null || emailController.text.isNotEmpty) {
      return;
    }

    emailController.text = cachedEmail;
  }

  String _loginFailureMessage(http.Response response) {
    const fallback = 'Login failed';

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final serverMessage = decoded['message'] ?? decoded['error'];
        final normalizedMessage = serverMessage?.toString().trim();

        if (normalizedMessage != null && normalizedMessage.isNotEmpty) {
          return normalizedMessage;
        }
      }
    } catch (_) {
      // Keep the user-facing fallback when the server does not return JSON.
    }

    return fallback;
  }

  Future<void> login() async {
    if (isLoading) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: await ApiConfig.jsonHeaders(),
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authToken = data['access_token']?.toString().trim();

        if (authToken == null || authToken.isEmpty) {
          if (!mounted) return;
          await ValidationDialog.show(
            context,
            message: 'Login failed: session token was missing.',
            type: ValidationDialogType.error,
          );
          return;
        }

        await UserSessionController.instance.saveUser(
          Map<String, dynamic>.from(data['user'] as Map<String, dynamic>),
          authToken: authToken,
        );
        await LogApi.persistServerStreakSnapshot(
          data['streak'] as Map<String, dynamic>?,
        );

        final user = data['user'] as Map<String, dynamic>;
        final userId = user['user_id'] as int;
        final onboardingCompleted = user['onboarding_completed'] == true;

        if (onboardingCompleted) {
          try {
            final summary = await OnboardingApi.fetchSummary(userId);
            await OnboardingService.saveDefaultsFromSummary(summary);
          } catch (_) {
            // Home and Profile can still use any locally cached defaults.
          }
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => onboardingCompleted
                ? const MainNavigation()
                : OnboardingPage(userId: userId),
          ),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        await ValidationDialog.show(
          context,
          message: _loginFailureMessage(response),
          type: ValidationDialogType.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      await ValidationDialog.show(
        context,
        message:
            'Unable to reach the server right now. Please check your connection and try again.',
        type: ValidationDialogType.connection,
      );
    } finally {
      if (mounted && isLoading) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      illustrationAsset: authWorkStressAsset,
      topOverlayAsset: authMeditationAsset,
      backdropStyle: AuthBackdropStyle.login,
      child: AuthGlassPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthBrandHeader(
              title: 'Welcome back',
              subtitle:
                  'Continue your check-ins and keep your wellness rhythm visible.',
              logoSize: 68,
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: emailController,
              label: 'Email',
              hintText: 'you@gmail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('login-forgot-password-button'),
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordPage(
                              initialEmail: emailController.text.trim(),
                            ),
                          ),
                        );
                      },
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AuthButton.primary(
              label: 'Sign in',
              icon: Icons.login_rounded,
              onPressed: login,
              isLoading: isLoading,
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'New to VitalySync? ',
                  style: GoogleFonts.poppins(
                    color: pageSecondaryTextColor(context),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: Text(
                    'Create account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
