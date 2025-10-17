import 'coin_entity.dart';
import 'market_repository.dart';

/// Use case to retrieve top coins list.
class GetTopCoinsUseCase {
  const GetTopCoinsUseCase(this._repository);
  final MarketRepository _repository;

  Future<List<CoinEntity>> call({int limit = 50}) {
    return _repository.getTopCoins(limit: limit);
  }
}
