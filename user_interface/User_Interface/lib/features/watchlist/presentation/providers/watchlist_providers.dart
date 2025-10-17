// Riverpod providers for watchlist feature.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../main.dart';
import '../../../market/domain/coin_entity.dart';
import '../../../market/presentation/providers/market_providers.dart';
import '../../data/watchlist_local_data_source.dart';
import '../../data/watchlist_repository_impl.dart';
import '../../domain/get_watchlist_coins_use_case.dart';
import '../../domain/toggle_watchlist_use_case.dart';
import '../../domain/watchlist_repository.dart';

// Data source provider
final watchlistLocalDataSourceProvider = Provider<WatchlistLocalDataSource>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WatchlistLocalDataSource(prefs);
});

// Repository provider
final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  final dataSource = ref.watch(watchlistLocalDataSourceProvider);
  return WatchlistRepositoryImpl(dataSource);
});

// Use case providers
final toggleWatchlistUseCaseProvider = Provider<ToggleWatchlistUseCase>((ref) {
  final repository = ref.watch(watchlistRepositoryProvider);
  return ToggleWatchlistUseCase(repository);
});

final getWatchlistCoinsUseCaseProvider = Provider<GetWatchlistCoinsUseCase>((
  ref,
) {
  final repository = ref.watch(watchlistRepositoryProvider);
  return GetWatchlistCoinsUseCase(repository);
});

// State provider for watchlist coin IDs
final watchlistCoinIdsProvider = FutureProvider<List<String>>((ref) async {
  final useCase = ref.watch(getWatchlistCoinsUseCaseProvider);
  return await useCase();
});

// Provider to check if a specific coin is in watchlist
final isInWatchlistProvider = FutureProvider.family<bool, String>((
  ref,
  coinId,
) async {
  final watchlistIds = await ref.watch(watchlistCoinIdsProvider.future);
  return watchlistIds.contains(coinId);
});

// Provider for watchlist coins with full data
final watchlistCoinsProvider = FutureProvider<List<CoinEntity>>((ref) async {
  // Get watchlist IDs
  final watchlistIds = await ref.watch(watchlistCoinIdsProvider.future);

  if (watchlistIds.isEmpty) {
    return [];
  }

  // Get all market coins
  final allCoins = await ref.watch(topCoinsProvider.future);

  // Filter to only watchlist coins
  return allCoins.where((coin) => watchlistIds.contains(coin.id)).toList();
});

// Controller for toggling watchlist
class WatchlistController extends AsyncNotifier<void> {
  late final ToggleWatchlistUseCase _toggleUseCase;

  @override
  FutureOr<void> build() {
    _toggleUseCase = ref.read(toggleWatchlistUseCaseProvider);
    return null;
  }

  Future<void> toggle(String coinId) async {
    state = const AsyncValue.loading();
    try {
      await _toggleUseCase(coinId);
      ref.invalidate(watchlistCoinIdsProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final watchlistControllerProvider =
    AsyncNotifierProvider<WatchlistController, void>(WatchlistController.new);
