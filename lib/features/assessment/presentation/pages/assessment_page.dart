import 'package:flutter/material.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../data/assessment_api.dart';
import '../../data/assessment_models.dart';
import '../../data/assessment_store.dart';
import '../../data/assessment_sync_service.dart';
import '../widgets/assessment_form.dart';
import '../widgets/assessment_result_card.dart';

class AssessmentPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? onboardingProfile;
  const AssessmentPage({
    super.key,
    required this.userId,
    this.onboardingProfile,
  });
  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final _store = AssessmentStore.instance;
  AssessmentDefinition? _definition;
  final Map<String, int> _answers = {};
  PendingAssessment? _pending;
  Map<String, dynamic>? _response;
  String? _message;
  bool _loading = true;
  bool _saving = false;
  bool _queued = false;
  bool get _onboarding => widget.onboardingProfile != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _active() async =>
      mounted &&
      (await UserSessionController.instance.load()).userId == widget.userId;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (!await _active()) return;
      if (!cbiAssessmentEnabled) {
        _message = 'Assessment submission is not enabled in this build.';
        return;
      }
      if (_onboarding) {
        final pending = await _store.pending(widget.userId);
        _pending = pending
            .where((item) => item.onboardingProfile != null)
            .firstOrNull;
        if (_pending != null) {
          _queued = true;
          return;
        }
      }
      final draft = await _store.draft(widget.userId, onboarding: _onboarding);
      if (draft != null) {
        _definition = draft.definition;
        _answers.addAll(draft.answers);
      } else {
        try {
          final definition = await AssessmentApi.instance.definition(
            widget.userId,
          );
          if (!await _active()) return;
          await _store.cacheDefinition(widget.userId, definition);
          _definition = definition;
        } catch (_) {
          _definition = await _store.definition(widget.userId);
          if (_definition == null) rethrow;
          _message =
              'Using the saved English assessment. You can complete it offline and sync later.';
        }
      }
    } catch (_) {
      _message =
          'The assessment could not be loaded. Connect to the internet and try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _answer(String id, int? value) async {
    setState(() {
      if (value == null) {
        _answers.remove(id);
      } else {
        _answers[id] = value;
      }
    });
    try {
      if (await _active()) {
        await _store.saveDraft(
          widget.userId,
          _definition!,
          _answers,
          onboarding: _onboarding,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'This draft could not be saved on your device. Keep this screen open and try again.',
        );
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      if (!await _active()) return;
      _pending ??= PendingAssessment(
        AssessmentSubmission.create(_definition!, _answers),
        onboardingProfile: widget.onboardingProfile,
      );
      await _store.queue(widget.userId, _pending!);
      _queued = true;
      await _store.clearDraft(widget.userId, onboarding: _onboarding);
      if (_onboarding) {
        final response = await AssessmentApi.instance.submit(
          widget.userId,
          _pending!.submission,
          profile: _pending!.onboardingProfile,
        );
        if (!await _active()) return;
        // Keep the exact pending request until Continue. If the app closes here,
        // replay retrieves the same result and completes local onboarding setup.
        setState(() => _response = response);
      } else {
        await AssessmentSyncService.instance.sync(widget.userId, force: true);
        if (mounted) Navigator.pop(context, true);
      }
    } on AssessmentApiException catch (error) {
      if (mounted) {
        setState(
          () => _message =
              '${error.message} Your completed assessment is saved on this device.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = _queued
              ? 'Unable to sync now. Your completed assessment is saved on this device. Retry when connected.'
              : 'Unable to save this assessment on your device. Keep this screen open and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      if (!await _active()) return;
      await _store.updatePending(
        widget.userId,
        _pending!.submission.id,
        remove: true,
      );
      if (mounted) Navigator.pop(context, _response);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Unable to finish on this device. Please try again.';
        });
      }
    }
  }

  Future<void> _startAgain() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new assessment?'),
        content: const Text(
          'This removes the pending copy from this device. If it already reached the server, its saved result stays in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep pending'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start again'),
          ),
        ],
      ),
    );
    if (discard != true || !await _active()) return;
    try {
      await _store.updatePending(
        widget.userId,
        _pending!.submission.id,
        remove: true,
      );
      _pending = null;
      _queued = false;
      _definition = null;
      _answers.clear();
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Unable to remove the local pending copy. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Exhaustion assessment')),
      body: Container(
        decoration: buildPageDecoration(context),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(_message!, semanticsLabel: _message),
                        ),
                      if (_response != null) ...[
                        AssessmentResultCard(
                          assessment: AssessmentRecord.fromJson(
                            Map<String, dynamic>.from(
                              _response!['assessment'] as Map,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : _continue,
                          child: const Text('Continue'),
                        ),
                      ] else if (_pending != null) ...[
                        const Text('Completed on this device · Pending sync'),
                        const SizedBox(height: 12),
                        const Text(
                          'Retry sends the same completed answers and profile. Your score will appear after the server accepts them.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(_saving ? 'Syncing…' : 'Retry sync'),
                        ),
                        TextButton(
                          onPressed: _saving ? null : _startAgain,
                          child: const Text('Start again'),
                        ),
                      ] else if (_definition != null) ...[
                        AbsorbPointer(
                          absorbing: _saving,
                          child: AssessmentForm(
                            definition: _definition!,
                            answers: _answers,
                            onChanged: _answer,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed:
                              !_saving && _definition!.isComplete(_answers)
                              ? _submit
                              : null,
                          child: Text(
                            _saving ? 'Saving…' : 'Complete assessment',
                          ),
                        ),
                        if (!_definition!.isComplete(_answers))
                          const Text(
                            'Answer all six required CBI questions to continue.',
                          ),
                      ] else
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    ),
  );
}
