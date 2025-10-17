import 'package:crypto_dash/core/errors/failure.dart';
import 'package:crypto_dash/features/market/domain/coin_entity.dart';
import 'package:crypto_dash/features/market/domain/market_repository.dart';
import 'package:crypto_dash/services/api/coin_api_client.dart';

import '../dto/coin_market_dto.dart';
import '../mappers/coin_market_mapper.dart';

/// Real repository implementation backed by CoinGecko REST API.
/// NOTE: No caching yet (D9); adds simple pass-through with mapping.
class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl(this._apiClient);
  final CoinApiClient _apiClient;

  @override
  Future<List<CoinEntity>> getTopCoins({int limit = 50}) async {
    try {
      final raw = await _apiClient.fetchTopMarkets(perPage: limit);
      return raw.map((m) => CoinMarketDto.fromJson(m).toEntity()).toList();
    } on Failure {
      rethrow; // propagate domain failure
    } catch (e) {
      throw UnknownFailure(
        message: 'Unexpected error loading top coins',
        cause: e,
      );
    }
  }

  @override
  Future<CoinEntity> getCoinById(String id) async {
    try {
      final detail = await _apiClient.fetchCoinDetail(id);
      // Reuse markets shape by extracting subset of fields for now; could create dedicated DTO later.
      final marketLike = {
        'id': detail['id'],
        'symbol': detail['symbol'],
        'name': detail['name'],
        'current_price': detail['market_data']?['current_price']?['usd'],
        'price_change_percentage_24h': detail['market_data']
            ?['price_change_percentage_24h'],
        'market_cap': detail['market_data']?['market_cap']?['usd'],
        'total_volume': detail['market_data']?['total_volume']?['usd'],
        'market_cap_rank': detail['market_cap_rank'],
        'sparkline_in_7d': detail['market_data']?['sparkline_7d'] == null
            ? null
            : {
                'price':
                    (detail['market_data']?['sparkline_7d']?['price'] as List?)
                        ?.cast<num>()
                        .toList(),
              },
      };
      return CoinMarketDto.fromJson(marketLike).toEntity();
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(
        message: 'Unexpected error loading coin detail',
        cause: e,
      );
    }
  }

  @override
  Future<List<double>> getHistoricalPrices(
    String id, {
    required Duration range,
  }) async {
    try {
      // Map duration to days granularity for CoinGecko.
      int days;
      if (range.inDays >= 90) {
        days = 90;
      } else if (range.inDays >= 30) {
        days = 30;
      } else if (range.inDays >= 7) {
        days = 7;
      } else {
        days = 1; // treat < 7d as 1d chart
      }
      final chart = await _apiClient.fetchMarketChart(id, days: days);
      // Each entry: [timestamp(ms), price]
      return chart.map((e) => (e.length > 1 ? e[1] : 0).toDouble()).toList();
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(
        message: 'Unexpected error loading historical prices',
        cause: e,
      );
    }
  }
}
