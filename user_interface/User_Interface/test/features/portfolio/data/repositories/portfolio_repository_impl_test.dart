import 'package:crypto_dash/features/portfolio/data/holding_record.dart';
import 'package:crypto_dash/features/portfolio/data/portfolio_local_data_source.dart';
import 'package:crypto_dash/features/portfolio/data/portfolio_repository_impl.dart';
import 'package:crypto_dash/features/portfolio/domain/holding_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'portfolio_repository_impl_test.mocks.dart';

@GenerateMocks([PortfolioLocalDataSource])
void main() {
  late PortfolioRepositoryImpl repository;
  late MockPortfolioLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockPortfolioLocalDataSource();
    // Stub default behavior for constructor call
    when(mockLocalDataSource.getHoldings()).thenAnswer((_) async => []);
    repository = PortfolioRepositoryImpl(mockLocalDataSource);
  });

  tearDown(() {
    repository.dispose();
  });

  group('PortfolioRepositoryImpl - getHoldings', () {
    test('should return list of holdings from local data source', () async {
      // Arrange
      final tRecords = [
        HoldingRecord(
          coinId: 'btc',
          amount: 0.5,
          avgBuyPrice: 30000.0,
          updatedAt: DateTime(2024, 1, 1),
        ),
        HoldingRecord(
          coinId: 'eth',
          amount: 2.0,
          avgBuyPrice: 2000.0,
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];
      when(mockLocalDataSource.getHoldings())
          .thenAnswer((_) async => tRecords);

      // Act
      final result = await repository.getHoldings();

      // Assert
      expect(result.length, equals(2));
      expect(result[0].coinId, equals('btc'));
      expect(result[0].amount, equals(0.5));
      expect(result[1].coinId, equals('eth'));
    });

    test('should return empty list when no holdings exist', () async {
      // Arrange
      when(mockLocalDataSource.getHoldings()).thenAnswer((_) async => []);

      // Act
      final result = await repository.getHoldings();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('PortfolioRepositoryImpl - addOrUpdate', () {
    test('should add new holding via local data source', () async {
      // Arrange
      const tHolding = HoldingEntity(
        coinId: 'btc',
        amount: 0.5,
        avgBuyPrice: 30000.0,
      );
      when(mockLocalDataSource.upsertHolding(any))
          .thenAnswer((_) async => null);

      // Act
      await repository.addOrUpdate(tHolding);

      // Assert
      verify(mockLocalDataSource.upsertHolding(any)).called(1);
    });

    test('should update existing holding via local data source', () async {
      // Arrange
      const tHolding = HoldingEntity(
        coinId: 'btc',
        amount: 1.0,
        avgBuyPrice: 35000.0,
      );
      when(mockLocalDataSource.upsertHolding(any))
          .thenAnswer((_) async => null);

      // Act
      await repository.addOrUpdate(tHolding);

      // Assert
      verify(mockLocalDataSource.upsertHolding(any)).called(1);
    });
  });

  group('PortfolioRepositoryImpl - remove', () {
    test('should remove holding via local data source', () async {
      // Arrange
      const tCoinId = 'btc';
      when(mockLocalDataSource.removeHolding(tCoinId))
          .thenAnswer((_) async => null);

      // Act
      await repository.remove(tCoinId);

      // Assert
      verify(mockLocalDataSource.removeHolding(tCoinId)).called(1);
    });
  });

  group('PortfolioRepositoryImpl - watchHoldings', () {
    test('should return a broadcast stream', () async {
      // Arrange
      final tRecords = [
        HoldingRecord(
          coinId: 'btc',
          amount: 0.5,
          avgBuyPrice: 30000.0,
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];
      when(mockLocalDataSource.getHoldings())
          .thenAnswer((_) async => tRecords);

      // Act
      final stream = repository.watchHoldings();

      // Assert
      expect(stream.isBroadcast, isTrue);
    });

    test('should emit holdings when subscribed', () async {
      // Arrange
      final tRecords = [
        HoldingRecord(
          coinId: 'sol',
          amount: 10.0,
          avgBuyPrice: 100.0,
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];
      when(mockLocalDataSource.getHoldings())
          .thenAnswer((_) async => tRecords);

      // Act
      final stream = repository.watchHoldings();

      // Assert - Should eventually emit holdings
      await expectLater(
        stream.first,
        completion(
          predicate<List<HoldingEntity>>(
            (list) => list.isNotEmpty && list.first.coinId == 'sol',
          ),
        ),
      );
    });
  });

  group('PortfolioRepositoryImpl - dispose', () {
    test('should not throw when disposed', () {
      // Act & Assert - should not throw
      expect(() => repository.dispose(), returnsNormally);
    });

    test('should close stream after dispose', () async {
      // Arrange
      final stream = repository.watchHoldings();

      // Act
      repository.dispose();

      // Assert - Stream should complete
      await expectLater(stream, emitsDone);
    });
  });
}
