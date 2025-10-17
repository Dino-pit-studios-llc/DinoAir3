import 'portfolio_repository.dart';

class RemoveHoldingUseCase {
  const RemoveHoldingUseCase(this._repository);
  final PortfolioRepository _repository;

  Future<void> call(String coinId) {
    return _repository.remove(coinId);
  }
}
