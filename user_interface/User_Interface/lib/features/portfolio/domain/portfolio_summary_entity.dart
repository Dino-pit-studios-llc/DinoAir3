/// Aggregated portfolio metrics derived from holdings and market prices.
class PortfolioSummaryEntity {
  const PortfolioSummaryEntity({
    required this.totalValue,
    required this.totalCostBasis,
    required this.unrealizedPnl,
    required this.unrealizedPnlPct,
    required this.allocations,
  });

  final double totalValue;
  final double totalCostBasis;
  final double unrealizedPnl; // totalValue - totalCostBasis
  final double unrealizedPnlPct; // unrealizedPnl / totalCostBasis (guard zero)
  final List<Allocation> allocations; // per-coin distribution
}

class Allocation {
  const Allocation(
      {required this.coinId, required this.value, required this.percent});
  final String coinId;
  final double value;
  final double percent; // 0..1
}
