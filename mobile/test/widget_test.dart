import 'package:flutter_test/flutter_test.dart';
import 'package:p3h_mobile/main.dart';

void main() {
  testWidgets('P3HApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const P3HApp());
    expect(find.byType(P3HApp), findsOneWidget);
  });
}
