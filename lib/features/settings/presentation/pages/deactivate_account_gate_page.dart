import 'package:flutter/material.dart';

import '../../../../shared/preferences/session_reset_service.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../auth/presentation/pages/auth_start_page.dart';
import '../../../profile/data/profile_avatar.dart';
import '../../data/account_lifecycle_api.dart';

class DeactivateAccountGatePage extends StatefulWidget {
  final AccountLifecycleApi? api;

  const DeactivateAccountGatePage({super.key, this.api});

  @override
  State<DeactivateAccountGatePage> createState() =>
      _DeactivateAccountGatePageState();
}

class _DeactivateAccountGatePageState extends State<DeactivateAccountGatePage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      _passwordController.text.trim().isNotEmpty &&
      _confirmationController.text.trim() == 'CONFIRM';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _deactivate() async {
    if (!_canSubmit || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final session = await UserSessionController.instance.load();
      final userId = session.userId;
      await (widget.api ?? AccountLifecycleApi.instance).deactivate(
        currentPassword: _passwordController.text,
        confirmation: _confirmationController.text,
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
          content: Text(error.toString().replaceFirst('Exception: ', '')),
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
          title: const Text('Deactivate account'),
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
                    Text(
                      'Take a break without losing your history',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your account will be signed out on every device. You can reactivate it within 40 days by signing in and confirming reactivation.',
                      style: TextStyle(
                        height: 1.5,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
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
                    Text(
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
                        labelText: 'Current password',
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
                    const SizedBox(height: 14),
                    TextField(
                      key: const ValueKey('deactivate-confirmation'),
                      controller: _confirmationController,
                      enabled: !_isSubmitting,
                      onChanged: (_) => setState(() {}),
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Type CONFIRM',
                        helperText: 'Confirmation is case-sensitive.',
                        border: OutlineInputBorder(),
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
                            : const Text('Confirm'),
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
