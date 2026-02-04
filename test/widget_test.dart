import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restro/app/app.dart';

void main() {
  testWidgets('RestroPOS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RestroPosApp(),
      ),
    );

    // Verify that the login screen is displayed
    expect(find.text('Enter the Passcode to access this Billing Station'), findsOneWidget);
  });
}
