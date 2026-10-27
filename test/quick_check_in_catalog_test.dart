import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/quick_check_in_preset.dart';
import 'package:vitalysync/features/log/presentation/widgets/quick_check_in_preset_widgets.dart';
import 'package:vitalysync/shared/widgets/app_skeleton.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('catalog uses three columns and filters to the required mode', (
    tester,
  ) async {
    await _pumpCatalog(tester, mode: CheckInMode.daily);

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(find.text('Productive'), findsOneWidget);
    expect(find.text('Weekly reset'), findsNothing);
    expect(find.byKey(const ValueKey('add-quick-check-in')), findsOneWidget);
  });

  testWidgets('tap requests preview and long press opens preset management', (
    tester,
  ) async {
    QuickCheckInPreset? tapped;
    QuickCheckInPreset? held;
    await _pumpCatalog(
      tester,
      mode: CheckInMode.daily,
      onTap: (preset) => tapped = preset,
      onLongPress: (preset) => held = preset,
    );

    final tile = find.byKey(const ValueKey('quick-preset-1'));
    await tester.tap(tile);
    expect(tapped?.name, 'Productive');

    await tester.longPress(tile);
    expect(held?.presetId, 1);
  });

  testWidgets('catalog uses themed skeleton tiles while presets load', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: SizedBox(
          width: 390,
          height: 720,
          child: QuickCheckInCatalog(
            mode: CheckInMode.daily,
            presets: const [],
            isLoading: true,
            isStale: false,
            activePresetId: null,
            onPresetTap: (_) {},
            onPresetLongPress: (_) {},
            onAdd: () {},
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

Future<void> _pumpCatalog(
  WidgetTester tester, {
  required CheckInMode mode,
  ValueChanged<QuickCheckInPreset>? onTap,
  ValueChanged<QuickCheckInPreset>? onLongPress,
}) {
  return pumpTestApp(
    tester,
    Scaffold(
      body: SizedBox(
        width: 390,
        height: 720,
        child: QuickCheckInCatalog(
          mode: mode,
          presets: const [_dailyPreset, _weeklyPreset],
          isLoading: false,
          isStale: false,
          activePresetId: null,
          onPresetTap: onTap ?? (_) {},
          onPresetLongPress: onLongPress ?? (_) {},
          onAdd: () {},
          onRetry: () {},
        ),
      ),
    ),
  );
}

const _draft = CheckInDraft(
  sleepHours: 7,
  sleepQuality: 3,
  moodIndex: 4,
  energyLevel: 4,
  hydrationLiters: 2,
  workloadHoursBand: '5-6 hours',
  exerciseNames: {'Walking'},
  symptomNames: {'None'},
  habitNames: {'Quiet break'},
  perceivedPressureLevel: 3,
  recoveryRestLevel: 4,
  detachmentLevel: 2,
  productivityFocusLevel: 4,
  accomplishmentLevel: 5,
);

const _dailyPreset = QuickCheckInPreset(
  presetId: 1,
  name: 'Productive',
  mode: CheckInMode.daily,
  avatarId: 'focused',
  draft: _draft,
);

const _weeklyPreset = QuickCheckInPreset(
  presetId: 2,
  name: 'Weekly reset',
  mode: CheckInMode.weekly,
  avatarId: 'calm',
  draft: _draft,
);
