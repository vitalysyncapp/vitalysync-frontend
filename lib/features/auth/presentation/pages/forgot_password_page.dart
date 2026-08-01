import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/preferences/session_reset_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/new_password_fields.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../../data/email_validator.dart';
import '../../data/password_reset_api.dart';
import '../widgets/auth_chrome.dart';
import '../widgets/verification_code_field.dart';
import 'auth_start_page.dart';
import 'package:vitalysync/l10n/localized_text.dart';

typedef PasswordResetRequester = Future<String> Function(String email);
typedef PasswordResetCodeVerifier =
    Future<String> Function(String email, String code);
typedef PasswordResetConfirmer =
    Future<String> Function(
      String resetToken,
      String newPassword,
      String confirmPassword,
    );

enum _ForgotPasswordStage { email, code, password, success }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    this.initialEmail,
    this.requestPasswordReset,
    this.verifyPasswordResetCode,
    this.confirmPasswordReset,
    this.resetSession,
    this.resendCooldown = const Duration(seconds: 60),
  });

  final String? initialEmail;
  final PasswordResetRequester? requestPasswordReset;
  final PasswordResetCodeVerifier? verifyPasswordResetCode;
  final PasswordResetConfirmer? confirmPasswordReset;
  final Future<void> Function()? resetSession;
  final Duration resendCooldown;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  _ForgotPasswordStage _stage = _ForgotPasswordStage.email;
  bool _isSubmitting = false;
  String? _resetToken;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownSeconds = widget.resendCooldown.inSeconds;
    if (_cooldownSeconds <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
        return;
      }
      setState(() => _cooldownSeconds--);
    });
  }

  Future<void> _requestCode({bool resend = false}) async {
    if (_isSubmitting) return;
    if (_stage == _ForgotPasswordStage.email &&
        !(_formKey.currentState?.validate() ?? false)) {
      await ValidationDialog.show(
        context,
        title: 'Check your email',
        message: 'Enter the email address connected to your account.',
        type: ValidationDialogType.error,
      );
      return;
    }

    final email = EmailValidator.normalize(_emailController.text);
    setState(() => _isSubmitting = true);
    try {
      final requester =
          widget.requestPasswordReset ?? PasswordResetApi.requestCode;
      final message = await requester(email);
      if (!mounted) return;
      setState(() {
        _stage = _ForgotPasswordStage.code;
        _codeController.clear();
      });
      _startCooldown();
      await ValidationDialog.show(
        context,
        title: resend ? 'New code sent' : 'Reset code sent',
        message: message,
        type: ValidationDialogType.success,
        duration: const Duration(milliseconds: 1800),
      );
    } catch (error) {
      if (!mounted) return;
      await _showError('Unable to send code', error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final verifier =
          widget.verifyPasswordResetCode ?? PasswordResetApi.verifyCode;
      final resetToken = await verifier(
        EmailValidator.normalize(_emailController.text),
        _codeController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _resetToken = resetToken;
        _stage = _ForgotPasswordStage.password;
      });
    } catch (error) {
      if (!mounted) return;
      await _showError('Code not verified', error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final resetToken = _resetToken;
    if (resetToken == null || resetToken.isEmpty) {
      setState(() => _stage = _ForgotPasswordStage.email);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final confirmer =
          widget.confirmPasswordReset ??
          (token, password, confirmation) => PasswordResetApi.resetPassword(
            resetToken: token,
            newPassword: password,
            confirmPassword: confirmation,
          );
      final message = await confirmer(
        resetToken,
        _passwordController.text.trim(),
        _confirmPasswordController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _stage = _ForgotPasswordStage.success);
      await ValidationDialog.show(
        context,
        title: 'Password changed',
        message: message,
        type: ValidationDialogType.success,
        duration: const Duration(milliseconds: 1800),
      );
      await (widget.resetSession ??
          SessionResetService.instance.resetForLogout)();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthStartPage()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      await _showError('Unable to change password', error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showError(String title, Object error) {
    return ValidationDialog.show(
      context,
      title: title,
      message: error.toString().replaceFirst('Exception: ', ''),
      type: ValidationDialogType.error,
    );
  }

  void _handleBack() {
    if (_stage == _ForgotPasswordStage.email) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _stage = _ForgotPasswordStage.email;
      _resetToken = null;
      _codeController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
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
                  onPressed: _isSubmitting ? null : _handleBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
              ),
              AuthBrandHeader(title: _title, subtitle: _subtitle, logoSize: 64),
              const SizedBox(height: 22),
              _buildStageContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _ForgotPasswordStage.email:
        return Column(
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'you@gmail.com'.localizedCopy(context),
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => EmailValidator.validate(
                value,
                emptyMessage: 'Enter your email',
              ),
            ),
            const SizedBox(height: 16),
            AuthButton.primary(
              key: const ValueKey('send-reset-code-button'),
              label: 'Send reset code',
              icon: Icons.send_outlined,
              onPressed: () => _requestCode(),
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 16),
            const AuthFinePrint(
              icon: Icons.timer_outlined,
              text:
                  'The six-digit code expires in 10 minutes and can only be used once.',
            ),
          ],
        );
      case _ForgotPasswordStage.code:
        return Column(
          children: [
            VerificationCodeField(
              controller: _codeController,
              enabled: !_isSubmitting,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            AuthButton.primary(
              key: const ValueKey('verify-reset-code-button'),
              label: 'Verify code',
              icon: Icons.verified_outlined,
              onPressed: _verifyCode,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 10),
            TextButton(
              key: const ValueKey('resend-reset-code-button'),
              onPressed: _isSubmitting || _cooldownSeconds > 0
                  ? null
                  : () => _requestCode(resend: true),
              child: LocalizedText(
                _cooldownSeconds > 0
                    ? 'Send again in ${_cooldownSeconds}s'
                    : 'Send a new code',
              ),
            ),
            LocalizedText(
              'Code sent to ${EmailValidator.normalize(_emailController.text)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: pageSecondaryTextColor(context),
                fontSize: 12.5,
              ),
            ),
          ],
        );
      case _ForgotPasswordStage.password:
        return Column(
          children: [
            NewPasswordFields(
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 18),
            AuthButton.primary(
              key: const ValueKey('confirm-password-reset-button'),
              label: 'Change password',
              icon: Icons.lock_reset_rounded,
              onPressed: _resetPassword,
              isLoading: _isSubmitting,
            ),
          ],
        );
      case _ForgotPasswordStage.success:
        return const Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        );
    }
  }

  String get _title => switch (_stage) {
    _ForgotPasswordStage.email => 'Reset password',
    _ForgotPasswordStage.code => 'Enter your code',
    _ForgotPasswordStage.password => 'Choose a new password',
    _ForgotPasswordStage.success => 'Password changed',
  };

  String get _subtitle => switch (_stage) {
    _ForgotPasswordStage.email =>
      'We will send a six-digit code to your account email.',
    _ForgotPasswordStage.code => 'Enter the code from your email to continue.',
    _ForgotPasswordStage.password =>
      'Use at least six characters for your new password.',
    _ForgotPasswordStage.success => 'Returning you to sign in.',
  };
}
