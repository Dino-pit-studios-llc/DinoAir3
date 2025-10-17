import 'package:crypto_dash/features/market/domain/coin_entity.dart';
import 'package:crypto_dash/features/portfolio/domain/holding_entity.dart';
import 'package:crypto_dash/features/portfolio/domain/portfolio_summary_entity.dart';
import 'package:crypto_dash/features/portfolio/presentation/widgets/portfolio_insights_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('PortfolioInsightsCard', () {
    testWidgets('renders performance metrics and target insights', (
      WidgetTester tester,
    ) async {
      final holdings = [
        const HoldingEntity(coinId: 'btc', amount: 1.0, avgBuyPrice: 20000),
        const HoldingEntity(coinId: 'eth', amount: 8.0, avgBuyPrice: 2000),
        const HoldingEntity(coinId: 'ada', amount: 1000, avgBuyPrice: 1.20),
      ];

      final coinLookup = {
        'btc': const CoinEntity(
          id: 'btc',
          symbol: 'btc',
          name: 'Bitcoin',
          price: 30000,
          change24hPct: 5,
          marketCap: 600000000000,
          volume24h: 25000000000,
          sparkline: [28000, 29200, 30000],
          rank: 1,
        ),
        'eth': const CoinEntity(
          id: 'eth',
          symbol: 'eth',
          name: 'Ethereum',
          price: 1500,
          change24hPct: -3,
          marketCap: 250000000000,
          volume24h: 15000000000,
          sparkline: [1700, 1600, 1500],
          rank: 2,
        ),
        'ada': const CoinEntity(
          id: 'ada',
          symbol: 'ada',
          name: 'Cardano',
          price: 1.30,
          change24hPct: 1.2,
          marketCap: 45000000000,
          volume24h: 2500000000,
          sparkline: [1.10, 1.25, 1.30],
          rank: 7,
        ),
        'sol': const CoinEntity(
          id: 'sol',
          symbol: 'sol',
          name: 'Solana',
          price: 90,
          change24hPct: 2,
          marketCap: 40000000000,
          volume24h: 5000000000,
          sparkline: [85, 88, 90],
          rank: 5,
        ),
      };

      const summary = PortfolioSummaryEntity(
        totalValue: 145000,
        totalCostBasis: 95000,
        unrealizedPnl: 50000,
        unrealizedPnlPct: 0.5263,
        allocations: [
          Allocation(coinId: 'btc', value: 72000, percent: 0.48),
          Allocation(coinId: 'eth', value: 46400, percent: 0.31),
          Allocation(coinId: 'ada', value: 26600, percent: 0.18),
        ],
      );

      final targetAllocations = {'btc': 0.45, 'eth': 0.55, 'sol': 0.12};

      var editTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioInsightsCard(
                holdings: holdings,
                coinLookup: coinLookup,
                summary: summary,
                change24hPercent: 0.051,
                change7dPercent: -0.08,
                targetAllocations: targetAllocations,
                onEditTargets: () {
                  editTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Portfolio intelligence'), findsOneWidget);
      expect(find.text('Performance 24h'), findsOneWidget);
      expect(find.textContaining('+5.1%'), findsOneWidget);
      expect(find.text('Performance 7d'), findsOneWidget);
      expect(find.textContaining('-8.0%'), findsOneWidget);

      expect(find.text('Top performer'), findsOneWidget);
      expect(find.text('Bitcoin • \$30,000.00'), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('Ethereum • \$12,000.00'), findsOneWidget);

      expect(find.text('Target allocations'), findsOneWidget);
      expect(find.text('Targets coverage'), findsOneWidget);
      expect(find.textContaining('112.0%'), findsOneWidget);
      expect(find.textContaining('above 100%'), findsOneWidget);
      expect(find.text('No targets for: ADA'), findsOneWidget);
      expect(find.text('Targets without holdings: Solana'), findsOneWidget);

      await tester.ensureVisible(find.text('Edit targets'));
      await tester.tap(find.text('Edit targets'));
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });

    testWidgets('shows empty states when no targets defined', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioInsightsCard(
                holdings: const [],
                coinLookup: const {},
                summary: const PortfolioSummaryEntity(
                  totalValue: 0,
                  totalCostBasis: 0,
                  unrealizedPnl: 0,
                  unrealizedPnlPct: 0,
                  allocations: [],
                ),
                onEditTargets: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Holdings tracked'), findsOneWidget);
      expect(
        find.text(
          'No targets set yet. Tap “Edit targets” to define your perfect allocation mix.',
        ),
        findsOneWidget,
      );
    });
  });
}
