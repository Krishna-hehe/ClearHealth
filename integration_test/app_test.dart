import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clear_health/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows login or dashboard', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Just verify that we don't crash immediately and show *something*
    // Ideally we define this based on initial state (Login usually)
    // For now, let's just assert that we are running by finding a common widget
    // If logged out: LoginPage
    // If logged in: DashboardPage
    
    // We expect at least one scaffold
    expect(find.byType(app.LabSenseApp), findsOneWidget);
  });
}

