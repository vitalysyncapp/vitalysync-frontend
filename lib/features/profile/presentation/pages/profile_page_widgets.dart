part of 'profile_page.dart';

class _ProfileHeaderPalette {
  const _ProfileHeaderPalette({
    required this.gradientColors,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.border,
    required this.divider,
    required this.glassSurface,
    required this.glassBorder,
    required this.avatarRingColors,
    required this.editButton,
    required this.primaryOrb,
    required this.secondaryOrb,
    required this.watermarkOpacity,
  });

  factory _ProfileHeaderPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return _ProfileHeaderPalette(
        gradientColors: const [
          Color(0xFF152738),
          Color(0xFF17363F),
          Color(0xFF1D3047),
        ],
        primaryText: const Color(0xFFF7FAFC),
        secondaryText: const Color(0xFFC5D3DD),
        accent: const Color(0xFF65D7BD),
        border: Colors.white.withValues(alpha: 0.09),
        divider: Colors.white.withValues(alpha: 0.1),
        glassSurface: Colors.white.withValues(alpha: 0.065),
        glassBorder: Colors.white.withValues(alpha: 0.1),
        avatarRingColors: const [
          Color(0xFF68D5B8),
          Color(0xFF76ACE8),
          Color(0xFFB18ADD),
        ],
        editButton: const Color(0xFF27A98F),
        primaryOrb: const Color(0xFF5BDEC1).withValues(alpha: 0.08),
        secondaryOrb: const Color(0xFF76ACE8).withValues(alpha: 0.08),
        watermarkOpacity: 0.08,
      );
    }

    return _ProfileHeaderPalette(
      gradientColors: const [
        Color(0xFFF9FFFC),
        Color(0xFFECF8F5),
        Color(0xFFEEF6FF),
      ],
      primaryText: const Color(0xFF15384A),
      secondaryText: const Color(0xFF5B7485),
      accent: const Color(0xFF168F83),
      border: const Color(0xFFD8ECE7),
      divider: const Color(0xFFC9E1DE).withValues(alpha: 0.72),
      glassSurface: Colors.white.withValues(alpha: 0.7),
      glassBorder: Colors.white.withValues(alpha: 0.94),
      avatarRingColors: const [
        Color(0xFF68D5B8),
        Color(0xFF76ACE8),
        Color(0xFFB18ADD),
      ],
      editButton: const Color(0xFF178E8A),
      primaryOrb: const Color(0xFF9BE5D3).withValues(alpha: 0.2),
      secondaryOrb: const Color(0xFFAECFF4).withValues(alpha: 0.2),
      watermarkOpacity: 0.09,
    );
  }

  final List<Color> gradientColors;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color border;
  final Color divider;
  final Color glassSurface;
  final Color glassBorder;
  final List<Color> avatarRingColors;
  final Color editButton;
  final Color primaryOrb;
  final Color secondaryOrb;
  final double watermarkOpacity;
}

class _ProfileHeaderCard extends StatelessWidget {
  final int? userId;
  final String username;
  final String email;
  final String? role;
  final int currentStreak;
  final int longestStreak;
  final int? age;
  final String? gender;
  final VoidCallback onEditAvatar;

