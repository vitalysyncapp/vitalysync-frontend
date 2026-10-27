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
  final String subtitle;
  final double progress;
  final int currentStep;
  final int totalSteps;

  const _OnboardingHeader({
    required this.step,
    required this.subtitle,
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      key: const ValueKey('onboarding-header'),
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: pageSurfaceColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: LocalizedText(
                      step.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  LocalizedText(
                    '$currentStep / $totalSteps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              LocalizedText(
                subtitle,
                style: TextStyle(
                  height: 1.3,
                  fontSize: 12,
                  color: pageSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Semantics(
                  label: 'Onboarding progress'.localizedCopy(context),
                  value: '$currentStep / $totalSteps',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF69A6FF), Color(0xFF8DD3FF)],
                            ),
                          ),
                          child: SizedBox.expand(),
                        ),
                      ),
                    ),
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

// The section illustration sits behind the content instead of taking header space.
class _OnboardingBackdrop extends StatelessWidget {
  final String assetPath;

  const _OnboardingBackdrop({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = (constraints.maxWidth * 1.15).clamp(360.0, 620.0);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF10213A).withValues(alpha: 0.40),
                                const Color(0xFF17365B).withValues(alpha: 0.30),
                              ]
                            : [
                                const Color(0xFFF2F7FF).withValues(alpha: 0.84),
                                const Color(0xFFE3F1FF).withValues(alpha: 0.72),
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: constraints.maxHeight * 0.12,
                  right: -size * 0.18,
                  child: Opacity(
                    opacity: isDark ? 0.18 : 0.30,
                    child: assetPath.endsWith('.svg')
                        ? SvgPicture.asset(
                            assetPath,
                            key: ValueKey(assetPath),
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                SizedBox.square(dimension: size),
                          )
                        : Lottie.asset(
                            assetPath,
                            key: ValueKey(assetPath),
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            repeat: !reduceMotion,
                            animate: !reduceMotion,
                            errorBuilder: (context, error, stackTrace) =>
                                SizedBox.square(dimension: size),
                          ),
                  ),
                ),
              ],
            );
          },
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
          LocalizedText(
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
    return LocalizedText(
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
    return LocalizedText(
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
                      isDark
                          ? const Color(0xFF203C60)
                          : const Color(0xFFE3F0FF),
                      isDark
                          ? const Color(0xFF1A304E)
                          : const Color(0xFFF2F8FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected
                ? null
                : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFFAFCFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              width: selected ? 1.6 : 1,
              color: selected
                  ? primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
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
                    LocalizedText(
                      _sentenceCaseOption(label),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      LocalizedText(
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
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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
            color: selected
                ? primary
                : Theme.of(context).colorScheme.outlineVariant,
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
        child: Icon(
          icon,
          size: 21,
          color: selected ? Theme.of(context).colorScheme.onPrimary : primary,
        ),
      ),
    );
  }
}
