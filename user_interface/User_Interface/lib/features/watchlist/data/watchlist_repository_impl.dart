// Repository implementation for watchlist feature.
import '../domain/watchlist_repository.dart';
import 'watchlist_local_data_source.dart';

class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl(this._localDataSource);
  final WatchlistLocalDataSource _localDataSource;

  @override
  Future<List<String>> getWatchlistCoinIds() async {
    return await _localDataSource.getWatchlist();
  }

  @override
  Future<bool> addToWatchlist(String coinId) async {
    return await _localDataSource.addToWatchlist(coinId);
  }

  @override
  Future<bool> removeFromWatchlist(String coinId) async {
    return await _localDataSource.removeFromWatchlist(coinId);
  }

  @override
  Future<bool> toggleWatchlist(String coinId) async {
    return await _localDataSource.toggleWatchlist(coinId);
  }

  @override
  Future<bool> isInWatchlist(String coinId) async {
    return await _localDataSource.isInWatchlist(coinId);
  }
}
