import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

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
            'Help & Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroCard(context),
                const SizedBox(height: 16),
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
                  title: 'Contact Number',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help?',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can contact the VitalySync team through the channels below. These are placeholder support accounts for now.',
            style: TextStyle(
              height: 1.5,
              color: pageSecondaryTextColor(context),
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.04,
            ),
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
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
