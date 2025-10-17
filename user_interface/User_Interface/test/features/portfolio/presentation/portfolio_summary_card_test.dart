import 'package:crypto_dash/features/portfolio/domain/portfolio_summary_entity.dart';
import 'package:crypto_dash/features/portfolio/presentation/widgets/portfolio_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  testWidgets('PortfolioSummaryCard renders metrics and allocations', (
    WidgetTester tester,
  ) async {
    const summary = PortfolioSummaryEntity(
      totalValue: 125000.0,
      totalCostBasis: 90000.0,
      unrealizedPnl: 35000.0,
      unrealizedPnlPct: 0.3888,
      allocations: [
        Allocation(coinId: 'btc', value: 60000.0, percent: 0.48),
        Allocation(coinId: 'eth', value: 40000.0, percent: 0.32),
        Allocation(coinId: 'sol', value: 25000.0, percent: 0.2),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(
          body: PortfolioSummaryCard(
            summary: summary,
            holdingCount: 5,
            dailyChangeValue: 1500.0,
            dailyChangePercent: 0.0425,
          ),
        ),
      ),
    );

    expect(find.text('Total net worth'), findsOneWidget);
    expect(find.text('HOLDINGS TRACKED'), findsOneWidget);
    expect(find.text('5 holdings'), findsOneWidget);
    expect(find.text('Daily move'), findsOneWidget);
    expect(find.text('+\$1,500.00 (+4.25%)'), findsOneWidget);

    expect(find.textContaining('BTC'), findsOneWidget);
    expect(find.textContaining('ETH'), findsOneWidget);
    expect(find.textContaining('SOL'), findsOneWidget);
  });
}
