import 'holding_entity.dart';
import 'portfolio_repository.dart';

class SaveHoldingUseCase {
  const SaveHoldingUseCase(this._repository);
  final PortfolioRepository _repository;

  Future<void> call(HoldingEntity holding) {
    return _repository.addOrUpdate(holding);
  }
}
