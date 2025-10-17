import 'dart:async';

import 'package:crypto_dash/features/portfolio/data/holding_record.dart';
import 'package:crypto_dash/features/portfolio/domain/holding_entity.dart';
import 'package:crypto_dash/features/portfolio/domain/portfolio_repository.dart';

import 'portfolio_local_data_source.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl(this._localDataSource) {
    _syncController();
  }

  final PortfolioLocalDataSource _localDataSource;
  final _controller = StreamController<List<HoldingEntity>>.broadcast();
  bool _initialized = false;

  Future<void> _syncController() async {
    final holdings = await getHoldings();
    if (!_controller.isClosed) {
      _controller.add(holdings);
    }
  }

  @override
  Future<List<HoldingEntity>> getHoldings() async {
    final records = await _localDataSource.getHoldings();
    return records.map((r) => r.toEntity()).toList(growable: false);
  }

  @override
  Future<void> addOrUpdate(HoldingEntity holding) async {
    final record = HoldingRecord.fromEntity(holding);
    await _localDataSource.upsertHolding(record);
    await _syncController();
  }

  @override
  Future<void> remove(String coinId) async {
    await _localDataSource.removeHolding(coinId);
    await _syncController();
  }

  @override
  Stream<List<HoldingEntity>> watchHoldings() {
    if (!_initialized) {
      _initialized = true;
      unawaited(_syncController());
    }
    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
