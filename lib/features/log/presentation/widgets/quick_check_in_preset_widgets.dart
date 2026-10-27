import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/localized_text.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../onboarding/data/burnout_baseline_questions.dart';
import '../../data/check_in_models.dart';
import '../../data/log_api.dart';
import '../../data/quick_check_in_preset.dart';
import 'log_widgets.dart';

enum QuickCheckInPresetMenuAction { edit, delete }

Future<CheckInMode?> showQuickCheckInModeDialog(BuildContext context) {
  return showDialog<CheckInMode>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const LocalizedText('Choose check-in type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChoice(
            icon: Icons.today_rounded,
            title: 'Daily check-in',
            subtitle: 'Save all 14 daily answers.',
            onTap: () => Navigator.pop(dialogContext, CheckInMode.daily),
          ),
          const SizedBox(height: 10),
          _ModeChoice(
            icon: Icons.date_range_rounded,
            title: 'Weekly check-in',
            subtitle: 'Save 9 practical inputs and 11 reflection answers.',
            onTap: () => Navigator.pop(dialogContext, CheckInMode.weekly),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const LocalizedText('Cancel'),
        ),
      ],
    ),
  );
}

Future<QuickCheckInPreset?> showQuickCheckInPresetEditor({
  required BuildContext context,
  required CheckInMode mode,
  required CheckInDraft initialDraft,
  required String exerciseGoalLabel,
  Map<String, int> initialWeeklyAnswers = const {},
  QuickCheckInPreset? existing,
}) {
  return showDialog<QuickCheckInPreset>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _QuickCheckInPresetEditor(
      mode: mode,
      initialDraft: initialDraft,
      initialWeeklyAnswers: initialWeeklyAnswers,
      exerciseGoalLabel: exerciseGoalLabel,
      existing: existing,
    ),
  );
}

