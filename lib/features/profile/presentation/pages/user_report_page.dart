import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/readable_page_body.dart';
import '../../data/report_service.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class UserReportPage extends StatefulWidget {
  final int userId;

  const UserReportPage({super.key, required this.userId});

  @override
  State<UserReportPage> createState() => _UserReportPageState();
}

class _UserReportPageState extends State<UserReportPage> {
  bool _isExportingReport = false;

  Future<void> _exportReport() async {
    setState(() => _isExportingReport = true);
    try {
      await ReportService().exportAndOpenUserReport(widget.userId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText(
            'Your report could not be prepared right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingReport = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: pagePrimaryTextColor(context),
          title: LocalizedText(
            'Wellness report',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ReadablePageBody(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Illustration
                Center(
                      child: SvgPicture.asset(
                        'assets/images/user_report_illustration.svg',
                        height: 220,
                      ),
                    )
                    .animate()
                    .fade(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 16),

                // Title & Subtitle
                LocalizedText(
                      'Your wellness report',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: pagePrimaryTextColor(context),
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fade(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOut),

                const SizedBox(height: 8),

                LocalizedText(
                      'Create a Word document with your daily check-ins, activity, nutrition, and wellness patterns in one clear summary.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                    .animate()
                    .fade(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOut),

                const SizedBox(height: 16),

                // Disclaimer Card
                Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LocalizedText(
                                  'For your information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: pagePrimaryTextColor(context),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LocalizedText(
                                  'This report is for personal use and informational purposes only. It is not intended for medical diagnosis or treatment.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: pageSecondaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fade(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOut),

                const SizedBox(height: 48),

                // Export Button
                Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? const Color(0xFF2C3E50)
                                        : const Color(0xFFFDE68A))
                                    .withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: _isExportingReport ? null : _exportReport,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF2C3E50)
                              : const Color(0xFFFDE68A),
                          foregroundColor: isDark
                              ? Colors.white
                              : const Color(0xFF451A03),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isExportingReport
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  key: ValueKey('loading'),
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    LocalizedText(
                                      'Preparing report…',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  key: ValueKey('button'),
                                  children: [
                                    Icon(Icons.download_rounded, size: 24),
                                    SizedBox(width: 12),
                                    LocalizedText(
                                      'Export Word report',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    )
                    .animate()
                    .fade(delay: 500.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
