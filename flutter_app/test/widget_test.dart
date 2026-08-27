import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_accounting/main.dart';

void main() {
  testWidgets('Accounting App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AccountingErpApp());
    expect(find.byType(AccountingErpApp), findsOneWidget);
  });
}
