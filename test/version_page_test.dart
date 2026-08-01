import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vitalysync/features/settings/presentation/pages/version_page.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'VitalySync',
      packageName: 'com.example.vitalysync',
      version: '2.3.4',
      buildNumber: '56',
      buildSignature: '',
    );
  });

  testWidgets('shows installed build details and academic testing status', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: VersionPage()));
    await tester.pumpAndSettle();

    expect(find.text('Version 2.3.4'), findsOneWidget);
    expect(find.textContaining('Build 56'), findsOneWidget);
    expect(find.text('Academic testing'), findsOneWidget);
    expect(find.text('Testing build'), findsOneWidget);
    expect(
      find.text('More dependable loading and clearer offline updates.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains scrollable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: VersionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latest updates'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
