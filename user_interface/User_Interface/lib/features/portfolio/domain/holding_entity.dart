/// Represents a user holding for a given coin.
class HoldingEntity {
  const HoldingEntity({
    required this.coinId,
    required this.amount,
    required this.avgBuyPrice,
  });
  final String coinId;
  final double amount; // May revisit precision using Decimal.
  final double avgBuyPrice;
}
