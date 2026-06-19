import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agbara_wallet/main.dart';

void main() {
  testWidgets('App renders bottom nav tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgbaraWalletApp()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    expect(find.byIcon(Icons.token), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
