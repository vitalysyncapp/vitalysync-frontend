import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/shared/widgets/analytics_animation.dart';

void main() {
  testWidgets('can replace a loader without overlaying outgoing content', (
    tester,
  ) async {
    var isLoading = true;
    late StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, updateState) {
              setState = updateState;
              return AnalyticsContentSwitcher(
                isLoading: isLoading,
                overlapOutgoing: false,
                loading: const SizedBox(key: ValueKey('loader'), height: 80),
                child: const SizedBox(key: ValueKey('content'), height: 160),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('loader')), findsOneWidget);

    setState(() => isLoading = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('loader')), findsNothing);
    expect(find.byKey(const ValueKey('content')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
