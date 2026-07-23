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

class _ProfileHeaderCard extends StatefulWidget {
  final int? userId;
  final String username;
  final String email;
  final bool emailVerified;
  final String? role;
  final int currentStreak;
  final int longestStreak;
  final int? age;
  final String? gender;
  final VoidCallback onEditAvatar;
  final VoidCallback onVerifyEmail;

  const _ProfileHeaderCard({
    required this.userId,
    required this.username,
    required this.email,
    required this.emailVerified,
    required this.role,
    required this.currentStreak,
    required this.longestStreak,
    required this.age,
    required this.gender,
    required this.onEditAvatar,
    required this.onVerifyEmail,
  });

  @override
  State<_ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<_ProfileHeaderCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _shimmerController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final List<Animation<double>> _statFades;
  late final List<Animation<Offset>> _statSlides;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        );

    _statFades = List.generate(4, (i) {
      final start = 0.3 + i * 0.1;
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          start,
          (start + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );
    });
    _statSlides = List.generate(4, (i) {
      final start = 0.3 + i * 0.1;
      return Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(
            start,
            (start + 0.35).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ProfileHeaderPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardFade,
        child: Container(
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
              BoxShadow(
                color: palette.accent.withValues(alpha: isDark ? 0.06 : 0.04),
                blurRadius: 48,
                spreadRadius: 2,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -76,
                right: -54,
                child: IgnorePointer(
                  child: _ProfileSoftOrb(
                    size: 196,
                    color: palette.secondaryOrb,
                  ),
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
                top: -40,
                left: -40,
                child: IgnorePointer(
                  child: _ProfileSoftOrb(
                    size: 120,
                    color: palette.accent.withValues(
                      alpha: isDark ? 0.04 : 0.06,
                    ),
                  ),
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
                    userId: widget.userId,
                    gender: widget.gender,
                    role: widget.role,
                    palette: palette,
                    onEditAvatar: widget.onEditAvatar,
                    shimmerAnimation: _shimmerController,
                  );
                  final identity = _ProfileIdentity(
                    username: widget.username,
                    email: widget.email,
                    emailVerified: widget.emailVerified,
                    role: widget.role,
                    centered: useStackedIdentity,
                    palette: palette,
                    shimmerAnimation: _shimmerController,
                    onVerifyEmail: widget.onVerifyEmail,
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
                        Divider(
                          color: palette.divider,
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, statConstraints) {
                            final columns = statConstraints.maxWidth >= 620
                                ? 4
                                : 2;
                            const spacing = 11.0;
                            final tileWidth =
                                (statConstraints.maxWidth -
                                    (spacing * (columns - 1))) /
                                columns;

                            final statTiles = [
                              _ProfileStatTile(
                                width: tileWidth,
                                accent: const Color(0xFFF08A35),
                                icon: const _ProfileFireAnimation(size: 24),
                                label: 'Current streak',
                                value: _daysValue(widget.currentStreak),
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
                                value: _daysValue(widget.longestStreak),
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
                                value: widget.age == null
                                    ? '--'
                                    : '${widget.age} yrs',
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
                                value: widget.gender ?? '--',
                              ),
                            ];

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: List.generate(statTiles.length, (i) {
                                return SlideTransition(
                                  position: _statSlides[i],
                                  child: FadeTransition(
                                    opacity: _statFades[i],
                                    child: statTiles[i],
                                  ),
                                );
                              }),
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
        ),
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
    required this.shimmerAnimation,
  });

  final int? userId;
  final String? gender;
  final String? role;
  final _ProfileHeaderPalette palette;
  final VoidCallback onEditAvatar;
  final Animation<double> shimmerAnimation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // Ambient glow behind the avatar
              Positioned(
                top: -6,
                left: -6,
                right: -6,
                bottom: -6,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: palette.avatarRingColors[0].withValues(
                            alpha: isDark ? 0.18 : 0.14,
                          ),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: palette.avatarRingColors[1].withValues(
                            alpha: isDark ? 0.10 : 0.08,
                          ),
                          blurRadius: 48,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Animated rotating gradient ring
              AnimatedBuilder(
                animation: shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        startAngle: shimmerAnimation.value * 6.2832,
                        colors: [
                          palette.avatarRingColors[0],
                          palette.avatarRingColors[1],
                          palette.avatarRingColors[2],
                          palette.avatarRingColors[0],
                        ],
                        stops: const [0.0, 0.33, 0.67, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accent.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF193044)
                        : Colors.white.withValues(alpha: 0.96),
                  ),
                  child: CurrentUserAvatar(
                    userId: userId,
                    gender: gender,
                    userType: role,
                    size: 86,
                    semanticLabel: 'Current profile avatar',
                  ),
                ),
              ),
              // Edit badge
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.editButton,
                        palette.editButton.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF193044) : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.editButton.withValues(alpha: 0.3),
                        blurRadius: 10,
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
    required this.emailVerified,
    required this.role,
    required this.centered,
    required this.palette,
    required this.shimmerAnimation,
    required this.onVerifyEmail,
  });

  final String username;
  final String email;
  final bool emailVerified;
  final String? role;
  final bool centered;
  final _ProfileHeaderPalette palette;
  final Animation<double> shimmerAnimation;
  final VoidCallback onVerifyEmail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: palette.primaryText,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              Icons.mail_outline_rounded,
              size: 14,
              color: palette.secondaryText.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: 13.5,
                  color: palette.secondaryText,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (emailVerified) ...[
              const SizedBox(width: 5),
              Tooltip(
                message: 'Email verified',
                child: Semantics(
                  label: 'Email verified',
                  child: const ExcludeSemantics(
                    child: Text(
                      '\u{2705}',
                      key: ValueKey('profile-email-verified-badge'),
                      style: TextStyle(fontSize: 13.5, height: 1),
                    ),
                  ),
                ),
              ),
            ] else if (email.trim().isNotEmpty &&
                email.trim() != 'user@email.com') ...[
              const SizedBox(width: 7),
              TextButton(
                key: const ValueKey('profile-email-verify-button'),
                onPressed: onVerifyEmail,
                style: TextButton.styleFrom(
                  foregroundColor: palette.accent,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 26),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Verify email'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: shimmerAnimation,
          builder: (context, child) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: palette.glassSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: palette.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(
                      alpha: isDark ? 0.08 : 0.06,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  final shimmerPos = shimmerAnimation.value;
                  return LinearGradient(
                    begin: Alignment(-1.0 + 2.0 * shimmerPos, 0),
                    end: Alignment(0.0 + 2.0 * shimmerPos, 0),
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.modulate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 16, color: palette.accent),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        role == null
                            ? 'Role not set'
                            : _titleCaseCategory(role!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.primaryText,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: palette.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.glassBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164E63).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.06 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.15),
                      accent.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
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
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: palette.primaryText,
                  letterSpacing: -0.25,
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
