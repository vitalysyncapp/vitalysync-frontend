import 'package:flutter/material.dart';

import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';

typedef EmailVerificationSender = Future<String> Function();

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, this.sendVerificationEmail});

  final EmailVerificationSender? sendVerificationEmail;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  UserSessionSnapshot _session = UserSessionSnapshot.empty;
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasSent = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await UserSessionController.instance.load();
    if (!mounted) return;

    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSending || _session.emailVerified) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final sender =
          widget.sendVerificationEmail ??
          UserSessionController.instance.resendEmailVerification;
      await sender();
      if (!mounted) return;

      setState(() => _hasSent = true);

      await ValidationDialog.show(
        context,
        title: 'Email has been sent',
        message: _sentMessage(_session.email),
        type: ValidationDialogType.success,
        duration: const Duration(milliseconds: 3200),
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

  String _sentMessage(String? email) {
    final normalizedEmail = email?.trim();
    final destination = normalizedEmail == null || normalizedEmail.isEmpty
        ? 'your email address'
        : normalizedEmail;

    return 'We sent a verification link to $destination. Open the email, tap the link, then return to VitalySync.';
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
            onPressed: _isSending ? null : () => Navigator.pop(context),
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
              _VerificationCard(
                email: email,
                isLoading: _isLoading,
                isVerified: isVerified,
                isSending: _isSending,
                hasSent: _hasSent,
                onSend: _sendVerificationEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.email,
    required this.isLoading,
    required this.isVerified,
    required this.isSending,
    required this.hasSent,
    required this.onSend,
  });

  final String email;
  final bool isLoading;
  final bool isVerified;
  final bool isSending;
  final bool hasSent;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final accent = isVerified
        ? const Color(0xFF1EAD83)
        : Theme.of(context).colorScheme.primary;

    return Container(
      key: const ValueKey('email-verification-page-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      isLoading
                          ? 'Checking your account'
                          : email.isEmpty
                          ? 'No email is saved for this account'
                          : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: pageSecondaryTextColor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _GuidanceBox(isVerified: isVerified, hasSent: hasSent),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('send-email-verification-button'),
              onPressed: isLoading || isVerified || email.isEmpty || isSending
                  ? null
                  : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                isSending
                    ? 'Sending...'
                    : hasSent
                    ? 'Send again'
                    : 'Send verification email',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
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
        ? 'Email sent. Open your inbox, tap the verification link, then return to VitalySync.\nMake sure to check your spam folder if you don\'t see it.'
        : 'Send a verification email, then open your inbox and tap the confirmation link. \nMake sure to check your spam folder if you don\'t see it.';

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
