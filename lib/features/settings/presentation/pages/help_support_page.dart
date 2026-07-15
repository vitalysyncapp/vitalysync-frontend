import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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
            'Help and support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              pageBottomContentPadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(context),
                const SizedBox(height: 16),
                _buildSectionLabel(context, 'Support channels'),
                const SizedBox(height: 10),
                _buildContactCard(
                  context: context,
                  icon: Icons.facebook_rounded,
                  iconColor: const Color(0xFF1877F2),
                  title: 'Facebook',
                  subtitle: 'Message us on our Facebook page',
                  value: 'facebook.com/VitalySyncOfficial',
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  context: context,
                  icon: Icons.music_note_rounded,
                  iconColor: const Color(0xFF111111),
                  title: 'TikTok',
                  subtitle: 'Follow updates and short wellness tips',
                  value: '@vitalysync.app',
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  context: context,
                  icon: Icons.phone_in_talk_rounded,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Contact number',
                  subtitle: 'Support hotline',
                  value: '+63 917 123 4567',
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  context: context,
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Email',
                  subtitle: 'Reach out for account or app concerns',
                  value: 'support@vitalysyncapp.com',
                ),
                const SizedBox(height: 16),
                _buildCareNote(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF173246), Color(0xFF16362F)]
              : const [Color(0xFFEAF7FF), Color(0xFFEAFBF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: pageBorderColor(context)),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Need help?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reach the VitalySync team through the channels below for account, app, or project concerns.',
            style: TextStyle(
              height: 1.5,
              color: pageSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: pagePrimaryTextColor(context),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = isDark && iconColor.computeLuminance() < 0.18
        ? Colors.white.withValues(alpha: 0.92)
        : iconColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iconColor.withValues(alpha: isDark ? 0.18 : 0.08),
              ),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareNote(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'For urgent health, safety, or mental health emergencies, contact local emergency services or a qualified professional.',
              style: TextStyle(
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: pageSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
