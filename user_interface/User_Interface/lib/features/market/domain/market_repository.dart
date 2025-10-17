import 'coin_entity.dart';

/// Abstraction over data sources to provide market data.
abstract class MarketRepository {
  Future<List<CoinEntity>> getTopCoins({int limit = 50});
  Future<CoinEntity> getCoinById(String id);
  Future<List<double>> getHistoricalPrices(String id,
      {required Duration range});
}
