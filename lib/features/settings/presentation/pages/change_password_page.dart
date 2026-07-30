import 'package:flutter/material.dart';

import '../../../../shared/preferences/session_reset_service.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/new_password_fields.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../../../auth/presentation/pages/auth_start_page.dart';

typedef PasswordChanger =
    Future<String> Function(
      String currentPassword,
      String newPassword,
      String confirmPassword,
    );

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({
    super.key,
    required this.verifiedPassword,
    this.changePassword,
    this.resetSession,
  });

  final String verifiedPassword;
  final PasswordChanger? changePassword;
  final Future<void> Function()? resetSession;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final changer =
          widget.changePassword ??
          (currentPassword, newPassword, confirmation) =>
              UserSessionController.instance.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmation,
              );
      final message = await changer(
        widget.verifiedPassword,
        _passwordController.text.trim(),
        _confirmPasswordController.text.trim(),
      );
      if (!mounted) return;

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
      await ValidationDialog.show(
        context,
        title: 'Unable to change password',
        message: error.toString().replaceFirst('Exception: ', ''),
        type: ValidationDialogType.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        key: const ValueKey('change-password-page'),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: pagePrimaryTextColor(context),
          leading: IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text(
            'Change password',
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
                padding: const EdgeInsets.all(20),
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
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose a new account password',
                              style: TextStyle(
                                color: pagePrimaryTextColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'For your security, changing your password signs out every device, including this one.',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      NewPasswordFields(
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const ValueKey('submit-change-password-button'),
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _isSubmitting ? 'Changing...' : 'Change password',
                          ),
                        ),
                      ),
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
