import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool predictiveAnalytics = true;
  bool smartNudges = true;
  bool behavioralLearning = true;

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF0B1F44),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Settings",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F44),
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                _buildSectionCard(
                  title: "App Settings",
                  children: [
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconBg: const Color(0xFFFFF3CD),
                      iconColor: const Color(0xFFD79B00),
                      title: "Notifications",
                      subtitle: "Smart nudges & reminders",
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.phone_android_rounded,
                      iconBg: const Color(0xFFE3E7FF),
                      iconColor: const Color(0xFF5B5FEF),
                      title: "App Preferences",
                      subtitle: "Theme, language, display",
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSectionCard(
                  title: "Privacy & Security",
                  children: [
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      iconBg: const Color(0xFFFFE3E3),
                      iconColor: const Color(0xFFFF2D2D),
                      title: "Privacy Settings",
                      subtitle: "Data control & permissions",
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFF1F3F5),
                      iconColor: const Color(0xFF6B7280),
                      title: "Data Export",
                      subtitle: "Download your data",
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSectionCard(
                  title: "",
                  children: [
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconBg: const Color(0xFFF1F3F5),
                      iconColor: const Color(0xFF4B5563),
                      title: "Help & Support",
                      subtitle: null,
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.article_outlined,
                      iconBg: const Color(0xFFF1F3F5),
                      iconColor: const Color(0xFF4B5563),
                      title: "Terms & Privacy Policy",
                      subtitle: null,
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildDeleteButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (title.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F44),
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1F44),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withOpacity(0.12),
      indent: 18,
      endIndent: 18,
    );
  }

  Widget _buildDeleteButton() { 
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFC9C9),
        ),
        color: Colors.white.withOpacity(0.92),
      ),
      child: TextButton.icon(
        onPressed: () {
          // delete account logic here
        },
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.red,
        ),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            "Delete Account",
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}