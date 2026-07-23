import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../../shared/config/api_config.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../../data/email_validator.dart';
import '../widgets/auth_chrome.dart';

typedef PasswordResetRequester = Future<String> Function(String email);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    this.initialEmail,
    this.requestPasswordReset,
  });

  final String? initialEmail;
  final PasswordResetRequester? requestPasswordReset;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isSending = false;
  bool _hasSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<String> _requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse(ApiConfig.auth('/password-reset/request')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({'email': email}),
    );

    final data = _decodeResponseBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Unable to send reset email.');
    }

    return data['message']?.toString() ??
        'If this email belongs to a VitalySync account, a password reset link has been sent.';
  }

  Future<void> _handleSend() async {
    if (_isSending) {
      return;
    }

    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid) {
      await ValidationDialog.show(
        context,
        title: 'Check your email',
        message: 'Enter the email address connected to your account.',
        type: ValidationDialogType.error,
      );
      return;
    }

    final email = EmailValidator.normalize(_emailController.text);

    setState(() => _isSending = true);

    try {
      final requester = widget.requestPasswordReset ?? _requestPasswordReset;
      final message = await requester(email);
      if (!mounted) return;

      setState(() => _hasSent = true);

      await ValidationDialog.show(
        context,
        title: 'Reset email sent',
        message: message,
        type: ValidationDialogType.success,
        duration: const Duration(milliseconds: 2800),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');
      await ValidationDialog.show(
        context,
        title: 'Unable to send email',
        message: message,
        type: ValidationDialogType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return const <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      illustrationAsset: authWorkStressAsset,
      topOverlayAsset: authMeditationAsset,
      backdropStyle: AuthBackdropStyle.login,
      child: AuthGlassPanel(
        key: const ValueKey('forgot-password-page'),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  key: const ValueKey('forgot-password-back-button'),
                  onPressed: _isSending ? null : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: pagePrimaryTextColor(context),
                  ),
                  tooltip: 'Back to sign in',
                ),
              ),
              const AuthBrandHeader(
                title: 'Reset password',
                subtitle:
                    'We will send a secure reset link to your account email.',
                logoSize: 64,
              ),
              const SizedBox(height: 22),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'you@gmail.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => EmailValidator.validate(
                  value,
                  emptyMessage: 'Enter your email',
                ),
              ),
              const SizedBox(height: 16),
              AuthButton.primary(
                label: _hasSent ? 'Send reset link again' : 'Send reset link',
                icon: Icons.send_outlined,
                onPressed: _handleSend,
                isLoading: _isSending,
              ),
              const SizedBox(height: 16),
              AuthFinePrint(
                icon: _hasSent
                    ? Icons.mark_email_read_outlined
                    : Icons.info_outline,
                text: _hasSent
                    ? 'Email sent. Open your inbox, tap the reset link, then choose a new password.'
                    : 'The reset link expires soon and can only be used once.',
              ),
              const SizedBox(height: 10),
              Text(
                'Use the same email you use to sign in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: pageSecondaryTextColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
