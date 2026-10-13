import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../onboarding/widgets/onboarding_card.dart';
import '../../data/assessment_api.dart';
import '../../data/assessment_models.dart';
import '../../data/assessment_store.dart';
import '../pages/assessment_history_page.dart';
import 'assessment_result_card.dart';

/// Only saved assessments are displayed. Wellness edits never supply a score.
class AssessmentOverviewCard extends StatefulWidget {
  final AssessmentApi? api;
  final int refreshVersion;
  final bool showObservations;
  const AssessmentOverviewCard({
    super.key,
    this.api,
    this.refreshVersion = 0,
    this.showObservations = false,
  });

  @override
  State<AssessmentOverviewCard> createState() => _AssessmentOverviewCardState();
}

class _AssessmentOverviewCardState extends State<AssessmentOverviewCard> {
  List<AssessmentRecord> _records = [];
  int? _userId;
  bool _loading = true;
  bool _offline = false;
  bool _reminder = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AssessmentOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final userId = (await UserSessionController.instance.load()).userId;
    if (!mounted || userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    var records = <AssessmentRecord>[];
    var offline = false;
    try {
      if (widget.showObservations) {
        records = (await (widget.api ?? AssessmentApi.instance).history(
          userId,
        )).assessments;
      } else {
        final latest = await (widget.api ?? AssessmentApi.instance).latest(
          userId,
        );
        if (latest != null) records = [latest];
      }
      await AssessmentStore.instance.cacheLatest(userId, records.firstOrNull);
    } catch (_) {
      offline = true;
      final cached = await AssessmentStore.instance.latest(userId);
      if (cached != null) records = [cached];
    }
    final activeUserId = (await UserSessionController.instance.load()).userId;
    if (!mounted || request != _request || activeUserId != userId) {
      return;
    }
    setState(() {
      _userId = userId;
      _records = records;
      _loading = false;
      _offline = offline;
      _reminder =
          prefs.getBool('cbi_assessment_v1_${userId}_reminder') ?? false;
    });
  }

  Future<void> _openHistory() async {
    if (_userId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssessmentHistoryPage(userId: _userId!),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final latest = _records.firstOrNull;
    final reminderDue =
        _reminder &&
        latest != null &&
        DateTime.now().difference(latest.completedAt).inDays >= 30;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const OnboardingCard(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (latest != null)
          AssessmentResultCard(assessment: latest)
        else
          const OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exhaustion assessment — CBI Personal Burnout'),
                SizedBox(height: 8),
                Text(
                  'No completed assessment yet. You can keep recording your daily wellness.',
                ),
              ],
            ),
          ),
        if (_offline)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Offline or unavailable. Showing the last saved assessment, if available.',
            ),
          ),
        if (widget.showObservations && _records.isNotEmpty)
          OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recorded CBI observations'),
                const Text(
                  'Each dot is a completed assessment. Dates without an assessment have no score. Changes are not clinical conclusions.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _AssessmentDots(
                      _records,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ..._records
                    .take(5)
                    .map(
                      (record) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${DateFormat('MMM d, yyyy · h:mm a', 'en').format(record.completedAt.toLocal())} · ${record.displayScore} / 100',
                        ),
                      ),
                    ),
                if (_records.length > 5)
                  Text(
                    '${_records.length} observations shown; open history for all dates.',
                  ),
              ],
            ),
          ),
        if (reminderDue)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Your last assessment was at least 30 days ago. Retake it if useful to you; daily logging remains available.',
            ),
          ),
        TextButton.icon(
          onPressed: _loading ? null : _openHistory,
          icon: const Icon(Icons.history),
          label: const Text('Assessment and history'),
        ),
        if (latest != null)
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text('Show a reassessment reminder after 30 days'),
            subtitle: const Text(
              'Optional app schedule, not a clinical interval.',
            ),
            value: _reminder,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              if ((await UserSessionController.instance.load()).userId !=
                  _userId) {
                return;
              }
              await prefs.setBool(
                'cbi_assessment_v1_${_userId}_reminder',
                value,
              );
              if (mounted) setState(() => _reminder = value);
            },
          ),
      ],
    );
  }
}

class _AssessmentDots extends CustomPainter {
  final List<AssessmentRecord> records;
  final Color color;
  _AssessmentDots(this.records, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final times = records
        .map((record) => record.completedAt.millisecondsSinceEpoch.toDouble())
        .toList();
    final first = times.reduce((a, b) => a < b ? a : b);
    final last = times.reduce((a, b) => a > b ? a : b);
    final paint = Paint()..color = color;
    for (final value in [0, 50, 100]) {
      final label = TextPainter(
        text: TextSpan(
          text: '$value',
          style: TextStyle(color: color, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(0, 8 + (100 - value) / 100 * (size.height - 24)),
      );
    }
    for (final record in records) {
      final x = last == first
          ? 0.5
          : (record.completedAt.millisecondsSinceEpoch - first) /
                (last - first);
      final score = double.parse(record.displayScore);
      canvas.drawCircle(
        Offset(
          32 + x * (size.width - 42),
          12 + (100 - score) / 100 * (size.height - 24),
        ),
        4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AssessmentDots oldDelegate) =>
      oldDelegate.records != records || oldDelegate.color != color;
}
