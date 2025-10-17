import 'dart:convert';

import 'package:crypto_dash/features/watchlist/data/watchlist_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storageKey = 'watchlist_items';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<WatchlistLocalDataSource> buildDataSource({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    return WatchlistLocalDataSource(
      prefs,
      clock: now != null ? () => now : null,
    );
  }

  test('returns empty list when nothing stored', () async {
    final dataSource = await buildDataSource();
    expect(await dataSource.getWatchlist(), isEmpty);
  });

  test('addToWatchlist persists coin id and timestamp', () async {
    final now = DateTime.utc(2025, 10, 6, 12);
    final dataSource = await buildDataSource(now: now);
    final prefs = await SharedPreferences.getInstance();

    final added = await dataSource.addToWatchlist('bitcoin');
    expect(added, isTrue);
    expect(await dataSource.getWatchlist(), ['bitcoin']);

    final raw = prefs.getString(storageKey);
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded, hasLength(1));
    final entry = Map<String, dynamic>.from(decoded.first as Map);
    expect(entry['id'], 'bitcoin');
    expect(entry['ts'], now.toIso8601String());
  });

  test('addToWatchlist is idempotent', () async {
    final dataSource = await buildDataSource();
    final first = await dataSource.addToWatchlist('eth');
    final second = await dataSource.addToWatchlist('eth');

    expect(first, isTrue);
    expect(second, isFalse);
    expect(await dataSource.getWatchlist(), ['eth']);
  });

  test('toggleWatchlist adds then removes coin', () async {
    final dataSource = await buildDataSource();

    final added = await dataSource.toggleWatchlist('sol');
    expect(added, isTrue);
    expect(await dataSource.isInWatchlist('sol'), isTrue);

    final removed = await dataSource.toggleWatchlist('sol');
    expect(removed, isFalse);
    expect(await dataSource.isInWatchlist('sol'), isFalse);
  });

  test('removeFromWatchlist returns false when coin missing', () async {
    final dataSource = await buildDataSource();
    final result = await dataSource.removeFromWatchlist('ada');
    expect(result, isFalse);
  });

  test('gracefully handles corrupted payloads', () async {
    SharedPreferences.setMockInitialValues({storageKey: 'not-json'});
    final dataSource = await buildDataSource();

    expect(await dataSource.getWatchlist(), isEmpty);
    final toggled = await dataSource.toggleWatchlist('btc');
    expect(toggled, isTrue);
    expect(await dataSource.getWatchlist(), ['btc']);
  });
}
