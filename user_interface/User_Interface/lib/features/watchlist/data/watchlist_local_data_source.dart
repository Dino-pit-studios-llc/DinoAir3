import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for watchlist coin identifiers.
///
/// Data is stored as a JSON-encoded list of objects, preserving insertion
/// order and capturing the timestamp each coin was added. The schema is:
///
/// ```json
/// [
///   {"id": "bitcoin", "ts": "2025-10-06T12:34:56.000Z"},
///   {"id": "ethereum", "ts": "2025-10-06T12:35:10.000Z"}
/// ]
/// ```
///
/// Timestamps are optional for readers, but always written for new entries so
/// future features (sorting, activity feeds) can leverage them.
class WatchlistLocalDataSource {
  WatchlistLocalDataSource(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const _storageKey = 'watchlist_items';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  Future<List<String>> getWatchlist() async {
    final entries = _loadEntries();
    return entries.map((e) => e.coinId).toList(growable: false);
  }

  Future<bool> addToWatchlist(String coinId) async {
    final entries = _loadEntries();
    if (entries.any((e) => e.coinId == coinId)) {
      return false;
    }
    entries.add(_WatchlistEntry(coinId: coinId, addedAt: _clock()));
    await _saveEntries(entries);
    return true;
  }

  Future<bool> removeFromWatchlist(String coinId) async {
    final entries = _loadEntries();
    final initialLength = entries.length;
    entries.removeWhere((e) => e.coinId == coinId);
    if (entries.length == initialLength) {
      return false;
    }
    await _saveEntries(entries);
    return true;
  }

  /// Toggles membership, returning `true` when the coin is now in the
  /// watchlist and `false` when it has been removed.
  Future<bool> toggleWatchlist(String coinId) async {
    final entries = _loadEntries();
    final existingIndex = entries.indexWhere((e) => e.coinId == coinId);
    if (existingIndex >= 0) {
      entries.removeAt(existingIndex);
      await _saveEntries(entries);
      return false;
    }

    entries.add(_WatchlistEntry(coinId: coinId, addedAt: _clock()));
    await _saveEntries(entries);
    return true;
  }

  Future<bool> isInWatchlist(String coinId) async {
    final entries = _loadEntries();
    return entries.any((e) => e.coinId == coinId);
  }

  List<_WatchlistEntry> _loadEntries() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <_WatchlistEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(_WatchlistEntry.fromJson)
            .where((entry) => entry.coinId.isNotEmpty)
            .toList(growable: true);
      }
    } catch (_) {
      // Swallow malformed payloads and reset storage on next save.
    }
    return <_WatchlistEntry>[];
  }

  Future<void> _saveEntries(List<_WatchlistEntry> entries) async {
    final payload = entries
        .map((e) => {'id': e.coinId, 'ts': e.addedAt.toIso8601String()})
        .toList(growable: false);
    final success = await _prefs.setString(_storageKey, jsonEncode(payload));
    if (!success) {
      // Handle failure: log, throw, or otherwise notify
      throw Exception('Failed to save watchlist entries to local storage.');
    }
  }
}

class _WatchlistEntry {
  const _WatchlistEntry({required this.coinId, required this.addedAt});

  factory _WatchlistEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      return _WatchlistEntry(
        coinId: '',
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    final ts = json['ts'];
    final parsed = ts is String ? DateTime.tryParse(ts) : null;
    return _WatchlistEntry(
      coinId: id,
      addedAt: parsed ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String coinId;
  final DateTime addedAt;
}
