import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/home/presentation/widgets/home_header.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('home header fits its controls on a compact screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'username': 'Alex Rivera',
      'log_streak': 4,
    });

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en', 'US'),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: Size(320, 720), disableAnimations: true),
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 296, child: HomeHeader()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-header')), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('4 days'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_rounded), findsNothing);
    expect(find.byKey(const ValueKey('home-header-logo')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-header-time-indicator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-header-notifications')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-header-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-header-streak')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-header-avatar'))),
      const Size.square(40),
    );
    expect(tester.takeException(), isNull);
  });
}
