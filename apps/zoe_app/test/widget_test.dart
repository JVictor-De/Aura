import 'package:flutter_test/flutter_test.dart';

import 'package:zoe_app/app.dart';

void main() {
  testWidgets('Zoe app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZoeApp());
    expect(find.text('ZOE'), findsWidgets);
  });
}