Future<QuickCheckInPresetMenuAction?> showQuickCheckInPresetMenu(
  BuildContext context,
  QuickCheckInPreset preset,
) {
  return showModalBottomSheet<QuickCheckInPresetMenuAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pageSurfaceColor(sheetContext),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: pageBorderColor(sheetContext)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: LocalizedText('Edit ${preset.name}'),
              onTap: () => Navigator.pop(
                sheetContext,
                QuickCheckInPresetMenuAction.edit,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const LocalizedText('Delete quick check-in'),
              textColor: Theme.of(sheetContext).colorScheme.error,
              iconColor: Theme.of(sheetContext).colorScheme.error,
              onTap: () => Navigator.pop(
                sheetContext,
                QuickCheckInPresetMenuAction.delete,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> confirmQuickCheckInPresetDelete(
  BuildContext context,
  QuickCheckInPreset preset,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const LocalizedText('Delete quick check-in?'),
          content: LocalizedText(
            '${preset.name} will be removed from every signed-in device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const LocalizedText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const LocalizedText('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

class QuickCheckInCatalog extends StatelessWidget {
  const QuickCheckInCatalog({
    super.key,
    required this.mode,
    required this.presets,
    required this.isLoading,
    required this.isStale,
    required this.activePresetId,
    required this.onPresetTap,
    required this.onPresetLongPress,
    required this.onAdd,
    required this.onRetry,
  });

  final CheckInMode mode;
  final List<QuickCheckInPreset> presets;
  final bool isLoading;
  final bool isStale;
  final int? activePresetId;
  final ValueChanged<QuickCheckInPreset> onPresetTap;
  final ValueChanged<QuickCheckInPreset> onPresetLongPress;
  final VoidCallback onAdd;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final filtered = presets
        .where((preset) => preset.mode == mode)
        .toList(growable: false);
    final bottomPadding = mainPageBottomContentPadding(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: CustomScrollView(
        key: const PageStorageKey('quick-check-in-catalog'),
        slivers: [
          SliverToBoxAdapter(child: _CatalogHeader(mode: mode)),
          if (isStale)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _StalePresetBanner(onRetry: onRetry),
              ),
            ),
          if (isLoading && filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 18, bottom: 6),
                  child: LocalizedText(
                    'No quick check-ins for this type yet. Add one to make future logging faster.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == filtered.length) {
                    return _AddPresetTile(onTap: onAdd);
                  }
                  final preset = filtered[index];
                  return _PresetTile(
                    preset: preset,
                    isSaving: activePresetId == preset.presetId,
                    onTap: () => onPresetTap(preset),
                    onLongPress: () => onPresetLongPress(preset),
                  );
                }, childCount: filtered.length + 1),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.66,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
        ],
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.mode});

  final CheckInMode mode;

  @override
  Widget build(BuildContext context) {
    final weekly = mode == CheckInMode.weekly;
    final accent = weekly ? const Color(0xFF8B5CF6) : const Color(0xFF1FB489);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: accent, size: 20),
              const SizedBox(width: 6),
              LocalizedText(
                weekly ? 'WEEKLY QUICK CHECK-INS' : 'DAILY QUICK CHECK-INS',
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LocalizedText(
            'Quick check-ins',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 5),
          LocalizedText(
            'Tap to log now. Long press to edit or delete. Swipe left for the full questionnaire.',
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.isSaving,
    required this.onTap,
    required this.onLongPress,
  });

  final QuickCheckInPreset preset;
  final bool isSaving;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final avatar = QuickCheckInAvatarCatalog.find(preset.avatarId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary =
        '${'Sleep:'.localizedCopy(context)} ${_number(preset.draft.sleepHours)}h\n'
        '${'Water:'.localizedCopy(context)} ${_number(preset.draft.hydrationLiters)}L\n'
        '${'Energy:'.localizedCopy(context)} ${preset.draft.energyLevel ?? '-'}/5';
    return Semantics(
      button: true,
      label: '${'Log now'.localizedCopy(context)}: ${preset.name}',
      onLongPressHint: 'Edit or delete quick check-in'.localizedCopy(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('quick-preset-${preset.presetId}'),
          onTap: isSaving ? null : onTap,
          onLongPress: isSaving ? null : onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(7, 10, 7, 9),
            decoration: BoxDecoration(
              color: pageSurfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pageBorderColor(context)),
              boxShadow: pageCardShadow(context),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: isSaving
                        ? const CircularProgressIndicator(strokeWidth: 2.5)
                        : SvgPicture.asset(
                            avatar.assetPath,
                            semanticsLabel: avatar.semanticLabel.localizedCopy(
                              context,
                            ),
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) =>
                                const Icon(Icons.mood_rounded, size: 44),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  preset.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 13,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: isDark ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPresetTile extends StatelessWidget {
  const _AddPresetTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF5B700);
    return Semantics(
      button: true,
      label: 'Add quick check-in'.localizedCopy(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('add-quick-check-in'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: pageSurfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pageBorderColor(context)),
              boxShadow: pageCardShadow(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 12),
                LocalizedText(
                  'Add',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StalePresetBanner extends StatelessWidget {
  const _StalePresetBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB020).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB020).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: LocalizedText(
              'Showing saved presets. Connect to manage or sync them.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onRetry, child: const LocalizedText('Retry')),
        ],
      ),
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(icon),
        title: LocalizedText(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: LocalizedText(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}

class _QuickCheckInPresetEditor extends StatefulWidget {
  const _QuickCheckInPresetEditor({
    required this.mode,
    required this.initialDraft,
    required this.initialWeeklyAnswers,
    required this.exerciseGoalLabel,
    this.existing,
  });

  final CheckInMode mode;
  final CheckInDraft initialDraft;
  final Map<String, int> initialWeeklyAnswers;
  final String exerciseGoalLabel;
  final QuickCheckInPreset? existing;

  @override
  State<_QuickCheckInPresetEditor> createState() =>
      _QuickCheckInPresetEditorState();
}

class _QuickCheckInPresetEditorState extends State<_QuickCheckInPresetEditor> {
  late final TextEditingController _nameController;
  late CheckInDraft _draft;
  late Map<String, int> _weeklyAnswers;
  late String _avatarId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _draft = widget.initialDraft;
    _weeklyAnswers = Map<String, int>.from(widget.initialWeeklyAnswers);
    _avatarId = widget.existing?.avatarId ?? 'happy';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleSet(
    String value,
    Set<String> current,
    CheckInDraft Function(Set<String>) write,
  ) {
    final next = Set<String>.from(current);
    if (value == 'None') {
      if (next.contains('None')) {
        next.remove('None');
      } else {
        next
          ..clear()
          ..add('None');
      }
    } else {
      next.remove('None');
      next.contains(value) ? next.remove(value) : next.add(value);
    }
    setState(() => _draft = write(next));
  }

  void _save() {
    final name = _nameController.text.trim();
    final missing = _draft.validationErrors(widget.mode);
    if (widget.mode == CheckInMode.weekly &&
        _weeklyAnswers.length != kWeeklyQuestionCount) {
      missing.add(
        'weekly reflection (${_weeklyAnswers.length} of $kWeeklyQuestionCount)',
      );
    }
    if (name.isEmpty || name.length > 40 || missing.isNotEmpty) {
      setState(() {
        _error = name.isEmpty || name.length > 40
            ? 'Enter a name between 1 and 40 characters.'
            : 'Complete ${missing.join(', ')} before saving.';
      });
      return;
    }

    Navigator.pop(
      context,
      QuickCheckInPreset(
        presetId: widget.existing?.presetId ?? 0,
        name: name,
        mode: widget.mode,
        avatarId: _avatarId,
        draft: _draft,
        weeklyAnswers: Map.unmodifiable(_weeklyAnswers),
        createdAt: widget.existing?.createdAt,
        updatedAt: widget.existing?.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final weekly = widget.mode == CheckInMode.weekly;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: screen.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: pageBorderColor(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            widget.existing == null
                                ? 'New quick check-in'
                                : 'Edit quick check-in',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          LocalizedText(
                            weekly ? 'Weekly preset' : 'Daily preset',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close'.localizedCopy(context),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const ValueKey('quick-check-in-name'),
                        controller: _nameController,
                        maxLength: 40,
                        decoration: InputDecoration(
                          labelText: 'Quick check-in name'.localizedCopy(
                            context,
                          ),
                          hintText: 'For example: Productive'.localizedCopy(
                            context,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const LocalizedText(
                        'Choose an emoji',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final avatar
                              in QuickCheckInAvatarCatalog.entries)
                            Semantics(
                              button: true,
                              selected: avatar.id == _avatarId,
                              label: avatar.semanticLabel.localizedCopy(
                                context,
                              ),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _avatarId = avatar.id),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 54,
                                  height: 54,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: avatar.id == _avatarId
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: avatar.id == _avatarId
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : pageBorderColor(context),
                                      width: avatar.id == _avatarId ? 2 : 1,
                                    ),
                                  ),
                                  child: SvgPicture.asset(avatar.assetPath),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LogWidgets(
                        revealCards: false,
                        showWeeklyQuestions: weekly,
                        weeklyAnswers: _weeklyAnswers,
                        onWeeklyAnswerChanged: (key, value) =>
                            setState(() => _weeklyAnswers[key] = value),
                        sleepHours: _draft.sleepHours,
                        sleepQuality: _draft.sleepQuality,
                        moodIndex: _draft.moodIndex,
                        energyLevel: _draft.energyLevel,
                        hydration: _draft.hydrationLiters,
                        workloadHoursBand: _draft.workloadHoursBand,
                        perceivedStressLevel: _draft.perceivedPressureLevel,
                        breakQualityLevel: _draft.recoveryRestLevel,
                        dailyDetachmentLevel: _draft.detachmentLevel,
                        dailyFocusLevel: _draft.productivityFocusLevel,
                        dailyAccomplishmentLevel: _draft.accomplishmentLevel,
                        selectedExercises: _draft.exerciseNames,
                        selectedSymptoms: _draft.symptomNames,
                        selectedHabits: _draft.habitNames,
                        sleepLabels: CheckInFormOptions.sleepLabels,
                        sleepStars: CheckInFormOptions.sleepStars,
                        moods: CheckInFormOptions.moods,
                        exercises: LogApi.exerciseOptions,
                        symptoms: CheckInFormOptions.symptoms,
                        habits: CheckInFormOptions.habits,
                        exerciseGoalLabel: widget.exerciseGoalLabel,
                        workloadOptions: LogApi.workloadHoursBandOptions,
                        onSleepChanged: (value) => setState(
                          () => _draft = _draft.copyWith(sleepHours: value),
                        ),
                        onSleepQualityChanged: (value) => setState(
                          () => _draft = _draft.copyWith(sleepQuality: value),
                        ),
                        onMoodChanged: (value) => setState(
                          () => _draft = _draft.copyWith(moodIndex: value),
                        ),
                        onEnergyChanged: (value) => setState(
                          () => _draft = _draft.copyWith(energyLevel: value),
                        ),
                        onHydrationAdd: (value) => setState(
                          () => _draft = _draft.copyWith(
                            hydrationLiters: (_draft.hydrationLiters + value)
                                .clamp(0, 10),
                          ),
                        ),
                        onHydrationSubtract: () => setState(
                          () => _draft = _draft.copyWith(
                            hydrationLiters: (_draft.hydrationLiters - 0.25)
                                .clamp(0, 10),
                          ),
                        ),
                        onHydrationReset: () => setState(
                          () => _draft = _draft.copyWith(hydrationLiters: 0),
                        ),
                        onWorkloadChanged: (value) => setState(
                          () => _draft = _draft.copyWith(
                            workloadHoursBand: value,
                          ),
                        ),
                        onPerceivedStressChanged: (value) => setState(
                          () => _draft = _draft.copyWith(
                            perceivedPressureLevel: value,
                          ),
                        ),
                        onBreakQualityChanged: (value) => setState(
                          () => _draft = _draft.copyWith(
                            recoveryRestLevel: value,
                          ),
                        ),
                        onDailyDetachmentChanged: (value) => setState(
                          () =>
                              _draft = _draft.copyWith(detachmentLevel: value),
                        ),
                        onDailyFocusChanged: (value) => setState(
                          () => _draft = _draft.copyWith(
                            productivityFocusLevel: value,
                          ),
                        ),
                        onDailyAccomplishmentChanged: (value) => setState(
                          () => _draft = _draft.copyWith(
                            accomplishmentLevel: value,
                          ),
                        ),
                        onExerciseToggle: (value) => _toggleSet(
                          value,
                          _draft.exerciseNames,
                          (values) => _draft.copyWith(exerciseNames: values),
                        ),
                        onSymptomToggle: (value) => _toggleSet(
                          value,
                          _draft.symptomNames,
                          (values) => _draft.copyWith(symptomNames: values),
                        ),
                        onHabitToggle: (value) => _toggleSet(
                          value,
                          _draft.habitNames,
                          (values) => _draft.copyWith(habitNames: values),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: LocalizedText(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const LocalizedText('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      key: const ValueKey('save-quick-check-in-preset'),
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const LocalizedText('Save quick check-in'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _number(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
