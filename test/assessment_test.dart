import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/assessment/data/assessment_api.dart';
import 'package:vitalysync/features/assessment/data/assessment_models.dart';
import 'package:vitalysync/features/assessment/data/assessment_store.dart';
import 'package:vitalysync/features/assessment/data/assessment_sync_service.dart';
import 'package:vitalysync/features/assessment/presentation/widgets/assessment_form.dart';
import 'package:vitalysync/features/assessment/presentation/widgets/assessment_result_card.dart';
import 'package:vitalysync/features/onboarding/widgets/likert_question.dart';
import 'package:vitalysync/l10n/app_localizations.dart';

final definitionJson = Map<String, dynamic>.from(
  jsonDecode(File('test/fixtures/cbi_definition.json').readAsStringSync())
      as Map,
);
AssessmentDefinition definition() =>
    AssessmentDefinition.fromJson(definitionJson);
Map<String, int> completeAnswers() => {for (var i = 1; i <= 6; i++) 'PB$i': 3};
AssessmentSubmission submission({DateTime? date}) =>
    AssessmentSubmission.create(definition(), completeAnswers(), now: date);
AssessmentRecord record(
  AssessmentSubmission submission, {
  String score = '50.0',
}) => AssessmentRecord.fromJson({
  ...submission.toJson(),
  'assessment_id': '123',
  'completion_status': 'complete',
  'result': {'display_score': score},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'user_id': 1}));

  test(
    'six required responses complete the form while context remains optional and unscored',
    () {
      expect(definition().isComplete({'PB1': 3}), isFalse);
      expect(definition().isComplete(completeAnswers()), isTrue);
      final payload = submission().toJson();
      expect(payload['answers'], hasLength(6));
      expect(payload.containsKey('result'), isFalse);
      expect(payload['language'], 'en');
      expect(payload['submission_id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(
        () => AssessmentSubmission.create(definition(), {'PB1': 3}),
        throwsFormatException,
      );
      expect(
        () => AssessmentSubmission.create(definition(), {
          ...completeAnswers(),
          'context1': 0,
        }),
        throwsFormatException,
      );
    },
  );

  test('unsupported or translated definitions cannot be administered', () {
    expect(
      () =>
          AssessmentDefinition.fromJson({...definitionJson, 'language': 'fil'}),
      throwsFormatException,
    );
    expect(
      () => AssessmentDefinition.fromJson({
        ...definitionJson,
        'translation_allowed': true,
      }),
      throwsFormatException,
    );
    expect(
      () => AssessmentDefinition.fromJson({
        ...definitionJson,
        'presentation_order': [],
      }),
      throwsFormatException,
    );
  });

  test(
    'drafts pin definitions; multiple completed submissions survive restarts and do not expire',
    () async {
      final store = AssessmentStore();
      await store.cacheDefinition(1, definition());
      await store.saveDraft(1, definition(), {'PB1': 2});
      final old = submission(date: DateTime.utc(2025, 1, 1));
      final recent = submission();
      await Future.wait([
        store.queue(1, PendingAssessment(old)),
        store.queue(1, PendingAssessment(recent)),
      ]);
      await store.queue(1, PendingAssessment(old));
      final restored = AssessmentStore();
      expect((await restored.draft(1))!.answers, {'PB1': 2});
      expect((await restored.draft(1))!.definition.toJson(), definitionJson);
      expect((await restored.pending(1)).map((item) => item.submission.id), [
        old.id,
        recent.id,
      ]);
      expect(
        (await restored.pending(1)).first.submission.completedAt,
        DateTime.utc(2025, 1, 1),
      );
      expect(await restored.pending(2), isEmpty);
      await expectLater(
        store.queue(
          1,
          PendingAssessment(
            AssessmentSubmission.fromJson({
              ...old.toJson(),
              'completed_at': DateTime.now().toUtc().toIso8601String(),
            }),
          ),
        ),
        throwsStateError,
      );
      final copy = old.toJson();
      (copy['answers'] as List).clear();
      expect(old.toJson()['answers'], hasLength(6));
    },
  );

  test(
    'retry preserves identifier and completion time after a lost response and caches server latest',
    () async {
      final store = AssessmentStore();
      final old = submission(date: DateTime.utc(2025, 1, 1));
      final newer = submission();
      await store.queue(1, PendingAssessment(old));
      final attempts = <Map<String, dynamic>>[];
      final sync = AssessmentSyncService(
        store: store,
        currentUser: () async => 1,
        submitter: (id, pending) async {
          attempts.add(pending.submission.toJson());
          if (attempts.length == 1) throw TimeoutException('response lost');
          return {'assessment': record(old).toJson()};
        },
        latest: (_) async => record(newer),
      );
      await sync.sync(1);
      expect((await store.pending(1)).single.attempts, 1);
      await sync.sync(1); // Backoff prevents a second upload.
      expect(attempts, hasLength(1));
      await sync.sync(1, force: true);
      expect(attempts[0], attempts[1]);
      expect(await store.pending(1), isEmpty);
      expect((await store.latest(1))!.submissionId, newer.id);
    },
  );

  test('concurrent sync calls send each pending submission once', () async {
    final store = AssessmentStore();
    await store.queue(1, PendingAssessment(submission()));
    final gate = Completer<void>();
    var uploads = 0;
    final sync = AssessmentSyncService(
      store: store,
      currentUser: () async => 1,
      submitter: (_, pending) async {
        uploads++;
        await gate.future;
        return {};
      },
      latest: (_) async => null,
    );
    final first = sync.sync(1);
    final second = sync.sync(1);
    gate.complete();
    await Future.wait([first, second]);
    expect(uploads, 1);
    expect(await store.pending(1), isEmpty);
  });

  test(
    'auth failures pause; validation failures stay visible for review without automatic retry',
    () async {
      final store = AssessmentStore();
      await store.queue(1, PendingAssessment(submission()));
      var status = 401;
      var uploads = 0;
      final sync = AssessmentSyncService(
        store: store,
        currentUser: () async => 1,
        submitter: (_, pending) async {
          uploads++;
          throw AssessmentApiException('Review required', status);
        },
        latest: (_) async => null,
      );
      await sync.sync(1, force: true);
      expect((await store.pending(1)).single.error, isNull);
      status = 422;
      await sync.sync(1, force: true);
      expect((await store.pending(1)).single.error, 'Review required');
      await sync.sync(1, force: true);
      expect(uploads, 2);
    },
  );

  test(
    'onboarding requests remain frozen for explicit retry and are not sent by background sync',
    () async {
      final store = AssessmentStore();
      await store.queue(
        1,
        PendingAssessment(submission(), onboardingProfile: {'role': 'Student'}),
      );
      final sync = AssessmentSyncService(
        store: store,
        currentUser: () async => 1,
        submitter: (_, pending) async =>
            fail('Background onboarding submission'),
        latest: (_) async => null,
      );
      await sync.sync(1, force: true);
      expect((await store.pending(1)).single.onboardingProfile, {
        'role': 'Student',
      });
    },
  );

  test(
    'logout during upload removes all sensitive caches and prevents stale response writes',
    () async {
      final store = AssessmentStore();
      await store.cacheDefinition(1, definition());
      await store.saveDraft(1, definition(), {'PB1': 3});
      await store.queue(1, PendingAssessment(submission()));
      final gate = Completer<void>();
      final started = Completer<void>();
      var userId = 1;
      final sync = AssessmentSyncService(
        store: store,
        currentUser: () async => userId,
        submitter: (_, pending) async {
          started.complete();
          await gate.future;
          return {};
        },
        latest: (_) async => record(submission()),
      );
      final running = sync.sync(1);
      await started.future;
      userId = 2;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await store.clearLocalData();
      gate.complete();
      await running;
      await expectLater(
        store.cacheLatest(1, record(submission())),
        throwsStateError,
      );
      expect(
        prefs.getKeys().where((key) => key.startsWith(AssessmentStore.prefix)),
        isEmpty,
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'English labels and accessible selection at 320px and 200% text in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        int? response;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fil'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: StatefulBuilder(
                    builder: (context, setState) => LikertQuestion(
                      question: definition().items.first.text,
                      value: response,
                      options: definition().options,
                      translate: false,
                      showLegend: true,
                      onChanged: (value) => setState(() => response = value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final option in definition().options) {
          expect(
            find.text('${option.value} = ${option.label}'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel('${option.value} - ${option.label}'),
            findsOneWidget,
          );
        }
        expect(find.text('How often do you feel tired?'), findsOneWidget);
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        expect(response, 1);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('1 - Never/almost never'))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        // Numbered controls are keyboard-operable through InkWell.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'form preserves fixed order and distinguishes optional context; result uses returned score',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AssessmentForm(
                definition: definition(),
                answers: {},
                onChanged: (_, _) {},
              ),
            ),
          ),
        ),
      );
      final widgets = tester
          .widgetList<LikertQuestion>(find.byType(LikertQuestion))
          .toList();
      expect(
        widgets.map((widget) => widget.key),
        definition().items.map((item) => ValueKey(item.id)),
      );
      expect(
        find.text('Lifestyle context · Optional · Not scored'),
        findsNWidgets(4),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssessmentResultCard(
              assessment: record(
                submission(date: DateTime.utc(2026, 10, 1)),
                score: '41.7',
              ),
            ),
          ),
        ),
      );
      expect(find.text('41.7 / 100'), findsOneWidget);
      expect(find.textContaining('Complete ·'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
