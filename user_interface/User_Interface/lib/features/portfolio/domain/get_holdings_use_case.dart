import 'holding_entity.dart';
import 'portfolio_repository.dart';

class GetHoldingsUseCase {
  const GetHoldingsUseCase(this._repository);
  final PortfolioRepository _repository;

  Future<List<HoldingEntity>> call() {
    return _repository.getHoldings();
  }

  Stream<List<HoldingEntity>> watch() {
    return _repository.watchHoldings();
  }
}
