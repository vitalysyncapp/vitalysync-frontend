import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/localized_text.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../onboarding/data/burnout_baseline_questions.dart';
import '../../../onboarding/widgets/likert_question.dart';
import '../../data/check_in_state_coordinator.dart';
import '../../data/weekly_assessment_api.dart';

/// Opens the 11-question weekly reflection for the current due cycle.
Future<void> openWeeklyAssessment(
  BuildContext context,
  Map<String, dynamic>? data,
) async {
  final dueDate = data?['due_date']?.toString();
  if (dueDate == null) return;
  final today = data?['today'];
  final initial = today is Map && today['answers'] is Map
      ? Map<String, int>.from(today['answers'] as Map)
      : <String, int>{};
  initial.addAll(await WeeklyAssessmentApi.draft(dueDate));
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          WeeklyAssessmentPage(dueDate: dueDate, initialAnswers: initial),
    ),
  );
}

/// Small pill that shows when the next weekly check-in is, or lets the user
/// open the weekly reflection when it is due today.
class WeeklyCheckInIndicator extends StatefulWidget {
  final bool compact;
  const WeeklyCheckInIndicator({super.key, this.compact = false});

  @override
  State<WeeklyCheckInIndicator> createState() => _WeeklyCheckInIndicatorState();
}

class _WeeklyCheckInIndicatorState extends State<WeeklyCheckInIndicator> {
  Map<String, dynamic>? _data;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    CheckInStateCoordinator.instance.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    CheckInStateCoordinator.instance.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    try {
      final data = await WeeklyAssessmentApi.load();
      if (mounted && version == _loadVersion) setState(() => _data = data);
    } catch (_) {
      // The indicator is optional; hide it when weekly data is unavailable.
    }
  }

  Future<void> _open() async {
    await openWeeklyAssessment(context, _data);
    await _load();
  }

  String _nextLabel(BuildContext context, String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final now = DateTime.now();
    final days = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 1) return 'Weekly tomorrow'.localizedCopy(context);
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = DateFormat('EEE, MMM d', locale).format(date);
    return '${'Next weekly'.localizedCopy(context)} · $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final isDue = data['is_due'] == true;
    final doneToday = data['completed_today'] == true;
    final next = data['next_due_date']?.toString();
    if (!isDue && !doneToday && next == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const weeklyColor = Color(0xFF8B5CF6);
    final accent = isDark ? const Color(0xFFC4B5FD) : weeklyColor;
    final IconData icon;
    final String label;
    if (doneToday) {
      icon = Icons.check_circle_rounded;
      label = 'Weekly reflection done'.localizedCopy(context);
    } else if (isDue) {
      icon = Icons.edit_note_rounded;
      label = 'Start weekly reflection'.localizedCopy(context);
    } else {
      icon = Icons.event_repeat_rounded;
      label = _nextLabel(context, next!);
    }
    final tappable = isDue || doneToday;
    final highlight = isDue && !doneToday;
    final fontSize = widget.compact ? 10.5 : 11.5;

    final pill = Container(
      height: widget.compact ? 24 : 28,
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 10),
      decoration: BoxDecoration(
        color: highlight
            ? accent.withValues(alpha: isDark ? 0.26 : 0.16)
            : accent.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: highlight ? 0.5 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: widget.compact ? 12 : 14, color: accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: fontSize,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: widget.compact ? 13 : 15,
              color: accent,
            ),
          ],
        ],
      ),
    );

    if (!tappable) return pill;
    return Material(
      key: const ValueKey('weekly-checkin-indicator'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _open,
        child: pill,
      ),
    );
  }
}

class WeeklyAssessmentCard extends StatefulWidget {
  final bool showHistory;
  const WeeklyAssessmentCard({super.key, this.showHistory = false});

  @override
  State<WeeklyAssessmentCard> createState() => _WeeklyAssessmentCardState();
}

