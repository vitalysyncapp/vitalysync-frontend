import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/wellness_profile_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "User Name";
  String email = "user@email.com";
  String? gender;
  String? userType;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      username = prefs.getString('username') ??
          prefs.getString('name') ??
          "User Name";
      email = prefs.getString('email') ?? "user@email.com";
      gender = prefs.getString('gender');
      userType = prefs.getString('user_type');
    });
  }

  String getAvatarImage(String? gender, String? userType) {
    if (gender == null || userType == null) return "assets/images/user.png";

    if (gender.toLowerCase() == 'male') {
      if (userType == 'Student') return "assets/images/male Student.png";
      return "assets/images/business-man.png";
    } else if (gender.toLowerCase() == 'female') {
      if (userType == 'Student') return "assets/images/female Student.png";
      return "assets/images/businesswoman.png";
    } else {
      return "assets/images/user.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarPath = getAvatarImage(gender, userType);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5F8FF),
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
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1D3557),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Profile",
            style: TextStyle(
              color: Color(0xFF1D3557),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(avatarPath),
              const SizedBox(height: 18),
              _buildInfoCard(),
              const SizedBox(height: 18),
              WellnessProfileCard(
                lifestyleType: "Sedentary",
                occupationalStatus: "Student",
                workIntensity: "High",
                waterGoal: "2.5 L",
                exerciseTarget: "5 days/week",
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String avatarPath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A7DFF),
            Color(0xFF6C63FF),
            Color(0xFF8E2BFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      avatarPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 42,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFF4CFF8F),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Healthy",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Divider(
            color: Colors.white.withOpacity(0.22),
            thickness: 1,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _StatItem(value: "87", label: "Days Active"),
              _StatItem(value: "42", label: "Risk Score"),
              _StatItem(value: "78%", label: "Consistency"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7ECF5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8AA4D6).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF102A56),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F3F8)),
          _infoTile(
            icon: Icons.person_outline,
            iconBg: const Color(0xFFE8F0FF),
            iconColor: const Color(0xFF2F6BFF),
            title: "Profile Details",
            subtitle: "Age, lifestyle type, health info",
            onTap: () {},
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F3F8)),
          _infoTile(
            icon: Icons.nightlight_round,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF8A35FF),
            title: "Sleep Schedule",
            subtitle: "10:30 PM - 6:30 AM",
            onTap: () {},
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F3F8)),
          _infoTile(
            icon: Icons.lock_outline,
            iconBg: const Color(0xFFE8FFF0),
            iconColor: const Color(0xFF12B76A),
            title: "Email and Password",
            subtitle: "Manage login credentials and security",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF102A56),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9AA4B2),
        size: 28,
      ),
      onTap: onTap,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.white.withOpacity(0.88),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