  const _ProfileHeaderCard({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.currentStreak,
    required this.longestStreak,
    required this.age,
    required this.gender,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfileHeaderPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('profile-header-card'),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF164E63,
            ).withValues(alpha: isDark ? 0.22 : 0.09),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -76,
            right: -54,
            child: IgnorePointer(
              child: _ProfileSoftOrb(size: 196, color: palette.secondaryOrb),
            ),
          ),
          Positioned(
            bottom: -92,
            left: -48,
            child: IgnorePointer(
              child: _ProfileSoftOrb(size: 184, color: palette.primaryOrb),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IgnorePointer(
              child: _ProfileLogoWatermark(
                opacity: palette.watermarkOpacity,
                size: 76,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final useStackedIdentity = constraints.maxWidth < 304;
              final horizontalPadding = useStackedIdentity ? 18.0 : 22.0;
              final avatar = _ProfileAvatarButton(
                userId: userId,
                gender: gender,
                role: role,
                palette: palette,
                onEditAvatar: onEditAvatar,
              );
              final identity = _ProfileIdentity(
                username: username,
                email: email,
                role: role,
                centered: useStackedIdentity,
                palette: palette,
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  22,
                ),
                child: Column(
                  children: [
                    if (useStackedIdentity)
                      Column(
                        children: [
                          avatar,
                          const SizedBox(height: 15),
                          identity,
                        ],
                      )
                    else
                      Row(
                        children: [
                          avatar,
                          const SizedBox(width: 18),
                          Expanded(child: identity),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Divider(color: palette.divider, height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, statConstraints) {
                        final columns = statConstraints.maxWidth >= 620 ? 4 : 2;
                        const spacing = 11.0;
                        final tileWidth =
                            (statConstraints.maxWidth -
                                (spacing * (columns - 1))) /
                            columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            _ProfileStatTile(
                              width: tileWidth,
                              accent: const Color(0xFFF08A35),
                              icon: const _ProfileFireAnimation(size: 24),
                              label: 'Current streak',
                              value: _daysValue(currentStreak),
                            ),
                            _ProfileStatTile(
                              width: tileWidth,
                              accent: const Color(0xFFF3A51F),
                              icon: const Icon(
                                Icons.emoji_events_rounded,
                                size: 20,
                                color: Color(0xFFE99A16),
                              ),
                              label: 'Best',
                              value: _daysValue(longestStreak),
                            ),
                            _ProfileStatTile(
                              width: tileWidth,
                              accent: const Color(0xFF4C9BE8),
                              icon: const Icon(
                                Icons.cake_outlined,
                                size: 20,
                                color: Color(0xFF3E8EDC),
                              ),
                              label: 'Age',
                              value: age == null ? '--' : '$age yrs',
                            ),
                            _ProfileStatTile(
                              width: tileWidth,
                              accent: const Color(0xFF9672D8),
                              icon: const Icon(
                                Icons.wc_rounded,
                                size: 21,
                                color: Color(0xFF8863CC),
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
              );
            },
          ),
        ],
      ),
    );
  }

  String _daysValue(int value) {
    return value == 1 ? '1 day' : '$value days';
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.userId,
    required this.gender,
    required this.role,
    required this.palette,
    required this.onEditAvatar,
  });

  final int? userId;
  final String? gender;
  final String? role;
  final _ProfileHeaderPalette palette;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change profile avatar',
      child: Tooltip(
        message: 'Change profile avatar',
        child: InkWell(
          key: const ValueKey('profile-header-avatar-edit'),
          onTap: onEditAvatar,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: palette.avatarRingColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF193044)
                        : Colors.white.withValues(alpha: 0.94),
                  ),
                  child: CurrentUserAvatar(
                    userId: userId,
                    gender: gender,
                    userType: role,
                    size: 82,
                    semanticLabel: 'Current profile avatar',
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette.editButton,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF123A4A).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.username,
    required this.email,
    required this.role,
    required this.centered,
    required this.palette,
  });

  final String username;
  final String email;
  final String? role;
  final bool centered;
  final _ProfileHeaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: palette.primaryText,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 13.5,
            color: palette.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: palette.glassSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: palette.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge_outlined, size: 16, color: palette.accent),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  role == null ? 'Role not set' : _titleCaseCategory(role!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: palette.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSoftOrb extends StatelessWidget {
  const _ProfileSoftOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _ProfileStreakPreviewCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final VoidCallback onOpenStreak;

  const _ProfileStreakPreviewCard({
    required this.currentStreak,
    required this.longestStreak,
    required this.onOpenStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onOpenStreak,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: pageBorderColor(context)),
          boxShadow: pageCardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A1F), Color(0xFFFACC15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(19),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFF8A1F,
                    ).withValues(alpha: isDark ? 0.18 : 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View streak card',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pagePrimaryTextColor(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Current: ${_daysValue(currentStreak)}  -  '
                    'Best: ${_daysValue(longestStreak)}',
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: pageSecondaryTextColor(context),
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
  const _ProfileLogoWatermark({required this.opacity, required this.size});

  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
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
  final Color accent;
  final Widget icon;
  final String label;
  final String value;

  const _ProfileStatTile({
    required this.width,
    required this.accent,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfileHeaderPalette.of(context);

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: palette.glassSurface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: palette.glassBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164E63).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: icon),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.2,
                    color: palette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 26,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.primaryText,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
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
      child: Material(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personal information',
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
              title: 'Profile details',
              subtitle:
                  '${gender ?? 'Gender not set'} - ${role == null ? 'Role not set' : _sentenceCaseCategory(role!)}',
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
              title: 'Sleep schedule',
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
                    'Edit profile',
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
                      'My goals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Targets shared with home and nutrition',
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
            label: 'Wellness goal',
            value: goals.wellnessGoal,
          ),
          _GoalDataRow(
            icon: Icons.bedtime_outlined,
            label: 'Sleep goal',
            value: goals.sleepLabel,
          ),
          _GoalDataRow(
            icon: Icons.water_drop_outlined,
            label: 'Hydration goal',
            value: goals.hydrationLabel,
          ),
          _GoalDataRow(
            icon: Icons.fitness_center_outlined,
            label: 'Activity goal',
            value: goals.activityLabel,
          ),
          _GoalDataRow(
            icon: Icons.directions_walk_rounded,
            label: 'Daily steps',
            value: goals.dailyStepsLabel,
          ),
          _GoalDataRow(
            icon: Icons.local_dining_outlined,
            label: 'Nutrition goal',
            value: goals.nutritionLabel,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Edit goals',
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

class _ProfileAccountCard extends StatelessWidget {
  final bool isLoggingOut;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  const _ProfileAccountCard({
    required this.isLoggingOut,
    required this.onOpenSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerColor = isDark
        ? const Color(0xFFFF8A8A)
        : const Color(0xFFD83B45);

    return Container(
      key: const ValueKey('profile-account-card'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Material(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'App preferences and session controls',
                    style: TextStyle(
                      fontSize: 13,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: pageBorderColor(context)),
            ListTile(
              key: const ValueKey('profile-settings-action'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 7,
              ),
              onTap: onOpenSettings,
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1D8CA8,
                  ).withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF1D8CA8),
                ),
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              subtitle: Text(
                'Notifications, privacy, preferences, and support',
                style: TextStyle(color: pageSecondaryTextColor(context)),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: pageSecondaryTextColor(context),
              ),
            ),
            Divider(height: 1, color: pageBorderColor(context)),
            ListTile(
              key: const ValueKey('profile-logout-action'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 7,
              ),
              enabled: !isLoggingOut,
              onTap: isLoggingOut ? null : onLogout,
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: dangerColor.withValues(alpha: isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoggingOut
                    ? Padding(
                        padding: const EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: dangerColor,
                        ),
                      )
                    : Icon(Icons.logout_rounded, color: dangerColor),
              ),
              title: Text(
                isLoggingOut ? 'Logging out...' : 'Log out',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: dangerColor,
                ),
              ),
              subtitle: Text(
                'Sign out safely on this device',
                style: TextStyle(color: pageSecondaryTextColor(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