class _WeeklyAssessmentCardState extends State<WeeklyAssessmentCard> {
  Map<String, dynamic>? _data;
  String? _error;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    CheckInStateCoordinator.instance.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    CheckInStateCoordinator.instance.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    try {
      final data = await WeeklyAssessmentApi.load();
      if (mounted && version == _loadVersion) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && version == _loadVersion) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _open() async {
    await openWeeklyAssessment(context, _data);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final latest = data?['latest'];
    final pending = data?['pending'];
    final hasPending = pending is Map && pending.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LocalizedText(
            'Weekly reflection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const LocalizedText(
            '11 questions about exhaustion, detachment, and accomplishment. Scored separately from your daily index.',
          ),
          const SizedBox(height: 10),
          if (_error != null) ...[
            LocalizedText(_error!),
            TextButton(onPressed: _load, child: const LocalizedText('Retry')),
          ] else if (data == null)
            const LinearProgressIndicator()
          else ...[
            if (latest is Map)
              WeeklyDimensionResults(
                assessment: Map<String, dynamic>.from(latest),
              )
            else
              const LocalizedText('No weekly questionnaire completed yet.'),
            if (hasPending)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LocalizedText(
                  'Weekly answers saved offline. Scores appear after syncing.',
                ),
              ),
            if (data['sync_error'] != null)
              LocalizedText(data['sync_error'].toString()),
            if (data['is_due'] == true || data['completed_today'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FilledButton.icon(
                  onPressed: _open,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: LocalizedText(
                    data['completed_today'] == true
                        ? 'Edit weekly log'
                        : 'Complete weekly log',
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LocalizedText(
                  data['next_due_date'] == null
                      ? 'Your first weekly log is scheduled after you start daily logging.'
                      : 'Next weekly log: ${data['next_due_date']}',
                ),
              ),
            if (widget.showHistory && data['history'] is List)
              for (final row in (data['history'] as List).whereType<Map>())
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: LocalizedText('Weekly log · ${row['response_date']}'),
                  children: [
                    WeeklyDimensionResults(
                      assessment: Map<String, dynamic>.from(row),
                    ),
                  ],
                ),
          ],
        ],
      ),
    );
  }
}

class WeeklyDimensionResults extends StatelessWidget {
  final Map<String, dynamic> assessment;
  const WeeklyDimensionResults({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final scores = assessment['scores'];
    const labels = {
      'emotional_exhaustion': 'Emotional exhaustion',
      'depersonalization': 'Detachment',
      'personal_accomplishment': 'Personal accomplishment',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText('Recorded ${assessment['response_date']}'),
        LocalizedText(
          assessment['questionnaire_version'] == kWeeklyQuestionnaireVersion
              ? '11-item weekly reflection'
              : 'Previous 22-item weekly reflection',
        ),
        if (scores is Map)
          for (final entry in labels.entries)
            if (scores[entry.key] is Map)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: LocalizedText(
                  '${entry.value}: ${scores[entry.key]['mean']} / 5 · total ${scores[entry.key]['total']} / ${scores[entry.key]['maximum']}',
                ),
              ),
        const SizedBox(height: 8),
        const LocalizedText(
          'Higher exhaustion or detachment means more burden. Higher accomplishment means greater fulfillment.',
        ),
      ],
    );
  }
}

class WeeklyAssessmentPage extends StatefulWidget {
  final String dueDate;
  final Map<String, int> initialAnswers;
  const WeeklyAssessmentPage({
    super.key,
    required this.dueDate,
    this.initialAnswers = const {},
  });

  @override
  State<WeeklyAssessmentPage> createState() => _WeeklyAssessmentPageState();
}

class _WeeklyAssessmentPageState extends State<WeeklyAssessmentPage> {
  late final Map<String, int> _answers = {
    for (final section in kBurnoutWeeklySections)
      for (final question in section.questions)
        if (widget.initialAnswers[question.questionKey] case final int value
            when value >= 1 && value <= 5)
          question.questionKey: value,
  };
  bool _saving = false;
  Future<void> _draftWrite = Future.value();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _draftWrite;
      final online = await WeeklyAssessmentApi.save(widget.dueDate, _answers);
      if (!mounted) return;
      CheckInStateCoordinator.instance.markChanged(this);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(
            online
                ? 'Weekly log saved.'
                : 'Weekly log saved offline and queued to sync.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: LocalizedText(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Weekly log')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LocalizedText('Think about the past seven days.'),
          const SizedBox(height: 8),
          const LocalizedText(
            '11 reflection questions: 5 exhaustion, 3 detachment, and 3 accomplishment. Your daily check-in has only 9 practical inputs on weekly days.',
          ),
          const SizedBox(height: 8),
          const LocalizedText(
            'Custom Maslach-based reflection. This is an adaptation, not the official MBI or a diagnosis.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final option in kBurnoutBaselineScale)
                LocalizedText('${option.value} · ${option.label}'),
            ],
          ),
          const SizedBox(height: 16),
          LocalizedText('${_answers.length} of $kWeeklyQuestionCount answered'),
          for (final section in kBurnoutWeeklySections) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: LocalizedText(
                section.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final question in section.questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: AbsorbPointer(
                  absorbing: _saving,
                  child: LikertQuestion(
                    question: question.questionText,
                    value: _answers[question.questionKey],
                    options: kBurnoutBaselineScale,
                    onChanged: (value) {
                      setState(() => _answers[question.questionKey] = value);
                      final answers = Map<String, int>.from(_answers);
                      _draftWrite = _draftWrite
                          .catchError((_) {})
                          .then(
                            (_) => WeeklyAssessmentApi.saveDraft(
                              widget.dueDate,
                              answers,
                            ),
                          );
                    },
                  ),
                ),
              ),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving || _answers.length != kWeeklyQuestionCount
                  ? null
                  : _save,
              child: LocalizedText(_saving ? 'Saving...' : 'Save weekly log'),
            ),
          ),
        ],
      ),
    ),
  );
}
