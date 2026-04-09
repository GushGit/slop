// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:slop/main.dart';

void main() {
  testWidgets('Bottom tabs are visible and refrigerator tab opens', (WidgetTester tester) async {
    await tester.pumpWidget(const ReciperApp());
    await tester.pumpAndSettle();

    expect(find.text('Рецепты'), findsWidgets);
    expect(find.text('Холодильник'), findsWidgets);
    expect(find.text('Цели'), findsWidgets);
    expect(find.text('Настройки'), findsWidgets);

    await tester.tap(find.text('Холодильник').first);
    await tester.pumpAndSettle();

    expect(find.text('Электронный холодильник'), findsWidgets);
  });
}
