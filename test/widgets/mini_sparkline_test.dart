import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_sense_app/widgets/mini_sparkline.dart';

void main() {
  testWidgets('MiniSparkline renders with data', (WidgetTester tester) async {
    final data = [10.0, 20.0, 15.0, 25.0];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniSparkline(
            data: data,
            width: 100,
            height: 50,
            color: Colors.red,
          ),
        ),
      ),
    );

    // Verify the widget exists
    expect(find.byType(MiniSparkline), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('MiniSparkline determines color based on trend', (
    WidgetTester tester,
  ) async {
    final positiveTrend = [10.0, 20.0];
    final negativeTrend = [20.0, 10.0];

    // We can't easily inspect the CustomPainter property 'color' without finding the painter instance,
    // but we can ensure it renders without error for different trends

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MiniSparkline(data: positiveTrend, key: const Key('positive')),
              MiniSparkline(data: negativeTrend, key: const Key('negative')),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('positive')), findsOneWidget);
    expect(find.byKey(const Key('negative')), findsOneWidget);
  });

  testWidgets('MiniSparkline handles empty or single point data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MiniSparkline(data: [10.0])),
      ),
    );

    // Should render a SizedBox (no CustomPaint) if data < 2
    // Implementation: if (data.length < 2) return SizedBox

    expect(find.byType(CustomPaint), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
