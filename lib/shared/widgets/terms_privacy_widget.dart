import 'package:flutter/material.dart';

import '../theme/app_page_style.dart';

class TermsPrivacyWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const TermsPrivacyWidget({
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 20),
            _introCard(context),
            const SizedBox(height: 16),
            _policyCard(
              context: context,
              title: 'Terms and Conditions',
              icon: Icons.gavel_rounded,
              color: const Color(0xFF2F66F3),
              children: _termsContent(context),
            ),
            const SizedBox(height: 16),
            _policyCard(
              context: context,
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_rounded,
              color: const Color(0xFF14B8A6),
              children: _privacyContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Color(0xFF2F66F3),
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Terms & Privacy Policy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _introCard(BuildContext context) {
    return _card(
      context: context,
      child: Text(
        'This section contains the Terms and Conditions and Privacy Policy of VitalySync.',
        style: TextStyle(
          fontSize: 14.5,
          height: 1.6,
          color: pageSecondaryTextColor(context),
        ),
      ),
    );
  }

  Widget _policyCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return _card(
      context: context,
      borderColor: color.withValues(alpha: 0.15),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: pagePrimaryTextColor(context),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  List<Widget> _termsContent(BuildContext context) {
    return [
      _section(
        context,
        '1. Acceptance of Terms',
        'By accessing or using VitalySync, you agree to be bound by these Terms and Conditions. If you do not agree, you must refrain from using the application.',
      ),
      _section(
        context,
        '2. Description of Service',
        'VitalySync is a health and wellness application that allows users to:',
        bullets: const [
          'Log daily activities and wellness data',
          'Track nutrition and habits',
          'View analytics and insights',
        ],
        footer:
            'The app is intended for informational purposes only and does not replace medical advice.',
      ),
      _section(
        context,
        '3. User Responsibilities',
        'Users agree to:',
        bullets: const [
          'Provide accurate and complete information',
          'Use the application lawfully',
          'Avoid unauthorized access or misuse',
        ],
        footer:
            'Users are responsible for maintaining account confidentiality.',
      ),
      _section(
        context,
        '4. Health Disclaimer',
        'VitalySync does not provide medical diagnosis or treatment. Consult a healthcare professional for medical concerns.',
      ),
      _section(
        context,
        '5. Intellectual Property',
        'All content and features are owned by the developers and protected by law.',
      ),
      _section(
        context,
        '6. Limitation of Liability',
        'VitalySync is not liable for:',
        bullets: const [
          'Inaccuracies in data',
          'Damages from app use',
          'Data loss due to technical issues',
        ],
      ),
      _section(
        context,
        '7. Termination',
        'We may suspend or terminate access if terms are violated.',
      ),
      _section(
        context,
        '8. Changes to Terms',
        'We may update these Terms. Continued use means acceptance.',
      ),
      _section(
        context,
        '9. Governing Law',
        'These Terms are governed by the laws of the Republic of the Philippines.',
      ),
    ];
  }

  List<Widget> _privacyContent(BuildContext context) {
    return [
      _section(
        context,
        '1. Introduction',
        'VitalySync protects your data in accordance with the Data Privacy Act of 2012.',
      ),
      _section(
        context,
        '2. Information We Collect',
        'Personal data may include:',
        bullets: const [
          'Name, email, profile details',
          'Health-related data',
          'Device and usage data',
        ],
      ),
      _section(
        context,
        '3. Purpose of Data Collection',
        'Data is used to:',
        bullets: const [
          'Provide app functionality',
          'Generate insights',
          'Ensure account security',
        ],
      ),
      _section(
        context,
        '4. Legal Basis',
        'Processing is based on consent, legitimate interest, and legal obligations.',
      ),
      _section(
        context,
        '5. Data Security',
        'We implement safeguards to protect your data.',
      ),
      _section(
        context,
        '6. Data Sharing',
        'We do not sell data. Sharing occurs only when necessary or legally required.',
      ),
      _section(
        context,
        '7. User Rights',
        'You may access, correct, delete data, or file complaints.',
      ),
      _section(
        context,
        '8. Data Retention',
        'Data is kept only as long as necessary.',
      ),
      _section(context, '9. Cookies', 'Used to improve experience.'),
      _section(
        context,
        '10. Policy Updates',
        'Users will be notified of major changes.',
      ),
      _section(
        context,
        '11. Consent',
        'By using the app, you consent to data processing under the Data Privacy Act.',
      ),
      _section(
        context,
        '12. Data Breach Notification',
        'Users will be notified if a breach occurs and actions will be taken.',
      ),
      _section(
        context,
        '13. Contact',
        'vitalysyncapp@gmail.com',
        footer: 'For concerns about your privacy, please contact us by email.',
      ),
    ];
  }

  Widget _section(
    BuildContext context,
    String title,
    String content, {
    List<String>? bullets,
    String? footer,
  }) {
    final bodyColor = pageSecondaryTextColor(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.8,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(fontSize: 14, height: 1.5, color: bodyColor),
          ),
          if (bullets != null)
            ...bullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\u2022 ', style: TextStyle(color: bodyColor)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(color: bodyColor, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(footer, style: TextStyle(color: bodyColor, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required BuildContext context,
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.16
                  : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
