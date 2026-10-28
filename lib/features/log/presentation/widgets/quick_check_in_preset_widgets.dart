import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/localized_text.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../onboarding/data/burnout_baseline_questions.dart';
import '../../data/check_in_models.dart';
import '../../data/log_api.dart';
import '../../data/quick_check_in_preset.dart';
import 'log_widgets.dart';
import 'quick_check_in_avatar_picker.dart';

enum QuickCheckInPresetMenuAction { edit, delete }

Future<CheckInMode?> showQuickCheckInModeDialog(BuildContext context) {
  return showDialog<CheckInMode>(
    context: context,
    builder: (dialogContext) => _QuickCheckInModeDialog(
      onDaily: () => Navigator.pop(dialogContext, CheckInMode.daily),
      onWeekly: () => Navigator.pop(dialogContext, CheckInMode.weekly),
      onCancel: () => Navigator.pop(dialogContext),
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
  return showDialog<QuickCheckInPresetMenuAction>(
    context: context,
    builder: (dialogContext) => Dialog(
      alignment: Alignment.center,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: pageSurfaceColor(dialogContext),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: pageBorderColor(dialogContext)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: LocalizedText('Edit ${preset.name}'),
              onTap: () => Navigator.pop(
                dialogContext,
                QuickCheckInPresetMenuAction.edit,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const LocalizedText('Delete quick check-in'),
              textColor: Theme.of(dialogContext).colorScheme.error,
              iconColor: Theme.of(dialogContext).colorScheme.error,
              onTap: () => Navigator.pop(
                dialogContext,
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
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 16),
                child: _QuickPresetCatalogSkeleton(),
              ),
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

class QuickCheckInCatalogLoadingView extends StatelessWidget {
  const QuickCheckInCatalogLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: CustomScrollView(
        key: const ValueKey('quick-check-in-catalog-skeleton'),
        slivers: [
          const SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonLine(width: 158, height: 11),
                SizedBox(height: 12),
                AppSkeletonLine(width: 220, height: 28),
                SizedBox(height: 10),
                AppSkeletonLine(widthFactor: 0.88, height: 13),
                SizedBox(height: 6),
                AppSkeletonLine(widthFactor: 0.62, height: 13),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 22),
              child: _QuickPresetCatalogSkeleton(),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: mainPageBottomContentPadding(context)),
          ),
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
            'Tap to preview and confirm. Long press to edit or delete. Swipe right for the full questionnaire.',
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
      label:
          '${'Preview quick check-in'.localizedCopy(context)}: ${preset.name}',
      onLongPressHint: 'Edit or delete quick check-in'.localizedCopy(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('quick-preset-${preset.presetId}'),
          onTap: isSaving ? null : onTap,
          onLongPress: isSaving ? null : onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
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
                                const Icon(Icons.mood_rounded, size: 40),
                          ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preset.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 14,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
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

class _QuickPresetCatalogSkeleton extends StatelessWidget {
  const _QuickPresetCatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      ignorePointers: false,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
        children: List.generate(
          3,
          (_) => Container(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
            decoration: BoxDecoration(
              color: pageSurfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pageBorderColor(context)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  width: 62,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 48,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
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

class _QuickCheckInModeDialog extends StatelessWidget {
  const _QuickCheckInModeDialog({
    required this.onDaily,
    required this.onWeekly,
    required this.onCancel,
  });

  final VoidCallback onDaily;
  final VoidCallback onWeekly;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: buildPageDecoration(context).copyWith(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1FB489), Color(0xFF52C7ED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LocalizedText(
                          'Choose check-in type',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                        LocalizedText(
                          'Create a reusable shortcut for your answers.',
                          style: TextStyle(
                            color: pageSecondaryTextColor(context),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ModeChoice(
                icon: Icons.today_rounded,
                accent: const Color(0xFF1FB489),
                title: 'Daily check-in',
                subtitle: 'Save all 14 daily answers.',
                onTap: onDaily,
              ),
              const SizedBox(height: 10),
              _ModeChoice(
                icon: Icons.date_range_rounded,
                accent: const Color(0xFF8B5CF6),
                title: 'Weekly check-in',
                subtitle: 'Save 9 practical inputs and 11 reflection answers.',
                onTap: onWeekly,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onCancel,
                  child: const LocalizedText('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                pageSurfaceColor(context),
                accent.withValues(alpha: isDark ? 0.11 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: pageAccentColor(context, accent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      title,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    LocalizedText(
                      subtitle,
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: pageAccentColor(context, accent),
              ),
            ],
          ),
        ),
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
  bool _isPreparingQuestionnaire = true;
  bool _preparationScheduled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _draft = widget.initialDraft;
    _weeklyAnswers = Map<String, int>.from(widget.initialWeeklyAnswers);
    _avatarId = widget.existing?.avatarId ?? 'happy';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preparationScheduled) return;
    _preparationScheduled = true;

    final delay = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 360);
    Future<void>.delayed(delay, () {
      if (mounted) {
        setState(() => _isPreparingQuestionnaire = false);
      }
    });
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
    final accent = weekly ? const Color(0xFF8B5CF6) : const Color(0xFF1FB489);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: screen.height * 0.9,
        ),
        child: Container(
          decoration: buildPageDecoration(context).copyWith(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.16),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: isDark ? 0.2 : 0.14),
                      accent.withValues(alpha: 0.025),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: pageBorderColor(context)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Icon(
                        weekly
                            ? Icons.calendar_view_week_rounded
                            : Icons.bolt_rounded,
                        color: pageAccentColor(context, accent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            widget.existing == null
                                ? 'New quick check-in'
                                : 'Edit quick check-in',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.45,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                  alpha: isDark ? 0.2 : 0.11,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: LocalizedText(
                                weekly ? 'Weekly preset' : 'Daily preset',
                                style: TextStyle(
                                  color: pageAccentColor(context, accent),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close'.localizedCopy(context),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: pageSurfaceColor(context),
                        side: BorderSide(color: pageBorderColor(context)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 21),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PresetEditorSection(
                        icon: Icons.edit_note_rounded,
                        accent: accent,
                        title: 'Name your preset',
                        subtitle: 'Make it easy to recognize later.',
                        child: TextField(
                          key: const ValueKey('quick-check-in-name'),
                          controller: _nameController,
                          maxLength: 40,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Quick check-in name'.localizedCopy(
                              context,
                            ),
                            hintText: 'For example: Productive'.localizedCopy(
                              context,
                            ),
                            filled: true,
                            fillColor: pageSubtleSurfaceColor(context),
                            prefixIcon: Icon(
                              Icons.auto_awesome_rounded,
                              color: pageAccentColor(context, accent),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: pageBorderColor(context),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: pageBorderColor(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PresetEditorSection(
                        icon: Icons.emoji_emotions_outlined,
                        accent: accent,
                        title: 'Choose an emoji',
                        subtitle: 'Scroll to explore moods and activities.',
                        child: QuickCheckInAvatarPicker(
                          selectedId: _avatarId,
                          accent: accent,
                          onSelected: (id) => setState(() => _avatarId = id),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _QuestionnaireHeading(weekly: weekly, accent: accent),
                      const SizedBox(height: 12),
                      AnalyticsContentSwitcher(
                        isLoading: _isPreparingQuestionnaire,
                        overlapOutgoing: false,
                        contentKey: widget.mode,
                        loading: const _QuickCheckInQuestionnaireSkeleton(),
                        child: LogWidgets(
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
                            () => _draft = _draft.copyWith(
                              detachmentLevel: value,
                            ),
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
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 19,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: LocalizedText(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: pageSurfaceColor(context),
                  border: Border(
                    top: BorderSide(color: pageBorderColor(context)),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(88, 48),
                      ),
                      child: const LocalizedText('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('save-quick-check-in-preset'),
                        onPressed: _isPreparingQuestionnaire ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_add_rounded),
                        label: const LocalizedText('Save quick check-in'),
                      ),
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

class _PresetEditorSection extends StatelessWidget {
  const _PresetEditorSection({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pageSurfaceColor(context),
            Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.045 : 0.03),
              pageSurfaceColor(context),
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: pageAccentColor(context, accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      title,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LocalizedText(
                      subtitle,
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _QuestionnaireHeading extends StatelessWidget {
  const _QuestionnaireHeading({required this.weekly, required this.accent});

  final bool weekly;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.fact_check_outlined,
            color: pageAccentColor(context, accent),
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LocalizedText(
                        'Your answers',
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        weekly ? '20' : '14',
                        style: TextStyle(
                          color: pageAccentColor(context, accent),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LocalizedText(
                  weekly
                      ? 'Add 9 practical inputs and all 11 weekly reflection answers.'
                      : 'Answer all 14 questions once. You can edit them anytime.',
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 12.5,
                    height: 1.35,
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

class _QuickCheckInQuestionnaireSkeleton extends StatelessWidget {
  const _QuickCheckInQuestionnaireSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading questionnaire'.localizedCopy(context),
      child: const Column(
        key: ValueKey('quick-check-in-questionnaire-skeleton'),
        children: [
          AppSkeletonCard(height: 126, lineCount: 2),
          SizedBox(height: 14),
          AppSkeletonCard(height: 142, lineCount: 2),
          SizedBox(height: 14),
          AppSkeletonCard(height: 118, lineCount: 1),
        ],
      ),
    );
  }
}

String _number(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
