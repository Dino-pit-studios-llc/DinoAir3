import 'dart:math' as math;

import 'holding_entity.dart';
import 'portfolio_summary_entity.dart';

class ComputePortfolioSummaryUseCase {
  const ComputePortfolioSummaryUseCase();

  PortfolioSummaryEntity call({
    required List<HoldingEntity> holdings,
    required Map<String, double> priceByCoinId,
  }) {
    if (holdings.isEmpty) {
      return const PortfolioSummaryEntity(
        totalValue: 0,
        totalCostBasis: 0,
        unrealizedPnl: 0,
        unrealizedPnlPct: 0,
        allocations: <Allocation>[],
      );
    }

    double totalValue = 0;
    double totalCostBasis = 0;
    final allocations = <Allocation>[];

    for (final holding in holdings) {
      final price = priceByCoinId[holding.coinId];
      final currentPrice = price ?? holding.avgBuyPrice;
      final currentValue = holding.amount * currentPrice;
      final costBasis = holding.amount * holding.avgBuyPrice;

      totalValue += currentValue;
      totalCostBasis += costBasis;

      allocations.add(
        Allocation(
          coinId: holding.coinId,
          value: currentValue,
          percent: 0, // placeholder, compute later
        ),
      );
    }

    final unrealizedPnl = totalValue - totalCostBasis;
    final unrealizedPnlPct =
        totalCostBasis > 0 ? (unrealizedPnl / totalCostBasis) : 0.0;

    final normalizedAllocations = <Allocation>[];
    for (final allocation in allocations) {
      final percent = totalValue > 0 ? allocation.value / totalValue : 0.0;
      normalizedAllocations.add(
        Allocation(
          coinId: allocation.coinId,
          value: allocation.value,
          percent: _clampPercent(percent),
        ),
      );
    }

    normalizedAllocations.sort((a, b) => b.value.compareTo(a.value));

    return PortfolioSummaryEntity(
      totalValue: _roundCurrency(totalValue),
      totalCostBasis: _roundCurrency(totalCostBasis),
      unrealizedPnl: _roundCurrency(unrealizedPnl),
      unrealizedPnlPct: unrealizedPnlPct,
      allocations: normalizedAllocations,
    );
  }

  double _roundCurrency(double value) {
    final factor = math.pow(10, 2);
    return (value * factor).roundToDouble() / factor;
  }

  double _clampPercent(double value) {
    if (value.isNaN) return 0;
    if (value.isInfinite) return value.isNegative ? 0 : 1;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
