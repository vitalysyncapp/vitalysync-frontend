import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/home/presentation/widgets/environmental_card.dart';

void main() {
  testWidgets('error state only shows the short unavailable message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EnvironmentalCard(
            snapshot: null,
            isLoading: false,
            hasError: true,
          ),
        ),
      ),
    );

    expect(find.text('Environment data is unavailable'), findsOneWidget);
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.textContaining('/api/environment'), findsNothing);
  });
}
