import 'package:crypto_dash/features/portfolio/domain/compute_portfolio_summary_use_case.dart';
import 'package:crypto_dash/features/portfolio/domain/holding_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = ComputePortfolioSummaryUseCase();

  group('ComputePortfolioSummaryUseCase', () {
    test('returns zeroed summary when there are no holdings', () {
      final summary = useCase(holdings: const [], priceByCoinId: const {});

      expect(summary.totalValue, 0);
      expect(summary.totalCostBasis, 0);
      expect(summary.unrealizedPnl, 0);
      expect(summary.unrealizedPnlPct, 0);
      expect(summary.allocations, isEmpty);
    });

    test('computes aggregate metrics using market prices when available', () {
      final summary = useCase(
        holdings: const [
          HoldingEntity(coinId: 'bitcoin', amount: 0.5, avgBuyPrice: 20000),
          HoldingEntity(coinId: 'ethereum', amount: 2, avgBuyPrice: 1500),
        ],
        priceByCoinId: const {'bitcoin': 30000, 'ethereum': 2000},
      );

      expect(summary.totalCostBasis, closeTo(13000, 0.001));
      expect(summary.totalValue, closeTo(19000, 0.001));
      expect(summary.unrealizedPnl, closeTo(6000, 0.001));
      expect(summary.unrealizedPnlPct, closeTo(6000 / 13000, 1e-6));

      expect(summary.allocations, hasLength(2));
      expect(summary.allocations.first.coinId, 'bitcoin');
      expect(summary.allocations.first.value, closeTo(15000, 0.001));
      expect(summary.allocations.first.percent, closeTo(15000 / 19000, 1e-6));

      expect(summary.allocations.last.coinId, 'ethereum');
      expect(summary.allocations.last.value, closeTo(4000, 0.001));
      expect(summary.allocations.last.percent, closeTo(4000 / 19000, 1e-6));
    });

    test('falls back to average buy price when market price is missing', () {
      final summary = useCase(
        holdings: const [
          HoldingEntity(coinId: 'solana', amount: 3, avgBuyPrice: 20),
        ],
        priceByCoinId: const {},
      );

      expect(summary.totalValue, closeTo(60, 0.001));
      expect(summary.totalCostBasis, closeTo(60, 0.001));
      expect(summary.unrealizedPnl, closeTo(0, 0.001));
      expect(summary.unrealizedPnlPct, 0);
      expect(summary.allocations.single.coinId, 'solana');
      expect(summary.allocations.single.value, closeTo(60, 0.001));
      expect(summary.allocations.single.percent, closeTo(1, 1e-6));
    });
  });
}
