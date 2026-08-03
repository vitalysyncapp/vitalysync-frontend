import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('overlay bubble omits the square-producing outer shadow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        color: Colors.transparent,
        home: ColoredBox(
          color: Colors.transparent,
          child: Center(
            child: SizedBox.square(
              dimension: 58,
              child: AssistantFloatingBubbleVisual(showOuterShadow: false),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final decorationContainer = tester.widget<Container>(
      find.byKey(const ValueKey('assistant-floating-bubble-decoration')),
    );
    final decoration = decorationContainer.decoration! as BoxDecoration;

    expect(decoration.shape, BoxShape.circle);
    expect(decoration.boxShadow, isNull);
    expect(tester.takeException(), isNull);
  });
}
