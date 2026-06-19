import 'package:flutter_test/flutter_test.dart';
import 'package:agbara_wallet/main.dart';

void main() {
  testWidgets('App renders home tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const AgbaraWalletApp());
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Factory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
