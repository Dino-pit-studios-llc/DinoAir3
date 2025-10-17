// Use case for getting watchlist coin IDs.
import 'watchlist_repository.dart';

class GetWatchlistCoinsUseCase {
  GetWatchlistCoinsUseCase(this._repository);
  final WatchlistRepository _repository;

  Future<List<String>> call() async {
    return await _repository.getWatchlistCoinIds();
  }
}
