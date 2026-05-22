part of 'floating_smart_nudge_assistant.dart';

class _WeeklyPulseCard extends StatelessWidget {
  final bool isLoading;
  final bool isSaving;
  final bool hasResponse;
  final bool isEditing;
  final int? productivityFocusLevel;
  final int? recoveryRestLevel;
  final int? detachmentLevel;
  final int? accomplishmentLevel;
  final ValueChanged<int> onProductivityChanged;
  final ValueChanged<int> onRecoveryChanged;
  final ValueChanged<int> onDetachmentChanged;
  final ValueChanged<int> onAccomplishmentChanged;
  final VoidCallback onSave;
  final VoidCallback onRedo;

  const _WeeklyPulseCard({
    required this.isLoading,
    required this.isSaving,
    required this.hasResponse,
    required this.isEditing,
    required this.productivityFocusLevel,
    required this.recoveryRestLevel,
    required this.detachmentLevel,
    required this.accomplishmentLevel,
    required this.onProductivityChanged,
    required this.onRecoveryChanged,
    required this.onDetachmentChanged,
    required this.onAccomplishmentChanged,
    required this.onSave,
    required this.onRedo,
  });

  bool get _canSave =>
      productivityFocusLevel != null &&
      recoveryRestLevel != null &&
      detachmentLevel != null &&
      accomplishmentLevel != null &&
      !isSaving;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _AssistantLoadingCard();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF0F1F2E).withValues(alpha: 0.96)
        : const Color(0xFFF8FEFC);
    final headerGradient = isDark
        ? const [Color(0xFF123655), Color(0xFF1FB489)]
        : const [Color(0xFFE8FFF5), Color(0xFFE8F7FF)];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFBCEBDD),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF1FB489,
            ).withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.82),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.9),
                    ),
                  ),
                  child: const Text(
                    '\u{1F33F}',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Pulse',
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasResponse
                            ? 'Your check-in is saved for this Monday-based week.'
                            : 'A calm check-in for focus, rest, distance, and wins.',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasResponse && !isEditing) ...[
            const SizedBox(height: 16),
            _WeeklyPulseSavedView(onRedo: onRedo),
          ] else ...[
            const SizedBox(height: 16),
            _PulseLikertQuestion(
              emoji: '\u{1F3AF}',
              title: 'I was able to stay focused on important tasks this week.',
              lowLabel: 'Scattered',
              highLabel: 'Focused',
              accentColor: const Color(0xFF38BDF8),
              value: productivityFocusLevel,
              onChanged: onProductivityChanged,
            ),
            const SizedBox(height: 12),
            _PulseLikertQuestion(
              emoji: '\u{1F319}',
              title: 'I had enough breaks or recovery time this week.',
              lowLabel: 'Limited',
              highLabel: 'Rested',
              accentColor: const Color(0xFF8B5CF6),
              value: recoveryRestLevel,
              onChanged: onRecoveryChanged,
            ),
            const SizedBox(height: 12),
            _PulseLikertQuestion(
              emoji: '\u{1FAE7}',
              title:
                  'I felt emotionally distant from my responsibilities this week.',
              lowLabel: 'Connected',
              highLabel: 'Detached',
              accentColor: const Color(0xFF14B8A6),
              value: detachmentLevel,
              onChanged: onDetachmentChanged,
            ),
            const SizedBox(height: 12),
            _PulseLikertQuestion(
              emoji: '\u{2728}',
              title: 'I felt I made meaningful progress this week.',
              lowLabel: 'Stuck',
              highLabel: 'Progress',
              accentColor: const Color(0xFFF59E0B),
              value: accomplishmentLevel,
              onChanged: onAccomplishmentChanged,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSave ? onSave : null,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : hasResponse
                      ? 'Update Weekly Pulse'
                      : 'Save Weekly Pulse',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FB489),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyPulseSavedView extends StatelessWidget {
  final VoidCallback onRedo;

  const _WeeklyPulseSavedView({required this.onRedo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFD7F5E7),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDCFCE7),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Text('\u{2705}', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 12),
          Text(
            'Weekly pulse saved',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You are set for this week. A fresh pulse opens again next Monday.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 13.5,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRedo,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Redo Weekly Pulse'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF15803D),
              side: const BorderSide(color: Color(0xFF86EFAC)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseLikertQuestion extends StatelessWidget {
  final String emoji;
  final String title;
  final String lowLabel;
  final String highLabel;
  final Color accentColor;
  final int? value;
  final ValueChanged<int> onChanged;

  const _PulseLikertQuestion({
    required this.emoji,
    required this.title,
    required this.lowLabel,
    required this.highLabel,
    required this.accentColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final optionValue = index + 1;
              final selected = value == optionValue;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 4 ? 0 : 7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onChanged(optionValue),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor
                            : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? accentColor
                              : pageBorderColor(context),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.24),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '$optionValue',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : pagePrimaryTextColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  lowLabel,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                highLabel,
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
