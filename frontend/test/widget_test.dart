import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const WordLegendApp());

    expect(find.byType(WordLegendApp), findsOneWidget);
  });
}
