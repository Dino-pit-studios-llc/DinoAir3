import 'package:crypto_dash/features/portfolio/data/holding_record.dart';
import 'package:crypto_dash/features/portfolio/data/portfolio_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late DateTime now;
  late PortfolioLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime.utc(2025, 1, 1, 12);
    dataSource = PortfolioLocalDataSource(prefs, clock: () => now);
  });

  test('returns empty list when nothing persisted', () async {
    final holdings = await dataSource.getHoldings();
    expect(holdings, isEmpty);
  });

  test('upsertHolding adds new entry with updated timestamp', () async {
    final record = HoldingRecord(
      coinId: 'btc',
      amount: 1.5,
      avgBuyPrice: 12000,
      updatedAt: DateTime.utc(2000),
    );

    await dataSource.upsertHolding(record);

    final stored = await dataSource.getHoldings();
    expect(stored, hasLength(1));
    final item = stored.first;
    expect(item.coinId, 'btc');
    expect(item.amount, 1.5);
    expect(item.avgBuyPrice, 12000);
    expect(item.updatedAt, now);
  });

  test('upsertHolding replaces existing entry when coin id matches', () async {
    final original = HoldingRecord(
      coinId: 'eth',
      amount: 2,
      avgBuyPrice: 1500,
      updatedAt: DateTime.utc(2001),
    );
    await dataSource.upsertHolding(original);

    now = now.add(const Duration(hours: 1));
    final updated = original.copyWith(amount: 3, avgBuyPrice: 1800);
    await dataSource.upsertHolding(updated);

    final stored = await dataSource.getHoldings();
    expect(stored, hasLength(1));
    final item = stored.first;
    expect(item.amount, 3);
    expect(item.avgBuyPrice, 1800);
    expect(item.updatedAt, now);
  });

  test('removeHolding deletes the matching record', () async {
    await dataSource.upsertHolding(
      HoldingRecord(
        coinId: 'btc',
        amount: 1,
        avgBuyPrice: 10000,
        updatedAt: DateTime.utc(2000),
      ),
    );
    await dataSource.upsertHolding(
      HoldingRecord(
        coinId: 'eth',
        amount: 5,
        avgBuyPrice: 2000,
        updatedAt: DateTime.utc(2000),
      ),
    );

    await dataSource.removeHolding('btc');

    final stored = await dataSource.getHoldings();
    expect(stored, hasLength(1));
    expect(stored.first.coinId, 'eth');
  });
}
