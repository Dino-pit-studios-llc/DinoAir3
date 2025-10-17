/// DTO representing a coin row from the CoinGecko /coins/markets endpoint.
/// We manually map instead of using code generation initially for clarity.
class CoinMarketDto {
  factory CoinMarketDto.fromJson(Map<String, dynamic> json) {
    List<double>? parseSparkline() {
      final spark = json['sparkline_in_7d'];
      if (spark is Map && spark['price'] is List) {
        return (spark['price'] as List)
            .whereType<num>()
            .map((e) => e.toDouble())
            .toList();
      }
      return null;
    }

    double toDouble(dynamic v) => v is num ? v.toDouble() : 0.0;

    return CoinMarketDto(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      currentPrice: toDouble(json['current_price']),
      priceChangePct24h: toDouble(json['price_change_percentage_24h']),
      marketCap: toDouble(json['market_cap']),
      totalVolume: toDouble(json['total_volume']),
      marketCapRank: (json['market_cap_rank'] as num?)?.toInt() ?? 0,
      sparkline: parseSparkline(),
    );
  }
  CoinMarketDto({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChangePct24h,
    required this.marketCap,
    required this.totalVolume,
    required this.marketCapRank,
    this.sparkline,
  });

  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChangePct24h;
  final double marketCap;
  final double totalVolume;
  final int marketCapRank;
  final List<double>? sparkline;
}
