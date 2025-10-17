import 'dart:async';

import 'package:crypto_dash/services/api/api_providers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_market_repository.dart';
import '../../data/repositories/cmc_market_repository_impl.dart';
import '../../data/repositories/market_repository_impl.dart';
import '../../domain/coin_entity.dart';
import '../../domain/get_top_coins_use_case.dart';
import '../../domain/market_repository.dart';

// Data source selection enum.
enum MarketDataSource { mock, coingecko, coinmarketcap }

/// Parses MARKET_DATA_SOURCE (case-insensitive).
/// Supported aliases:
///  - coingecko | gecko
///  - coinmarketcap | cmc
///  - mock
/// Fallback (unknown / null): coinmarketcap (prefers real data out of the box).
MarketDataSource _parseDataSource(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'coingecko':
    case 'gecko':
      return MarketDataSource.coingecko;
    case 'coinmarketcap':
    case 'cmc':
      return MarketDataSource.coinmarketcap;
    case 'mock':
      return MarketDataSource.mock;
    default:
      return MarketDataSource.coinmarketcap; // new default
  }
}

/// Provider to select which data source to use.
/// Priority order:
/// 1. --dart-define MARKET_DATA_SOURCE
/// 2. .env MARKET_DATA_SOURCE (loaded in bootstrap)
/// 3. Default: coinmarketcap
///
/// Notes:
///  - If CoinMarketCap is selected but CMC_API_KEY is missing, a warning chip is shown in UI
///    and requests will likely fail with 401 until the key is supplied.
///  - To use the mock repository set MARKET_DATA_SOURCE=mock.
final marketDataSourceProvider = Provider<MarketDataSource>((ref) {
  const defineValue = String.fromEnvironment('MARKET_DATA_SOURCE');
  if (defineValue.isNotEmpty) return _parseDataSource(defineValue);
  final envValue = dotenv.maybeGet('MARKET_DATA_SOURCE');
  if (envValue != null && envValue.trim().isNotEmpty) {
    return _parseDataSource(envValue.trim());
  }
  return MarketDataSource.coinmarketcap; // default now CMC
});

// Refresh interval (can be overridden in tests or settings)
final marketRefreshIntervalProvider = Provider<Duration>(
  (_) => const Duration(seconds: 30),
);

// Repository provider selects implementation based on data source choice.
final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  switch (ref.watch(marketDataSourceProvider)) {
    case MarketDataSource.mock:
      return MockMarketRepository();
    case MarketDataSource.coingecko:
      final api = ref.watch(coinApiClientProvider);
      return MarketRepositoryImpl(api);
    case MarketDataSource.coinmarketcap:
      final cmc = ref.watch(cmcApiClientProvider);
      return CmcMarketRepositoryImpl(cmc);
  }
});

// Use case provider.
final getTopCoinsUseCaseProvider = Provider<GetTopCoinsUseCase>((ref) {
  final repo = ref.watch(marketRepositoryProvider);
  return GetTopCoinsUseCase(repo);
});

class MarketLastUpdatedController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime timestamp) {
    state = timestamp;
  }
}

final marketLastUpdatedProvider =
    NotifierProvider<MarketLastUpdatedController, DateTime?>(
  MarketLastUpdatedController.new,
);

// Coins list provider returning AsyncValue<List<CoinEntity>>.
final topCoinsProvider = FutureProvider.autoDispose<List<CoinEntity>>((
  ref,
) async {
  final useCase = ref.watch(getTopCoinsUseCaseProvider);
  final coins = await useCase();
  ref.read(marketLastUpdatedProvider.notifier).set(DateTime.now().toUtc());
  return coins;
});

// Public auto-refresh activator provider.
final marketAutoRefreshActivatorProvider = Provider.autoDispose<void>((ref) {
  final interval = ref.watch(marketRefreshIntervalProvider);
  final timer = Timer.periodic(
    interval,
    (_) => ref.invalidate(topCoinsProvider),
  );
  ref.onDispose(timer.cancel);
});
