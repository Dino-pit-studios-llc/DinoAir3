import 'package:crypto_dash/core/errors/failure.dart';
import 'package:crypto_dash/features/market/domain/coin_entity.dart';
import 'package:crypto_dash/features/market/domain/market_repository.dart';
import 'package:crypto_dash/services/api/cmc_api_client.dart';

import '../dto/cmc_listing_dto.dart';
import '../mappers/cmc_listing_mapper.dart';

/// Market repository backed by CoinMarketCap listings endpoint.
/// NOTE: Coin detail & historical prices are NOT implemented here yet; those
/// will either use dedicated CMC endpoints later or fall back to CoinGecko.
class CmcMarketRepositoryImpl implements MarketRepository {
  CmcMarketRepositoryImpl(this._api);
  final CmcApiClient _api;

  @override
  Future<List<CoinEntity>> getTopCoins({int limit = 50}) async {
    try {
      final raw = await _api.fetchLatestListings(limit: limit);
      return raw.map((m) => CmcListingDto.fromJson(m).toEntity()).toList();
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: 'CMC top coins failed', cause: e);
    }
  }

  @override
  Future<CoinEntity> getCoinById(String id) async {
    // Inefficient fallback: fetch listings and search; placeholder until dedicated endpoint.
    final list = await getTopCoins(limit: 250);
    final coin = list.firstWhere(
      (c) => c.id == id || c.symbol.toLowerCase() == id.toLowerCase(),
      orElse: () =>
          throw UnknownFailure(message: 'Coin $id not found in CMC data'),
    );
    return coin;
  }

  @override
  Future<List<double>> getHistoricalPrices(
    String id, {
    required Duration range,
  }) async {
    // Not implemented for CMC yet.
    throw UnsupportedError(
      'Historical prices not implemented for CoinMarketCap repository',
    );
  }
}
