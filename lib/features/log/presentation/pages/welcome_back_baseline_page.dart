import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../profile/presentation/pages/retake_baseline_questionnaire_page.dart';

class WelcomeBackBaselinePage extends StatefulWidget {
  const WelcomeBackBaselinePage({
    super.key,
    required this.username,
    required this.onSave,
  });

  final String username;
  final RetakeBaselineSaveCallback onSave;

  @override
  State<WelcomeBackBaselinePage> createState() =>
      _WelcomeBackBaselinePageState();
}

class _WelcomeBackBaselinePageState extends State<WelcomeBackBaselinePage> {
  bool _isOpening = false;

  Future<void> _refreshBaseline() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);

    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RetakeBaselineQuestionnairePage(
          initialAnswers: const <String, int>{},
          onSave: widget.onSave,
          pageTitle: 'Refresh baseline',
          successTitle: 'Baseline refreshed',
          successMessage: 'Thanks. Your baseline is refreshed for today.',
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isOpening = false);
    if (refreshed == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.username.trim().isEmpty ? 'there' : widget.username;
    final primary = pagePrimaryTextColor(context);
    final secondary = pageSecondaryTextColor(context);

    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _isOpening
                ? null
                : () => Navigator.of(context).pop(false),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: pageSurfaceColor(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: pageBorderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2F6BFF), Color(0xFF0891B2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.waving_hand_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Welcome back, $name',
                        key: const ValueKey('baseline-welcome-title'),
                        style: TextStyle(
                          color: primary,
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "It has been a while, so VitalySync needs a fresh burnout baseline before today's check-in. This is only the baseline questions.",
                        style: TextStyle(
                          color: secondary,
                          fontSize: 15.5,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This helps recalibrate your pattern estimate. It does not diagnose a medical condition.',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const ValueKey('refresh-baseline-button'),
                          onPressed: _isOpening ? null : _refreshBaseline,
                          icon: _isOpening
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: Text(
                            _isOpening ? 'Opening...' : 'Refresh baseline',
                          ),
                        ),
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
