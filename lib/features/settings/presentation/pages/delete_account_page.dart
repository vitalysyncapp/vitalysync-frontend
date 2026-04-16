import 'package:flutter/material.dart';

import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../log/data/log_api.dart';

class DeleteAccountPage extends StatefulWidget {
  final String verifiedPassword;

  const DeleteAccountPage({
    super.key,
    required this.verifiedPassword,
  });

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _confirmationController = TextEditingController();
  bool _isDeleting = false;

  bool get _canDelete => _confirmationController.text.trim() == 'DELETE';

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type DELETE to confirm account removal.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account permanently?'),
          content: const Text(
            'This will permanently remove your VitalySync account and related synced data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await UserSessionController.instance.deleteAccount(
        password: widget.verifiedPassword,
      );
      await AppPreferencesController.instance.resetToDefaults();
      await LogApi.clearLocalDemoData();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Delete Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
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
              _SectionCard(
                title: 'Before You Continue',
                children: const [
                  _InfoBlock(
                    text:
                        'Deleting your account permanently removes your VitalySync account and related synced records.',
                  ),
                  _InfoBlock(
                    text:
                        'This includes profile-linked data such as onboarding details, preferences, logs, streaks, and stored environment snapshots.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFC9C9)),
                  color: pageSurfaceColor(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final Confirmation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type DELETE below to unlock permanent account removal.',
                        style: TextStyle(
                          height: 1.45,
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmationController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type DELETE',
                          filled: true,
                          fillColor: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: pageBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: pageBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isDeleting || !_canDelete ? null : _deleteAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD14343),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isDeleting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Delete My Account'),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String text;

  const _InfoBlock({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Text(
        text,
        style: TextStyle(
          height: 1.45,
          color: pageSecondaryTextColor(context),
        ),
      ),
    );
  }
}
