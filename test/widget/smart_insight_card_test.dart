import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clear_health/widgets/smart_insight_card.dart';
import 'package:clear_health/core/providers/lab_providers.dart';

void main() {
  /*
  testWidgets('SmartInsightCard displays predictions when data is available', (
    WidgetTester tester,
  ) async {
    final List<Map<String, dynamic>> mockPredictions = [
      {
        'metric': 'Hemoglobin',
        'current_value': '13.5',
        'predicted_value': '14.0',
        'trend_direction': 'Increasing',
        'risk_level': 'Low',
        'insight': 'Levels are improving.',
        'recommendation': 'Keep eating iron-rich foods.',
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthPredictionsProvider.overrideWith((ref) => mockPredictions),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 600, child: SmartInsightCard()),
            ),
          ),
        ),
      ),
    );

    // Wait for Future to complete
    await tester.pumpAndSettle();

    // Verify content
    expect(find.text('AI Health Forecast'), findsOneWidget);
    expect(find.text('Hemoglobin'), findsOneWidget);
    expect(find.text('13.5'), findsOneWidget);
    expect(find.text('Low Risk'), findsOneWidget);
    expect(find.text('Keep eating iron-rich foods.'), findsOneWidget);
  });
*/

  testWidgets('SmartInsightCard shows loading indicator', (
    WidgetTester tester,
  ) async {
    // We can't easily force a loading state with FutureProvider.overrideWith unless we use a Completer
    // or just checking the initial state before pumpAndSettle might work if the Future is delayed.
    // However, simplest way to test loading widget structure is just forcing a loading AsyncValue if we could,
    // but FutureProvider makes that hard without mocking the underlying service call delay.
    // So we'll simulate a long-running future.

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthPredictionsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(seconds: 1));
            return [];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 600, child: SmartInsightCard()),
            ),
          ),
        ),
      ),
    );

    await tester.pump(); // Start the future

    // Should be loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Finish
    await tester.pumpAndSettle();
  });

  testWidgets('SmartInsightCard hides when data is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthPredictionsProvider.overrideWith((ref) => [])],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 600, child: SmartInsightCard()),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should find nothing (SizedBox.shrink)
    expect(find.text('AI Health Forecast'), findsNothing);
  });
}
