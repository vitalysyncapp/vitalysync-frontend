import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../settings/data/account_lifecycle_api.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../authenticated_session_coordinator.dart';

class ReactivateAccountPage extends StatefulWidget {
  final AccountReactivationChallenge challenge;
  final AccountLifecycleApi? api;

  const ReactivateAccountPage({super.key, required this.challenge, this.api});

  @override
  State<ReactivateAccountPage> createState() => _ReactivateAccountPageState();
}

class _ReactivateAccountPageState extends State<ReactivateAccountPage> {
  bool _isSubmitting = false;

  String _date(DateTime value) {
    return DateFormat.yMMMMd().format(value.toLocal());
  }

  Future<void> _reactivate() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final data = await (widget.api ?? AccountLifecycleApi.instance)
          .reactivate(widget.challenge);
      if (!mounted) return;
      await completeAuthenticatedSession(context, data);
    } on FormatException {
      if (!mounted) return;
      await ValidationDialog.show(
        context,
        message:
            'The reactivated session response was incomplete. Sign in again.',
        type: ValidationDialogType.error,
      );
    } catch (error) {
      if (!mounted) return;
      await ValidationDialog.show(
        context,
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: pagePrimaryTextColor(context),
          title: const Text('Reactivate account'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: pageSurfaceColor(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: pageBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.restore_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Restore your VitalySync account?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your account can be reactivated until ${_date(widget.challenge.reactivationDeadline)}. Your retained data is scheduled for permanent deletion on ${_date(widget.challenge.retentionExpiresAt)} if the account remains deactivated.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.5,
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        key: const ValueKey('reactivate-account-button'),
                        onPressed: _isSubmitting ? null : _reactivate,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Reactivate and continue'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const ValueKey('cancel-reactivation-button'),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
