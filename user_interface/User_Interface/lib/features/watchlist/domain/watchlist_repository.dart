// Repository interface for watchlist feature.
abstract class WatchlistRepository {
  Future<List<String>> getWatchlistCoinIds();

  Future<bool> addToWatchlist(String coinId);

  Future<bool> removeFromWatchlist(String coinId);

  Future<bool> toggleWatchlist(String coinId);

  Future<bool> isInWatchlist(String coinId);
}
