/// Immutable domain representation of a cryptocurrency in list context.
class CoinEntity {
  const CoinEntity({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24hPct,
    required this.marketCap,
    required this.volume24h,
    this.sparkline,
    this.rank,
  });

  final String id;
  final String symbol;
  final String name;
  final double price;
  final double change24hPct;
  final double marketCap;
  final double volume24h;
  final List<double>? sparkline; // Last N points for mini chart.
  final int? rank;
}
