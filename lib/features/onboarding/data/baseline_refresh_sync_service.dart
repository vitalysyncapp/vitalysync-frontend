import '../../dashboard/data/burnout_score_api.dart';
import '../services/onboarding_service.dart';
import 'onboarding_api.dart';
import 'pending_baseline_refresh_store.dart';

enum BaselineRefreshSyncState { nothingPending, synced, queued, needsAttention }

typedef BaselineRefreshSubmitter =
    Future<Map<String, dynamic>> Function(PendingBaselineRefresh pending);
typedef BaselineRefreshResponseApplier =
    Future<void> Function(Map<String, dynamic> response);

class BaselineRefreshSyncService {
  BaselineRefreshSyncService({
    PendingBaselineRefreshStore store = PendingBaselineRefreshStore.instance,
    BaselineRefreshSubmitter? submitter,
    BaselineRefreshResponseApplier? responseApplier,
  }) : _store = store,
       _submitter = submitter ?? _submit,
       _responseApplier = responseApplier ?? _applyResponse;

  static final instance = BaselineRefreshSyncService();

  final PendingBaselineRefreshStore _store;
  final BaselineRefreshSubmitter _submitter;
  final BaselineRefreshResponseApplier _responseApplier;

  Future<BaselineRefreshSyncState> saveOrQueue({
    required int userId,
    required List<Map<String, dynamic>> answers,
    required String baselineDate,
  }) async {
    await _store.queue(
      userId: userId,
      answers: answers,
      baselineDate: baselineDate,
    );
    return syncPending(userId);
  }

  Future<BaselineRefreshSyncState> syncPending(int userId) async {
    final pending = await _store.read(userId);
    if (pending == null) return BaselineRefreshSyncState.nothingPending;
    if (pending.needsAttention) {
      return BaselineRefreshSyncState.needsAttention;
    }

    try {
      final response = await _submitter(pending);
      await _responseApplier(response);
      await _store.clear(userId);
      return BaselineRefreshSyncState.synced;
    } on OnboardingApiException catch (error) {
      if (error.statusCode >= 400 && error.statusCode < 500) {
        await _store.markNeedsAttention(pending, error.message);
        return BaselineRefreshSyncState.needsAttention;
      }
      return BaselineRefreshSyncState.queued;
    } catch (_) {
      return BaselineRefreshSyncState.queued;
    }
  }

  static Future<Map<String, dynamic>> _submit(PendingBaselineRefresh pending) {
    return OnboardingApi.updateBurnoutBaseline(
      userId: pending.userId,
      burnoutAnswers: pending.answers,
      baselineDate: pending.baselineDate,
      clientRefreshId: pending.clientRefreshId,
    );
  }

  static Future<void> _applyResponse(Map<String, dynamic> response) async {
    final profile = response['profile'];
    if (profile is Map) {
      await OnboardingService.saveDefaultsFromProfile(
        Map<String, dynamic>.from(profile),
      );
    }
    final latestScore = response['latest_score'];
    await BurnoutScoreApi.markInputsChanged(
      latestScore: latestScore is Map
          ? Map<String, dynamic>.from(latestScore)
          : null,
      clearLatestScore: latestScore is! Map,
    );
  }
}
