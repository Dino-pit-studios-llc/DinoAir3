/// DTO for CoinMarketCap listings/latest response item.
class CmcListingDto {
  factory CmcListingDto.fromJson(Map<String, dynamic> json) {
    double numToDouble(dynamic v) => v is num ? v.toDouble() : 0.0;
    final quote = (json['quote'] as Map?)?['USD'] as Map? ?? const {};
    return CmcListingDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      price: numToDouble(quote['price']),
      percentChange24h: numToDouble(quote['percent_change_24h']),
      marketCap: numToDouble(quote['market_cap']),
      volume24h: numToDouble(quote['volume_24h']),
      cmcRank: (json['cmc_rank'] as num?)?.toInt() ?? 0,
    );
  }
  CmcListingDto({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    required this.percentChange24h,
    required this.marketCap,
    required this.volume24h,
    required this.cmcRank,
  });

  final int id; // CMC numeric id
  final String name;
  final String symbol;
  final double price;
  final double percentChange24h;
  final double marketCap;
  final double volume24h;
  final int cmcRank;
}
