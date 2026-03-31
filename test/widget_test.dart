import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bikepool/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: BikePoolApp()));
    await tester.pumpAndSettle();

    // Verify that the app builds without crashing.
    expect(find.byType(BikePoolApp), findsOneWidget);
  });
}
