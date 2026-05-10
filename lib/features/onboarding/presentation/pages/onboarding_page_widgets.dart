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

class _QuestionTitle extends StatelessWidget {
  final String text;

  const _QuestionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        height: 1.22,
        fontSize: 25,
        fontWeight: FontWeight.w900,
        color: pagePrimaryTextColor(context),
      ),
    );
  }
}

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

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF6FBF9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            width: selected ? 1.6 : 1,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : pageBorderColor(context),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: pagePrimaryTextColor(context),
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : pageSecondaryTextColor(context),
            ),
          ],
        ),
      ),
    );
  }
}
