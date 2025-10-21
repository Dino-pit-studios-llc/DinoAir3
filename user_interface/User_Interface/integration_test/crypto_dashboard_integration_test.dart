import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:crypto_dash/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Crypto Dashboard Integration Tests', () {
    setUp(() {
      // Each test needs to launch the app independently
      // This is handled in each test to ensure proper isolation
    });

    testWidgets(
      'User can view market data and portfolio summary',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Open drawer
        Finder drawerButton = find.byKey(const Key('open_drawer_button'));
        if (drawerButton.evaluate().isEmpty) {
          drawerButton = find.byTooltip('Open navigation menu');
        }
        expect(drawerButton, findsOneWidget,
            reason: 'Drawer/menu button not found');
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to Crypto Dashboard
        final cryptoTile = find.text('Crypto Dashboard');
        expect(cryptoTile, findsOneWidget,
            reason: 'Crypto Dashboard should be available in drawer - feature missing or renamed');
        await tester.tap(cryptoTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify dashboard loaded
        expect(
          find.text('Crypto dashboard'),
          findsWidgets,
          reason: 'Crypto Dashboard screen not loaded',
        );

        // Wait for market data to load
        const maxWaitMs = 10000;
        var waitedMs = 0;
        while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
            waitedMs < maxWaitMs) {
          await tester.pump(const Duration(milliseconds: 500));
          waitedMs += 500;
        }

        // Check portfolio summary card exists with assertion
        final portfolioCard = find.textContaining('Portfolio');
        expect(portfolioCard, findsWidgets,
            reason: 'Portfolio summary should be visible');

        // Check market data is displayed with assertion
        final marketSection = find.textContaining('Market');
        expect(marketSection, findsWidgets,
            reason: 'Market section should be visible');
      },
    );

    testWidgets(
      'User can navigate to market screen',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Navigate to Crypto Dashboard
        Finder drawerButton = find.byKey(const Key('open_drawer_button'));
        if (drawerButton.evaluate().isEmpty) {
          drawerButton = find.byTooltip('Open navigation menu');
        }
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final cryptoTile = find.text('Crypto Dashboard');
        expect(cryptoTile, findsOneWidget,
            reason: 'Crypto Dashboard should be available - feature missing or renamed');
        await tester.tap(cryptoTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to full market view
        final viewMarketButton = find.textContaining('View Market');
        expect(viewMarketButton, findsOneWidget,
            reason: 'View Market button should be present');
        await tester.tap(viewMarketButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify market screen loaded
        final marketScreen = find.textContaining('Market');
        expect(marketScreen, findsWidgets,
            reason: 'Market screen should be visible');
      },
    );

    testWidgets(
      'User can add a portfolio holding',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Navigate to Crypto Dashboard
        Finder drawerButton = find.byKey(const Key('open_drawer_button'));
        if (drawerButton.evaluate().isEmpty) {
          drawerButton = find.byTooltip('Open navigation menu');
        }
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final cryptoTile = find.text('Crypto Dashboard');
        expect(cryptoTile, findsOneWidget,
            reason: 'Crypto Dashboard should be available - feature missing or renamed');
        await tester.tap(cryptoTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Add holding
        final addButton = find.byKey(const Key('add_holding_button'));
        expect(addButton, findsOneWidget,
            reason: 'Add holding button should be present');
        await tester.tap(addButton);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // Verify add holding dialog/sheet
        final coinIdField = find.byKey(const Key('holding_coin_id_field'));
        expect(coinIdField, findsOneWidget,
            reason: 'Add holding form should be displayed');

        // Enter test data
        await tester.enterText(coinIdField, 'btc');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        final amountField = find.byKey(const Key('holding_amount_field'));
        expect(amountField, findsOneWidget,
            reason: 'Amount field should be present');
        await tester.enterText(amountField, '0.5');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        final priceField = find.byKey(const Key('holding_avg_price_field'));
        expect(priceField, findsOneWidget,
            reason: 'Average price field should be present');
        await tester.enterText(priceField, '30000');
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        // Save holding
        final saveButton = find.byKey(const Key('save_holding_button'));
        expect(saveButton, findsOneWidget,
            reason: 'Save button should be present');
        await tester.tap(saveButton);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // Verify holding was added (dialog closed)
        expect(find.byKey(const Key('holding_coin_id_field')), findsNothing,
            reason: 'Add holding dialog should close after save');

        // Verify holding appears in portfolio list
        final btcHolding = find.textContaining('BTC');
        expect(btcHolding, findsWidgets,
            reason: 'Added BTC holding should be visible in portfolio');
      },
    );
  });
}
