import '../../../onboarding/data/pending_baseline_refresh_store.dart';
import '../../../profile/presentation/pages/history_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../onboarding/widgets/onboarding_card.dart';
import '../../data/assessment_api.dart';
import '../../data/assessment_models.dart';
import '../../data/assessment_store.dart';
import '../../data/assessment_sync_service.dart';
import '../widgets/assessment_result_card.dart';
import 'assessment_page.dart';

class AssessmentHistoryPage extends StatefulWidget {
  final int userId;
  const AssessmentHistoryPage({super.key, required this.userId});
  @override
  State<AssessmentHistoryPage> createState() => _AssessmentHistoryPageState();
}

class _AssessmentHistoryPageState extends State<AssessmentHistoryPage> {
  final _store = AssessmentStore.instance;
  List<AssessmentRecord> _records = [];
  List<PendingAssessment> _pending = [];
  String? _cursor;
  String? _message;
  bool _loading = true;
  PendingBaselineRefresh? _legacyPending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if ((await UserSessionController.instance.load()).userId !=
          widget.userId) {
        return;
      }
      if (!more) {
        // Show saved state before attempting network work.
        _pending = await _store.pending(widget.userId);
        _legacyPending = await PendingBaselineRefreshStore.instance.read(
          widget.userId,
        );
        final cached = await _store.latest(widget.userId);
        if (_records.isEmpty && cached != null) _records = [cached];
        if (mounted) setState(() {});
        if (cbiAssessmentEnabled) {
          await AssessmentSyncService.instance.sync(widget.userId, force: true);
        }
        _pending = await _store.pending(widget.userId);
      }
      final history = await AssessmentApi.instance.history(
        widget.userId,
        cursor: more ? _cursor : null,
      );
      if (!mounted ||
          (await UserSessionController.instance.load()).userId !=
              widget.userId) {
        return;
      }
      _records = more
          ? [..._records, ...history.assessments]
          : history.assessments;
      _cursor = history.nextCursor;
      if (!more) {
        await _store.cacheLatest(
          widget.userId,
          history.assessments.firstOrNull,
        );
      }
    } catch (_) {
      _message =
          'Unable to refresh history. Saved results retain their original completion dates. Pending assessments stay on this device.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retake() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AssessmentPage(userId: widget.userId)),
    );
    if (mounted) await _load();
  }

  Future<void> _discard(PendingAssessment pending) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard pending assessment?'),
        content: const Text(
          'This removes the pending copy from this device. A result already saved on the server remains in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep pending'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard != true) return;
    try {
      await _store.updatePending(
        widget.userId,
        pending.submission.id,
        remove: true,
      );
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _message = 'Unable to remove the pending copy. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Assessment history')),
    body: Container(
      decoration: buildPageDecoration(context),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              FilledButton.icon(
                onPressed: _loading || !cbiAssessmentEnabled ? null : _retake,
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Take exhaustion assessment'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HistoryPage(showLegacy: true),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Legacy composite history (not CBI)'),
              ),
              if (_legacyPending != null)
                OnboardingCard(
                  child: Text(
                    'Legacy pending baseline from ${_legacyPending!.baselineDate}. This method is retired. These saved answers cannot be submitted as CBI. You can start a new CBI assessment; daily logging remains available.',
                  ),
                ),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_message!),
                ),
              if (_pending.isNotEmpty) ...[
                TextButton.icon(
                  onPressed: _loading || !cbiAssessmentEnabled
                      ? null
                      : () => _load(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Retry pending sync'),
                ),
                for (final pending in _pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OnboardingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pending.error == null
                                ? 'Completed on this device · Pending sync'
                                : 'Pending assessment · Needs review',
                          ),
                          Text(
                            DateFormat(
                              'MMM d, yyyy · h:mm a',
                              'en',
                            ).format(pending.submission.completedAt.toLocal()),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pending.error ??
                                'Your score will appear after the server accepts this assessment.',
                          ),
                          if (pending.error != null)
                            const Text(
                              'This request cannot be retried automatically. Keep it for review or discard the local copy and start a new assessment.',
                            ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _discard(pending),
                            child: const Text('Discard pending copy'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (!_loading && _records.isEmpty)
                const Text(
                  'No completed CBI assessment is available. Legacy baseline results remain in your existing history.',
                ),
              for (final record in _records)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AssessmentResultCard(assessment: record),
                ),
              if (_cursor != null)
                OutlinedButton(
                  onPressed: _loading ? null : () => _load(more: true),
                  child: const Text('Load earlier assessments'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
