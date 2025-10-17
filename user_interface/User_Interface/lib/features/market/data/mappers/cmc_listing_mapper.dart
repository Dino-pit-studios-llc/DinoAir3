import 'package:crypto_dash/features/market/domain/coin_entity.dart';
import '../dto/cmc_listing_dto.dart';

extension CmcListingDtoMapper on CmcListingDto {
  CoinEntity toEntity() => CoinEntity(
        id: id.toString(),
        symbol: symbol,
        name: name,
        price: price,
        change24hPct: percentChange24h,
        marketCap: marketCap,
        volume24h: volume24h,
        rank: cmcRank,
      );
}
