import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'holding_record.dart';

class PortfolioLocalDataSource {
  PortfolioLocalDataSource(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const _storageKey = 'portfolio_holdings';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  Future<List<HoldingRecord>> getHoldings() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <HoldingRecord>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(HoldingRecord.fromJson)
            .toList(growable: true);
      }
    } catch (_) {
      // ignore corrupt data; will be overwritten on next save
    }
    return <HoldingRecord>[];
  }

  Future<void> upsertHolding(HoldingRecord record) async {
    final records = await getHoldings();
    final index = records.indexWhere((r) => r.coinId == record.coinId);
    final updatedRecord = record.copyWith(updatedAt: _clock().toUtc());
    if (index >= 0) {
      records[index] = updatedRecord;
    } else {
      records.add(updatedRecord);
    }
    await _save(records);
  }

  Future<void> removeHolding(String coinId) async {
    final records = await getHoldings();
    records.removeWhere((r) => r.coinId == coinId);
    await _save(records);
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }

  Future<void> _save(List<HoldingRecord> records) async {
    final payload = records.map((r) => r.toJson()).toList(growable: false);
    await _prefs.setString(_storageKey, jsonEncode(payload));
  }
}
