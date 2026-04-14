import 'package:flutter/material.dart';

class TermsPrivacyWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const TermsPrivacyWidget({
    Key? key,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF4F8FF),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 20),

            _introCard(),
            const SizedBox(height: 16),

            _policyCard(
              title: "Terms and Conditions",
              icon: Icons.gavel_rounded,
              color: const Color(0xFF2F66F3),
              children: _termsContent(),
            ),

            const SizedBox(height: 16),

            _policyCard(
              title: "Privacy Policy",
              icon: Icons.privacy_tip_rounded,
              color: const Color(0xFF14B8A6),
              children: _privacyContent(),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.shield_rounded,
              color: Color(0xFF2F66F3), size: 26),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "Terms & Privacy Policy",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102A43),
            ),
          ),
        ),
      ],
    );
  }

  // INTRO
  Widget _introCard() {
    return _card(
      child: const Text(
        "This section contains the Terms and Conditions and Privacy Policy of VitalySync.",
        style: TextStyle(
          fontSize: 14.5,
          height: 1.6,
          color: Color(0xFF334E68),
        ),
      ),
    );
  }

  // POLICY CARD
  Widget _policyCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return _card(
      borderColor: color.withOpacity(0.15),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF102A43),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  // TERMS CONTENT
  List<Widget> _termsContent() {
    return [
      _section("1. Acceptance of Terms",
          "By accessing or using VitalySync, you agree to be bound by these Terms and Conditions. If you do not agree, you must refrain from using the application."),
      _section("2. Description of Service",
          "VitalySync is a health and wellness application that allows users to:",
          bullets: [
            "Log daily activities and wellness data",
            "Track nutrition and habits",
            "View analytics and insights",
          ],
          footer:
              "The app is intended for informational purposes only and does not replace medical advice."),
      _section("3. User Responsibilities",
          "Users agree to:",
          bullets: [
            "Provide accurate and complete information",
            "Use the application lawfully",
            "Avoid unauthorized access or misuse",
          ],
          footer:
              "Users are responsible for maintaining account confidentiality."),
      _section("4. Health Disclaimer",
          "VitalySync does not provide medical diagnosis or treatment. Consult a healthcare professional for medical concerns."),
      _section("5. Intellectual Property",
          "All content and features are owned by the developers and protected by law."),
      _section("6. Limitation of Liability",
          "VitalySync is not liable for:",
          bullets: [
            "Inaccuracies in data",
            "Damages from app use",
            "Data loss due to technical issues",
          ]),
      _section("7. Termination",
          "We may suspend or terminate access if terms are violated."),
      _section("8. Changes to Terms",
          "We may update these Terms. Continued use means acceptance."),
      _section("9. Governing Law",
          "These Terms are governed by the laws of the Republic of the Philippines."),
    ];
  }

  // PRIVACY CONTENT
  List<Widget> _privacyContent() {
    return [
      _section("1. Introduction",
          "VitalySync protects your data in accordance with the Data Privacy Act of 2012."),
      _section("2. Information We Collect",
          "Personal data may include:",
          bullets: [
            "Name, email, profile details",
            "Health-related data",
            "Device and usage data",
          ]),
      _section("3. Purpose of Data Collection",
          "Data is used to:",
          bullets: [
            "Provide app functionality",
            "Generate insights",
            "Ensure account security",
          ]),
      _section("4. Legal Basis",
          "Processing is based on consent, legitimate interest, and legal obligations."),
      _section("5. Data Security",
          "We implement safeguards to protect your data."),
      _section("6. Data Sharing",
          "We do not sell data. Sharing occurs only when necessary or legally required."),
      _section("7. User Rights",
          "You may access, correct, delete data, or file complaints."),
      _section("8. Data Retention",
          "Data is kept only as long as necessary."),
      _section("9. Cookies",
          "Used to improve experience."),
      _section("10. Policy Updates",
          "Users will be notified of major changes."),
      _section("11. Consent",
          "By using the app, you consent to data processing under the Data Privacy Act."),
      _section("12. Data Breach Notification",
          "Users will be notified if a breach occurs and actions will be taken."),
      _section("13. Contact",
          "📧 vitalysyncapp@gmail.com"),
    ];
  }

  // SECTION BUILDER
  Widget _section(String title, String content,
      {List<String>? bullets, String? footer}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14.8)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(fontSize: 14, height: 1.5)),
          if (bullets != null)
            ...bullets.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Text("• "),
                      Expanded(child: Text(e)),
                    ],
                  ),
                )),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(footer),
          ]
        ],
      ),
    );
  }

  // BASE CARD
  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}