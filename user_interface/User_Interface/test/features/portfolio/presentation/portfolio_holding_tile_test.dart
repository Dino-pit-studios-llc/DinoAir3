import 'package:crypto_dash/features/market/domain/coin_entity.dart';
import 'package:crypto_dash/features/portfolio/domain/holding_entity.dart';
import 'package:crypto_dash/features/portfolio/presentation/widgets/portfolio_holding_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  testWidgets('PortfolioHoldingTile renders data and triggers callbacks', (
    WidgetTester tester,
  ) async {
    var editCount = 0;
    var deleteCount = 0;

    const holding = HoldingEntity(
      coinId: 'btc',
      amount: 0.75,
      avgBuyPrice: 20000,
    );

    const coin = CoinEntity(
      id: 'btc',
      symbol: 'btc',
      name: 'Bitcoin',
      price: 27000,
      change24hPct: 2.5,
      marketCap: 600000000000,
      volume24h: 30000000000,
      sparkline: [25000, 26000, 27000],
      rank: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: PortfolioHoldingTile(
            holding: holding,
            coin: coin,
            onEdit: () => editCount++,
            onDelete: () => deleteCount++,
          ),
        ),
      ),
    );

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsWidgets);
    expect(find.text('#BTC'), findsOneWidget);
    expect(find.text('0.7500'), findsOneWidget);
    expect(find.text('UNITS'), findsOneWidget);
    expect(find.text('AVG BUY'), findsOneWidget);
    expect(find.text('COST BASIS'), findsOneWidget);
    expect(find.textContaining('+\$5,250.00 (35.00%)'), findsOneWidget);
    expect(find.text('Now \$27,000.00'), findsOneWidget);

    await tester.tap(find.text('Bitcoin'));
    await tester.pumpAndSettle();
    expect(editCount, 1);

    await tester.tap(find.byTooltip('Holding options'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove holding'));
    await tester.pumpAndSettle();
    expect(deleteCount, 1);
  });
}
