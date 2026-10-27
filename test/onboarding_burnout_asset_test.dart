import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('burnout SVG is bundled and renders from the real asset bundle', (
    tester,
  ) async {
    const asset = 'assets/images/onboarding_burnout.svg';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    expect(manifest.listAssets(), contains(asset));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SvgPicture.asset(asset))),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
