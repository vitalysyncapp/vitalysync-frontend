import 'package:flutter/material.dart';

import '../../../../shared/preferences/session_reset_service.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../auth/presentation/pages/auth_start_page.dart';
import '../../../profile/data/profile_avatar.dart';
import '../../data/account_lifecycle_api.dart';
import '../widgets/typed_confirmation_dialog.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class DeactivateAccountGatePage extends StatefulWidget {
  final AccountLifecycleApi? api;

  const DeactivateAccountGatePage({super.key, this.api});

  @override
  State<DeactivateAccountGatePage> createState() =>
      _DeactivateAccountGatePageState();
}

class _DeactivateAccountGatePageState extends State<DeactivateAccountGatePage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  bool get _canSubmit => _passwordController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deactivate() async {
    if (!_canSubmit || _isSubmitting) {
      return;
    }

    final confirmed = await showTypedConfirmationDialog(
      context: context,
      title: 'Deactivate account',
      message:
          'Your account will be signed out on every device. You can reactivate it within 40 days by signing in and confirming reactivation.',
      actionLabel: 'Deactivate account',
      confirmationFieldKey: const ValueKey('deactivate-confirmation'),
      actionButtonKey: const ValueKey('deactivate-dialog-confirm-button'),
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final session = await UserSessionController.instance.load();
      final userId = session.userId;
      await (widget.api ?? AccountLifecycleApi.instance).deactivate(
        currentPassword: _passwordController.text,
        confirmation: 'CONFIRM',
      );

      if (userId != null) {
        try {
          await ProfileAvatarController.instance.clearForUser(userId);
        } catch (error, stackTrace) {
          debugPrint('Unable to clear the local profile avatar: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      await SessionResetService.instance.resetForLogout();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthStartPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: pagePrimaryTextColor(context),
          title: const LocalizedText('Deactivate account'),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              pageBottomContentPadding(context),
            ),
            children: [
              _GateCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'Take a break without losing your history',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LocalizedText(
                      'Your account will be signed out on every device. You can reactivate it within 40 days by signing in and confirming reactivation.',
                      style: TextStyle(
                        height: 1.5,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LocalizedText(
                      'After 40 days, access stays blocked. Retained account data is permanently deleted five years after deactivation.',
                      style: TextStyle(
                        height: 1.5,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GateCard(
                borderColor: const Color(0xFFFFC9C9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'Confirm deactivation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const ValueKey('deactivate-current-password'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isSubmitting,
                      onChanged: (_) => setState(() {}),
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Current password'.localizedCopy(context),
                        suffixIcon: IconButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const ValueKey('deactivate-confirm-button'),
                        onPressed: _isSubmitting || !_canSubmit
                            ? null
                            : _deactivate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD14343),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const LocalizedText('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _GateCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? pageBorderColor(context)),
      ),
      child: child,
    );
  }
}
