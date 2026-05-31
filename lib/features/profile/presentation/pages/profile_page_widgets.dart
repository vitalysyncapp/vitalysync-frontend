part of 'profile_page.dart';

class _ProfileHeaderCard extends StatelessWidget {
  final String avatarPath;
  final String username;
  final String email;
  final String? role;
  final int currentStreak;
  final int longestStreak;
  final int? age;
  final String? gender;

  const _ProfileHeaderCard({
    required this.avatarPath,
    required this.username,
    required this.email,
    required this.role,
    required this.currentStreak,
    required this.longestStreak,
    required this.age,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF60A5FA),
              Color(0xFF38BDF8),
              Color.fromARGB(255, 91, 110, 174),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 16,
              right: 18,
              child: IgnorePointer(child: _ProfileLogoWatermark()),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            avatarPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              size: 42,
                              color: Colors.white,
                            ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 210),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 15,
                                  color: Colors.white.withValues(alpha: 0.94),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    role ?? 'Role not set',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                const SizedBox(height: 18),
                Divider(
                  color: Colors.white.withValues(alpha: 0.22),
                  thickness: 1,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 520 ? 4 : 2;
                    const spacing = 10.0;
                    final tileWidth =
                        (constraints.maxWidth - (spacing * (columns - 1))) /
                        columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _ProfileStatTile(
                          width: tileWidth,
                          icon: const _ProfileFireAnimation(size: 27),
                          label: 'Current streak',
                          value: _daysValue(currentStreak),
                        ),
                        _ProfileStatTile(
                          width: tileWidth,
                          icon: const Text(
                            '\u{1F525}',
                            style: TextStyle(fontSize: 23),
                          ),
                          label: 'Best',
                          value: _daysValue(longestStreak),
                        ),
                        _ProfileStatTile(
                          width: tileWidth,
                          icon: const Icon(
                            Icons.cake_outlined,
                            size: 22,
                            color: Colors.white,
                          ),
                          label: 'Age',
                          value: age == null ? '--' : '$age yrs',
                        ),
                        _ProfileStatTile(
                          width: tileWidth,
                          icon: const Icon(
                            Icons.wc_rounded,
                            size: 23,
                            color: Colors.white,
                          ),
                          label: 'Gender',
                          value: gender ?? '--',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daysValue(int value) {
    return value == 1 ? '1 day' : '$value days';
  }
}

class _ProfileLogoWatermark extends StatelessWidget {
  const _ProfileLogoWatermark();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.28,
      child: SizedBox(
        width: 88,
        height: 88,
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _ProfileFireAnimation extends StatelessWidget {
  final double size;

  const _ProfileFireAnimation({required this.size});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      _profileStreakFireAnimationPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      animate: !MediaQuery.disableAnimationsOf(context),
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.local_fire_department_rounded,
          size: size * 0.9,
          color: const Color(0xFFFFC46B),
        );
      },
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final double width;
  final Widget icon;
  final String label;
  final String value;

  const _ProfileStatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 78,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(width: 28, height: 28, child: Center(child: icon)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 25,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalInformationCard extends StatelessWidget {
  final String? gender;
  final String? role;
  final String sleepSchedule;
  final bool isSaving;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenHistory;
  final VoidCallback onEditProfile;

  const _PersonalInformationCard({
    required this.gender,
    required this.role,
    required this.sleepSchedule,
    required this.isSaving,
    required this.onOpenDetails,
    required this.onOpenHistory,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: pagePrimaryTextColor(context),
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: pageBorderColor(context)),
          _ProfileInfoTile(
            icon: Icons.person_outline,
            iconBg: const Color(0xFFE8F0FF),
            iconColor: const Color(0xFF2F6BFF),
            title: 'Profile Details',
            subtitle:
                '${gender ?? 'Gender not set'} - ${role ?? 'Role not set'}',
            onTap: onOpenDetails,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: pageSecondaryTextColor(context),
            ),
          ),
          Divider(height: 1, thickness: 1, color: pageBorderColor(context)),
          _ProfileInfoTile(
            icon: Icons.nightlight_round,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0891B2),
            title: 'Sleep Schedule',
            subtitle: sleepSchedule,
          ),
          Divider(height: 1, thickness: 1, color: pageBorderColor(context)),
          _ProfileInfoTile(
            icon: Icons.history_rounded,
            iconBg: const Color(0xFFEAF7EE),
            iconColor: const Color(0xFF1FB489),
            title: 'History',
            subtitle: 'Daily logs, burnout, nutrition, and activity',
            onTap: onOpenHistory,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: pageSecondaryTextColor(context),
            ),
          ),
          Divider(height: 1, thickness: 1, color: pageBorderColor(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onEditProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: pageBorderColor(context)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyGoalsCard extends StatelessWidget {
  final UserGoalsSnapshot goals;
  final bool isSaving;
  final VoidCallback onEdit;

  const MyGoalsCard({
    super.key,
    required this.goals,
    required this.isSaving,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Goals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Targets shared with Home and Nutrition',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GoalDataRow(
            icon: Icons.flag_outlined,
            label: 'Wellness Goal',
            value: goals.wellnessGoal,
          ),
          _GoalDataRow(
            icon: Icons.bedtime_outlined,
            label: 'Sleep Goal',
            value: goals.sleepLabel,
          ),
          _GoalDataRow(
            icon: Icons.water_drop_outlined,
            label: 'Hydration Goal',
            value: goals.hydrationLabel,
          ),
          _GoalDataRow(
            icon: Icons.fitness_center_outlined,
            label: 'Activity Goal',
            value: goals.activityLabel,
          ),
          _GoalDataRow(
            icon: Icons.directions_walk_rounded,
            label: 'Daily Steps',
            value: goals.dailyStepsLabel,
          ),
          _GoalDataRow(
            icon: Icons.local_dining_outlined,
            label: 'Nutrition Goal',
            value: goals.nutritionLabel,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Edit Goals',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: themePrimary,
                side: BorderSide(color: pageBorderColor(context)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GoalDataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themePrimary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: themePrimary.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: themePrimary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: pagePrimaryTextColor(context),
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

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileInfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      onTap: onTap,
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
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: pagePrimaryTextColor(context),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: pageSecondaryTextColor(context),
          ),
        ),
      ),
      trailing: trailing,
    );
  }
}
