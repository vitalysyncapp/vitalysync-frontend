import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class PersonalInformationPage extends StatelessWidget {
  final String username;
  final String email;
  final int? age;
  final String? gender;
  final String? role;
  final String lifestyleType;
  final String wellnessGoal;
  final String usualSleepTime;
  final String usualWakeTime;
  final String workIntensity;
  final String waterGoal;
  final String exerciseTarget;
  final String burnoutLevel;
  final int burnoutScore;
  final bool isDemoMode;

  const PersonalInformationPage({
    super.key,
    required this.username,
    required this.email,
    required this.age,
    required this.gender,
    required this.role,
    required this.lifestyleType,
    required this.wellnessGoal,
    required this.usualSleepTime,
    required this.usualWakeTime,
    required this.workIntensity,
    required this.waterGoal,
    required this.exerciseTarget,
    required this.burnoutLevel,
    required this.burnoutScore,
    required this.isDemoMode,
  });

  String _value(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not set' : text;
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
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: pagePrimaryTextColor(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Personal Info',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            pageBottomContentPadding(context),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2F6BFF),
                      Color(0xFF3B82F6),
                      Color(0xFF0891B2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoGroupCard(
                emoji: '👤',
                icon: Icons.person_outline,
                title: 'Profile Details',
                children: [
                  _InfoRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    value: _value(username),
                  ),
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: _value(email),
                  ),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: age?.toString() ?? 'Not set',
                  ),
                  _InfoRow(
                    icon: Icons.wc_rounded,
                    label: 'Gender',
                    value: _value(gender),
                  ),
                  _InfoRow(
                    icon: Icons.work_outline_rounded,
                    label: 'Current Role',
                    value: _value(role),
                  ),
                  _InfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Session',
                    value: isDemoMode ? 'Demo mode' : 'Signed in',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoGroupCard(
                emoji: '🌿',
                icon: Icons.spa_outlined,
                title: 'Onboarding Profile',
                children: [
                  _InfoRow(
                    icon: Icons.directions_walk_rounded,
                    label: 'Lifestyle Type',
                    value: _value(lifestyleType),
                  ),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Wellness Goal',
                    value: _value(wellnessGoal),
                  ),
                  _InfoRow(
                    icon: Icons.bedtime_outlined,
                    label: 'Usual Sleep',
                    value: _value(usualSleepTime),
                  ),
                  _InfoRow(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Usual Wake',
                    value: _value(usualWakeTime),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoGroupCard(
                emoji: '⚡',
                icon: Icons.monitor_heart_outlined,
                title: 'Health Baseline',
                children: [
                  _InfoRow(
                    icon: Icons.speed_outlined,
                    label: 'Work Intensity',
                    value: _value(workIntensity),
                  ),
                  _InfoRow(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Initial Burnout',
                    value: '${_value(burnoutLevel)} ($burnoutScore%)',
                  ),
                  _InfoRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Daily Water Goal',
                    value: _value(waterGoal),
                  ),
                  _InfoRow(
                    icon: Icons.fitness_center_outlined,
                    label: 'Exercise Target',
                    value: _value(exerciseTarget),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoGroupCard extends StatelessWidget {
  final String emoji;
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _InfoGroupCard({
    required this.emoji,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    Positioned(
                      right: 3,
                      bottom: 1,
                      child: Text(emoji, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: pageSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.5,
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
