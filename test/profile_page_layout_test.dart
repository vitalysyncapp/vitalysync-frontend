import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/profile/presentation/pages/profile_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('profile header stays polished on a compact light layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpProfile(
      tester,
      brightness: Brightness.light,
      size: const Size(320, 900),
      textScaler: const TextScaler.linear(1.2),
    );

    final header = tester.widget<Container>(
      find.byKey(const ValueKey('profile-header-card')),
    );
    final decoration = header.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, const [
      Color(0xFFF9FFFC),
      Color(0xFFECF8F5),
      Color(0xFFEEF6FF),
    ]);
    expect(find.text('Cinnamon'), findsOneWidget);
    expect(find.text('Working Professional'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-email-verify-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-email-verified-badge')),
      findsNothing,
    );
    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('14 days'), findsOneWidget);
    expect(find.text('23 yrs'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-header-avatar-edit')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('profile-header-card'))).width,
      288,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile header uses its calm dark palette without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpProfile(
      tester,
      brightness: Brightness.dark,
      size: const Size(390, 844),
    );

    final header = tester.widget<Container>(
      find.byKey(const ValueKey('profile-header-card')),
    );
    final decoration = header.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, const [
      Color(0xFF152738),
      Color(0xFF17363F),
      Color(0xFF1D3047),
    ]);
    expect(find.text('Cinnamon'), findsOneWidget);
    expect(find.text('Working Professional'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile header shows a verified email badge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpProfile(
      tester,
      brightness: Brightness.light,
      size: const Size(390, 844),
      emailVerified: true,
    );

    expect(
      find.byKey(const ValueKey('profile-email-verified-badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-email-verify-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile verify button opens the email verification page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpProfile(
      tester,
      brightness: Brightness.light,
      size: const Size(390, 844),
    );

    await tester.tap(find.byKey(const ValueKey('profile-email-verify-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('email-verification-page-card')),
      findsOneWidget,
    );
    expect(find.text('Verify your email'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('send-email-verification-button')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required Brightness brightness,
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
  bool emailVerified = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'username': 'Cinnamon',
    'email': 'estoce.orlan@gmail.com',
    'email_verified': emailVerified,
    'age': 23,
    'gender': 'Male',
    'user_type': 'Working Professional',
    'log_streak': 3,
    'longest_log_streak': 14,
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: textScaler,
        ),
        child: const ProfilePage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 950));
}
