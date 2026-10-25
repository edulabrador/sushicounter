import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Settings is a scrolling list; bring a row into view before tapping it.
Future<void> tapSetting(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
}
