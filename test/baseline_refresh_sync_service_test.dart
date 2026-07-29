import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/onboarding/data/baseline_refresh_sync_service.dart';
import 'package:vitalysync/features/onboarding/data/onboarding_api.dart';
import 'package:vitalysync/features/onboarding/data/pending_baseline_refresh_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pending baseline queue stores only normalized replay fields', () async {
    final store = PendingBaselineRefreshStore.instance;
    final pending = await store.queue(
      userId: 7,
      answers: const [
        {
          'question_key': 'ee_01',
          'numeric_value': 3,
          'question_text': 'Sensitive question text',
        },
      ],
      baselineDate: '2026-07-29',
      now: DateTime.utc(2026, 7, 29, 8),
    );

    expect(pending.answers, const [
      {'question_key': 'ee_01', 'numeric_value': 3},
    ]);
    expect(pending.clientRefreshId, startsWith('refresh_7_'));
    expect((await store.read(7))?.baselineDate, '2026-07-29');
  });

  test('pending baseline queue expires after seven days', () async {
    final store = PendingBaselineRefreshStore.instance;
    await store.queue(
      userId: 7,
      answers: const [
        {'question_key': 'ee_01', 'numeric_value': 3},
      ],
      baselineDate: '2026-07-20',
      now: DateTime.utc(2026, 7, 20),
    );

    expect(await store.read(7, now: DateTime.utc(2026, 7, 27)), isNull);
  });

  test('successful baseline replay clears the queue', () async {
    PendingBaselineRefresh? submitted;
    var applied = false;
    final service = BaselineRefreshSyncService(
      submitter: (pending) async {
        submitted = pending;
        return {'profile': <String, dynamic>{}, 'latest_score': null};
      },
      responseApplier: (_) async => applied = true,
    );

    final state = await service.saveOrQueue(
      userId: 7,
      answers: const [
        {'question_key': 'ee_01', 'numeric_value': 3},
      ],
      baselineDate: '2026-07-29',
    );

    expect(state, BaselineRefreshSyncState.synced);
    expect(submitted?.baselineDate, '2026-07-29');
    expect(submitted?.clientRefreshId, isNotEmpty);
    expect(applied, isTrue);
    expect(await PendingBaselineRefreshStore.instance.read(7), isNull);
  });

  test('transient baseline replay failure keeps the queue retryable', () async {
    final service = BaselineRefreshSyncService(
      submitter: (_) async => throw Exception('offline'),
      responseApplier: (_) async {},
    );

    final state = await service.saveOrQueue(
      userId: 7,
      answers: const [
        {'question_key': 'ee_01', 'numeric_value': 3},
      ],
      baselineDate: '2026-07-29',
    );

    expect(state, BaselineRefreshSyncState.queued);
    expect(
      (await PendingBaselineRefreshStore.instance.read(7))?.needsAttention,
      isFalse,
    );
  });

  test('non-retryable baseline failure is marked for user attention', () async {
    final service = BaselineRefreshSyncService(
      submitter: (_) async =>
          throw const OnboardingApiException('Invalid baseline', 400),
      responseApplier: (_) async {},
    );

    final state = await service.saveOrQueue(
      userId: 7,
      answers: const [
        {'question_key': 'ee_01', 'numeric_value': 3},
      ],
      baselineDate: '2026-07-29',
    );

    final pending = await PendingBaselineRefreshStore.instance.read(7);
    expect(state, BaselineRefreshSyncState.needsAttention);
    expect(pending?.needsAttention, isTrue);
    expect(pending?.lastError, 'Invalid baseline');
  });
}
