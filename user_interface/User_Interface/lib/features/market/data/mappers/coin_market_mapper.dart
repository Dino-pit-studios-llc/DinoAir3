import '../../domain/coin_entity.dart';
import '../dto/coin_market_dto.dart';

extension CoinMarketDtoMapper on CoinMarketDto {
  CoinEntity toEntity() => CoinEntity(
        id: id,
        symbol: symbol,
        name: name,
        price: currentPrice,
        change24hPct: priceChangePct24h,
        marketCap: marketCap,
        volume24h: totalVolume,
        sparkline: sparkline,
        rank: marketCapRank,
      );
}
