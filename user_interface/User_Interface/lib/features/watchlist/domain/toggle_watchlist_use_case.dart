// Use case for toggling a coin in/out of the watchlist.
import 'watchlist_repository.dart';

class ToggleWatchlistUseCase {
  ToggleWatchlistUseCase(this._repository);
  final WatchlistRepository _repository;

  Future<bool> call(String coinId) async {
    return await _repository.toggleWatchlist(coinId);
  }
}
