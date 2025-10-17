import 'dart:math' as math;

import '../../domain/coin_entity.dart';
import '../../domain/market_repository.dart';

/// Temporary in-memory mock implementation to drive the UI (F1) before
/// wiring real API (D1-D6).
class MockMarketRepository implements MarketRepository {
  MockMarketRepository();

  List<CoinEntity> _generateCoins() {
    final basePrices = [63000.0, 3200.5, 1.05, 0.52, 420.12, 190.33];
    final names = [
      ['bitcoin', 'BTC', 'Bitcoin'],
      ['ethereum', 'ETH', 'Ethereum'],
      ['cardano', 'ADA', 'Cardano'],
      ['ripple', 'XRP', 'XRP'],
      ['binancecoin', 'BNB', 'BNB'],
      ['solana', 'SOL', 'Solana'],
    ];
    return List<CoinEntity>.generate(names.length, (i) {
      final change = ((i.isEven ? 1 : -1) * (2 + i)).toDouble();
      final pct = change / 100; // simple synthetic percent
      final price = basePrices[i] * (1 + pct);
      final spark = List<double>.generate(
        24,
        (h) => price * (1 + (0.005 * (h % 3 - 1))),
      );
      return CoinEntity(
        id: names[i][0],
        symbol: names[i][1],
        name: names[i][2],
        price: double.parse(price.toStringAsFixed(2)),
        change24hPct: pct * 100,
        marketCap: (price * 1000000) - (i * 5000000),
        volume24h: (price * 50000) + (i * 100000),
        sparkline: spark,
        rank: i + 1,
      );
    });
  }

  @override
  Future<List<CoinEntity>> getTopCoins({int limit = 50}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final data = _generateCoins();
    return data.take(limit).toList();
  }

  @override
  Future<CoinEntity> getCoinById(String id) async {
    return (await getTopCoins()).firstWhere((c) => c.id == id);
  }

  @override
  Future<List<double>> getHistoricalPrices(
    String id, {
    required Duration range,
  }) async {
    final points = <double>[];
    final totalHours = range.inHours == 0 ? 24 : range.inHours;
    final base = (await getCoinById(id)).price;
    for (var h = 0; h < totalHours; h++) {
      final factor = (h / totalHours) * math.pi * 2; // full wave
      points.add(
        base * (1 + 0.02 * math.sin(factor) + 0.01 * math.cos(factor / 2)),
      );
    }
    return points;
  }
}
