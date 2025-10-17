import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../main.dart';
import '../../../market/presentation/providers/market_providers.dart';
import '../../data/portfolio_local_data_source.dart';
import '../../data/portfolio_repository_impl.dart';
import '../../domain/compute_portfolio_summary_use_case.dart';
import '../../domain/get_holdings_use_case.dart';
import '../../domain/holding_entity.dart';
import '../../domain/portfolio_repository.dart';
import '../../domain/portfolio_summary_entity.dart';
import '../../domain/remove_holding_use_case.dart';
import '../../domain/save_holding_use_case.dart';

/// Provides the SharedPreferences-backed data source for portfolio holdings.
final portfolioLocalDataSourceProvider = Provider<PortfolioLocalDataSource>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PortfolioLocalDataSource(prefs);
});

/// Repository instance bridging domain and data layers.
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final dataSource = ref.watch(portfolioLocalDataSourceProvider);
  final repository = PortfolioRepositoryImpl(dataSource);
  ref.onDispose(repository.dispose);
  return repository;
});

/// Use case providers for read/write operations.
final getHoldingsUseCaseProvider = Provider<GetHoldingsUseCase>((ref) {
  final repository = ref.watch(portfolioRepositoryProvider);
  return GetHoldingsUseCase(repository);
});

final saveHoldingUseCaseProvider = Provider<SaveHoldingUseCase>((ref) {
  final repository = ref.watch(portfolioRepositoryProvider);
  return SaveHoldingUseCase(repository);
});

final removeHoldingUseCaseProvider = Provider<RemoveHoldingUseCase>((ref) {
  final repository = ref.watch(portfolioRepositoryProvider);
  return RemoveHoldingUseCase(repository);
});

final computePortfolioSummaryUseCaseProvider =
    Provider<ComputePortfolioSummaryUseCase>((_) {
  return const ComputePortfolioSummaryUseCase();
});

/// Stream provider emitting live holdings updates.
final portfolioHoldingsProvider = StreamProvider<List<HoldingEntity>>((ref) {
  final useCase = ref.watch(getHoldingsUseCaseProvider);
  return useCase.watch();
});

/// Future provider for one-time holdings fetch (useful for pre-loading forms).
final portfolioHoldingsOnceProvider = FutureProvider<List<HoldingEntity>>((
  ref,
) async {
  final useCase = ref.watch(getHoldingsUseCaseProvider);
  return useCase();
});

/// Maps holdings with market prices to a portfolio summary entity.
final portfolioSummaryProvider = Provider<AsyncValue<PortfolioSummaryEntity>>((
  ref,
) {
  final holdingsAsync = ref.watch(portfolioHoldingsProvider);
  final coinsAsync = ref.watch(topCoinsProvider);
  final compute = ref.watch(computePortfolioSummaryUseCaseProvider);

  return holdingsAsync.when(
    data: (holdings) {
      return coinsAsync.when(
        data: (coins) {
          final priceMap = <String, double>{
            for (final coin in coins) coin.id: coin.price,
          };
          final summary = compute(holdings: holdings, priceByCoinId: priceMap);
          return AsyncValue.data(summary);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Controller handling save/remove operations with progress + error state.
class PortfolioController extends AsyncNotifier<void> {
  late final SaveHoldingUseCase _saveHolding;
  late final RemoveHoldingUseCase _removeHolding;

  @override
  FutureOr<void> build() {
    _saveHolding = ref.read(saveHoldingUseCaseProvider);
    _removeHolding = ref.read(removeHoldingUseCaseProvider);
    return null;
  }

  Future<void> save(HoldingEntity holding) async {
    state = const AsyncValue.loading();
    try {
      await _saveHolding(holding);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> remove(String coinId) async {
    state = const AsyncValue.loading();
    try {
      await _removeHolding(coinId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final portfolioControllerProvider =
    AsyncNotifierProvider<PortfolioController, void>(PortfolioController.new);

enum PortfolioSortOption {
  valueDesc,
  valueAsc,
  nameAsc,
  nameDesc,
  gainLossDesc,
  gainLossAsc,
}

class PortfolioSortController extends Notifier<PortfolioSortOption> {
  static const _prefsKey = 'portfolio.sort_option';

  @override
  PortfolioSortOption build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      for (final option in PortfolioSortOption.values) {
        if (option.name == stored) {
          return option;
        }
      }
    }
    return PortfolioSortOption.valueDesc;
  }

  void select(PortfolioSortOption option) {
    if (state == option) return;
    state = option;
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setString(_prefsKey, option.name));
  }
}

final portfolioSortOptionProvider =
    NotifierProvider<PortfolioSortController, PortfolioSortOption>(
  PortfolioSortController.new,
);

class PortfolioTargetAllocationsController
    extends AsyncNotifier<Map<String, double>> {
  static const _prefsKey = 'portfolio.target_allocations_v1';

  late SharedPreferences _prefs;

  @override
  FutureOr<Map<String, double>> build() async {
    _prefs = ref.read(sharedPreferencesProvider);
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return const <String, double>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) {
          final percent = value is num
              ? value.toDouble()
              : double.tryParse(value.toString()) ?? 0.0;
          return MapEntry(key, _clampPercent(percent));
        })
          ..removeWhere((_, value) => value <= 0);
      }
    } catch (_) {
      // ignore malformed payload; will rewrite on next save
    }

    return const <String, double>{};
  }

  Future<void> saveAll(Map<String, double> targets) async {
    final sanitized = <String, double>{};
    for (final entry in targets.entries) {
      final percent = _clampPercent(entry.value);
      if (percent <= 0) continue;
      sanitized[entry.key] = percent;
    }

    state = AsyncValue.data(Map.unmodifiable(sanitized));
    await _prefs.setString(_prefsKey, jsonEncode(sanitized));
  }

  Future<void> setTarget(String coinId, double percent) async {
    final current = Map<String, double>.from(await future);
    final sanitized = _clampPercent(percent);
    if (sanitized <= 0) {
      current.remove(coinId);
    } else {
      current[coinId] = sanitized;
    }
    await saveAll(current);
  }

  Future<void> removeTarget(String coinId) async {
    final current = Map<String, double>.from(await future);
    if (current.remove(coinId) == null) return;
    await saveAll(current);
  }

  static double _clampPercent(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value.clamp(0.0, 1.0);
  }
}

final portfolioTargetAllocationsProvider = AsyncNotifierProvider<
    PortfolioTargetAllocationsController,
    Map<String, double>>(PortfolioTargetAllocationsController.new);

/// Lookup helper for a specific holding by coin id.
final portfolioHoldingByIdProvider =
    Provider.family<AsyncValue<HoldingEntity?>, String>((ref, coinId) {
  final holdings = ref.watch(portfolioHoldingsProvider);
  return holdings.whenData(
    (list) => _firstWhereOrNull(list, (h) => h.coinId == coinId),
  );
});

HoldingEntity? _firstWhereOrNull(
  Iterable<HoldingEntity> items,
  bool Function(HoldingEntity) test,
) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
