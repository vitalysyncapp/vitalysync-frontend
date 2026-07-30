import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../widgets/verification_code_field.dart';

typedef EmailVerificationSender = Future<String> Function();
typedef EmailVerificationCodeVerifier = Future<String> Function(String code);

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    this.sendVerificationEmail,
    this.verifyCode,
    this.resendCooldown = const Duration(seconds: 60),
  });

  final EmailVerificationSender? sendVerificationEmail;
  final EmailVerificationCodeVerifier? verifyCode;
  final Duration resendCooldown;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  UserSessionSnapshot _session = UserSessionSnapshot.empty;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _hasSent = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final session = await UserSessionController.instance.load();
    if (!mounted) return;
    setState(() {
      _session = session;
      _isLoading = false;
    });
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

  Future<void> _sendVerificationEmail() async {
    if (_isSending || _session.emailVerified) return;
    setState(() => _isSending = true);
    try {
      final sender =
          widget.sendVerificationEmail ??
          UserSessionController.instance.resendEmailVerification;
      final message = await sender();
      if (!mounted) return;
      setState(() => _hasSent = true);
      _startCooldown();
      await ValidationDialog.show(
        context,
        title: 'Verification code sent',
        message: message,
        type: ValidationDialogType.success,
        duration: const Duration(milliseconds: 1800),
      );
    } catch (error) {
      if (!mounted) return;
      await _showError('Unable to send code', error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_isVerifying || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isVerifying = true);
    try {
      final verifier =
          widget.verifyCode ?? UserSessionController.instance.verifyEmailCode;
      final message = await verifier(_codeController.text.trim());
      await UserSessionController.instance.updateEmailVerified(true);
      if (!mounted) return;
      await _loadSession();
      if (!mounted) return;
      await ValidationDialog.show(
        context,
        title: 'Email verified',
        message: message,
        type: ValidationDialogType.success,
        duration: const Duration(milliseconds: 1800),
      );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      await _showError('Verification unsuccessful', error);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
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

  @override
  Widget build(BuildContext context) {
    final isVerified = _session.emailVerified;
    final email = _session.email?.trim() ?? '';

    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: pagePrimaryTextColor(context),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _isSending || _isVerifying
                ? null
                : () => Navigator.pop(context),
          ),
          title: Text(
            'Verify email',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              pageBottomContentPadding(context),
            ),
            children: [
              Container(
                key: const ValueKey('email-verification-page-card'),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: pageSurfaceColor(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: pageBorderColor(context)),
                  boxShadow: pageCardShadow(context),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        email: email,
                        isLoading: _isLoading,
                        isVerified: isVerified,
                      ),
                      const SizedBox(height: 18),
                      _GuidanceBox(isVerified: isVerified, hasSent: _hasSent),
                      if (!isVerified && !_isLoading && email.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        VerificationCodeField(
                          controller: _codeController,
                          enabled: !_isSending && !_isVerifying,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            key: const ValueKey('verify-email-code-button'),
                            onPressed: _isVerifying ? null : _verifyCode,
                            icon: _isVerifying
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.verified_outlined),
                            label: Text(
                              _isVerifying ? 'Verifying...' : 'Verify code',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            key: const ValueKey(
                              'send-email-verification-button',
                            ),
                            onPressed: _isSending || _cooldownSeconds > 0
                                ? null
                                : _sendVerificationEmail,
                            icon: _isSending
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined, size: 18),
                            label: Text(
                              _cooldownSeconds > 0
                                  ? 'Send again in ${_cooldownSeconds}s'
                                  : _hasSent
                                  ? 'Send a new code'
                                  : 'Send verification code',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.email,
    required this.isLoading,
    required this.isVerified,
  });

  final String email;
  final bool isLoading;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final accent = isVerified
        ? const Color(0xFF1EAD83)
        : Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isVerified
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
            color: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isVerified ? 'Email verified' : 'Verify your email',
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isLoading ? 'Checking your account' : email,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pageSecondaryTextColor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuidanceBox extends StatelessWidget {
  const _GuidanceBox({required this.isVerified, required this.hasSent});

  final bool isVerified;
  final bool hasSent;

  @override
  Widget build(BuildContext context) {
    final color = isVerified || hasSent
        ? const Color(0xFF1EAD83)
        : const Color(0xFF2563EB);
    final text = isVerified
        ? 'Your email is confirmed for this account.'
        : hasSent
        ? 'Enter the six-digit code we sent. It expires in 10 minutes.'
        : 'Enter a code you already received, or send a new six-digit code.';

    return Container(
      key: ValueKey(
        hasSent
            ? 'email-verification-sent-guidance'
            : 'email-verification-guidance',
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isVerified ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.42,
                color: pageSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
