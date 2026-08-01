import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/shared/widgets/validation_dialog.dart';

void main() {
  testWidgets('validation dialog stays usable on a small scaled display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ValidationDialog(
            type: ValidationDialogType.connection,
            duration: Duration(minutes: 1),
            message:
                'We could not connect right now. Check your connection and try again when you are ready.',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
