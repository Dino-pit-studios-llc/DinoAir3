import 'holding_entity.dart';

/// Repository abstraction for portfolio persistence and retrieval.
abstract class PortfolioRepository {
  Future<List<HoldingEntity>> getHoldings();
  Future<void> addOrUpdate(HoldingEntity holding);
  Future<void> remove(String coinId);

  /// Optional stream if reactive updates are desired later.
  Stream<List<HoldingEntity>> watchHoldings() async* {
    yield await getHoldings();
  }
}
