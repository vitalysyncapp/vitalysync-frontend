import 'dart:math';
import '../../../shared/preferences/user_session.dart';
import 'assessment_api.dart';
import 'assessment_models.dart';
import 'assessment_store.dart';

typedef AssessmentSubmitter =
    Future<Map<String, dynamic>> Function(
      int userId,
      PendingAssessment pending,
    );

class AssessmentSyncService {
  static final instance = AssessmentSyncService();
  final AssessmentStore store;
  final AssessmentSubmitter _submit;
  final Future<int?> Function() _currentUser;
  final Future<AssessmentRecord?> Function(int) _latest;
  final Map<int, Future<void>> _running = {};

  AssessmentSyncService({
    AssessmentStore? store,
    AssessmentSubmitter? submitter,
    Future<int?> Function()? currentUser,
    Future<AssessmentRecord?> Function(int)? latest,
  }) : store = store ?? AssessmentStore.instance,
       _submit =
           submitter ??
           ((id, pending) => AssessmentApi.instance.submit(
             id,
             pending.submission,
             profile: pending.onboardingProfile,
           )),
       _currentUser =
           currentUser ??
           (() async => (await UserSessionController.instance.load()).userId),
       _latest = latest ?? AssessmentApi.instance.latest;

  Future<void> sync(int userId, {bool force = false}) {
    return _running.putIfAbsent(
      userId,
      () => _sync(userId, force: force).whenComplete(() {
        _running.remove(userId);
      }),
    );
  }

  Future<void> _sync(int userId, {required bool force}) async {
    if (await _currentUser() != userId) return;
    for (final pending in await store.pending(userId)) {
      // Onboarding is retried explicitly from onboarding so profile application
      // and navigation cannot be completed behind the user's current screen.
      if (pending.onboardingProfile != null || pending.error != null) continue;
      if (!force && pending.retryAt?.isAfter(DateTime.now()) == true) continue;
      if (await _currentUser() != userId) return;
      try {
        await _submit(userId, pending);
        if (await _currentUser() != userId) return;
        await store.updatePending(userId, pending.submission.id, remove: true);
      } on AssessmentApiException catch (error) {
        if (await _currentUser() != userId) return;
        if (error.status == 401 || error.status == 403) return;
        if (error.status >= 400 && error.status < 500 && error.status != 429) {
          await store.updatePending(
            userId,
            pending.submission.id,
            error: error.message,
          );
          continue;
        }
        await _backoff(userId, pending);
        return;
      } catch (_) {
        if (await _currentUser() == userId) await _backoff(userId, pending);
        return;
      }
    }
    // A successful upload is not necessarily the latest completed assessment.
    try {
      final latest = await _latest(userId);
      if (await _currentUser() == userId) {
        await store.cacheLatest(userId, latest);
      }
    } catch (_) {
      /* Retain the previously dated server result while offline. */
    }
  }

  Future<void> _backoff(int userId, PendingAssessment pending) =>
      store.updatePending(
        userId,
        pending.submission.id,
        attempts: pending.attempts + 1,
        retryAt: DateTime.now().add(
          Duration(
            seconds: min(900, 5 * pow(2, min(pending.attempts, 8))).toInt(),
          ),
        ),
      );
}
