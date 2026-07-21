part of 'onboarding_page.dart';

class _OnboardingStep {
  final String sectionTitle;
  final String title;
  final WidgetBuilder builder;
  final bool Function() isComplete;

  const _OnboardingStep({
    required this.sectionTitle,
    required this.title,
    required this.builder,
    required this.isComplete,
  });
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _OnboardingHeader extends StatelessWidget {
  final _OnboardingStep step;
  final IconData icon;
  final String subtitle;
  final String animationPath;
  final double progress;
  final int currentStep;
  final int totalSteps;

  const _OnboardingHeader({
    required this.step,
    required this.icon,
    required this.subtitle,
    required this.animationPath,
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  /// Section-aware accent color for the gradient border tint.
  Color _sectionAccent() {
    if (step.sectionTitle.contains('About')) return const Color(0xFF56CCF2);
    if (step.sectionTitle.contains('Routine')) return const Color(0xFF9B7DFF);
    return const Color(0xFFFF7E5F);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = _sectionAccent();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pageSurfaceColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color.lerp(
                    pageBorderColor(context),
                    accent.withValues(alpha: 0.35),
                    0.5,
                  ) ??
                  pageBorderColor(context),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.06 : 0.04),
                blurRadius: 32,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Lottie avatar with pulse.
                  _PulsingLottieAvatar(
                    animationPath: animationPath,
                    icon: icon,
                    primary: primary,
                    accent: accent,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey(step.sectionTitle),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.sectionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: pagePrimaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              height: 1.25,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Gradient progress bar.
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: pageBorderColor(context),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: value.clamp(0.0, 1.0),
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: [primary, accent],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      '$currentStep / $totalSteps',
                      key: ValueKey(currentStep),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Pulsing Lottie avatar for the header
// ---------------------------------------------------------------------------

class _PulsingLottieAvatar extends StatefulWidget {
  final String animationPath;
  final IconData icon;
  final Color primary;
  final Color accent;
  final bool isDark;

  const _PulsingLottieAvatar({
    required this.animationPath,
    required this.icon,
    required this.primary,
    required this.accent,
    required this.isDark,
  });

  @override
  State<_PulsingLottieAvatar> createState() => _PulsingLottieAvatarState();
}

class _PulsingLottieAvatarState extends State<_PulsingLottieAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1.0 + (_pulse.value * 0.04);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              widget.primary.withValues(
                alpha: widget.isDark ? 0.32 : 0.18,
              ),
              widget.accent.withValues(
                alpha: widget.isDark ? 0.22 : 0.28,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Lottie.asset(
              widget.animationPath,
              width: 68,
              height: 68,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) {
                return Icon(widget.icon, color: widget.primary, size: 34);
              },
            ),
            Positioned(
              right: 7,
              bottom: 7,
              child: Icon(widget.icon, color: widget.primary, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step entrance animation
// ---------------------------------------------------------------------------

class _StepEntrance extends StatelessWidget {
  final Widget child;

  const _StepEntrance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(16 * (1 - value), 18 * (1 - value)),
            child: Transform.scale(
              scale: 0.96 + (0.04 * value),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Prompt badge (category pill at top of each question card)
// ---------------------------------------------------------------------------

class _PromptBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PromptBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.14),
            primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: primary),
          const SizedBox(width: 7),
          Text(
            _sentenceCaseOption(label),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Question title
// ---------------------------------------------------------------------------

class _QuestionTitle extends StatelessWidget {
  final String text;

  const _QuestionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        height: 1.2,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
        color: pagePrimaryTextColor(context),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper text
// ---------------------------------------------------------------------------

class _HelperText extends StatelessWidget {
  final String text;

  const _HelperText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        height: 1.45,
        fontSize: 14.5,
        color: pageSecondaryTextColor(context),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Option tile (single/multi select)
// ---------------------------------------------------------------------------

class _OptionTile extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    this.description,
    required this.icon,
    required this.selected,
    this.multiSelect = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: selected ? 1.025 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.16),
                      primary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected
                ? null
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF6FBF9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              width: selected ? 1.6 : 1,
              color: selected ? primary : pageBorderColor(context),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: primary.withValues(alpha: 0.06),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _AnimatedIconBadge(icon, selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sentenceCaseOption(label),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(
                          height: 1.3,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  selected
                      ? multiSelect
                          ? Icons.check_box_rounded
                          : Icons.check_circle_rounded
                      : multiSelect
                          ? Icons.check_box_outline_blank_rounded
                          : Icons.radio_button_unchecked_rounded,
                  key: ValueKey('$selected-$multiSelect'),
                  color: selected ? primary : pageSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric input (height/weight)
// ---------------------------------------------------------------------------

class _MetricInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final TextInputAction textInputAction;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _MetricInput({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.textInputAction,
    required this.validator,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF6FBF9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: pageBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: pageBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            width: 1.6,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: pagePrimaryTextColor(context),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _sentenceCaseOption(String value) {
  final text = value.trim();
  if (text.length < 2) return text;
  return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
}

// ---------------------------------------------------------------------------
// Animated icon badge (circle beside each option)
// ---------------------------------------------------------------------------

class _AnimatedIconBadge extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _AnimatedIconBadge(this.icon, {required this.selected});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedRotation(
      turns: selected ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected
              ? LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.78)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.72),
          border: Border.all(
            color: selected ? primary : pageBorderColor(context),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 21, color: selected ? Colors.white : primary),
      ),
    );
  }
}
