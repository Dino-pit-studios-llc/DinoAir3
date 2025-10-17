import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../market/domain/coin_entity.dart';
import '../../../market/presentation/providers/market_providers.dart';
import '../../domain/holding_entity.dart';
import '../../domain/portfolio_summary_entity.dart';
import '../providers/portfolio_providers.dart';
import '../widgets/edit_holding_sheet.dart';
import '../widgets/edit_target_allocations_sheet.dart';
import '../widgets/portfolio_holding_tile.dart';
import '../widgets/portfolio_insights_card.dart';
import '../widgets/portfolio_summary_card.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(marketAutoRefreshActivatorProvider);
    final holdingsAsync = ref.watch(portfolioHoldingsProvider);
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final coinsAsync = ref.watch(topCoinsProvider);
    final lastUpdated = ref.watch(marketLastUpdatedProvider);
    final targetAllocationsAsync = ref.watch(
      portfolioTargetAllocationsProvider,
    );
    final controllerState = ref.watch(portfolioControllerProvider);
    final sortOption = ref.watch(portfolioSortOptionProvider);
    final sortController = ref.read(portfolioSortOptionProvider.notifier);

    final coins = coinsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <CoinEntity>[],
    );
    final isBusy = controllerState.isLoading;
    final theme = Theme.of(context);

    final isRefreshing = coinsAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            isBusy ? null : () => _openEditSheet(context, ref, coins: coins),
        icon: const Icon(Icons.add),
        label: const Text('Add holding'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.32),
              theme.colorScheme.surface.withValues(alpha: 0.04),
              theme.colorScheme.surfaceTint.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: holdingsAsync.when(
          loading: () => const _LoadingState(),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (holdings) {
            if (holdings.isEmpty) {
              return _EmptyState(
                onAddPressed: isBusy
                    ? null
                    : () => _openEditSheet(context, ref, coins: coins),
              );
            }

            final coinMap = <String, CoinEntity>{
              for (final coin in coins) coin.id: coin,
            };
            final sortedHoldings = [...holdings];
            _sortHoldings(sortedHoldings, sortOption, coinMap);

            final widgets = <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatLastUpdatedLabel(lastUpdated),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isRefreshing
                              ? const SizedBox(
                                  key: ValueKey('refreshing'),
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  key: const ValueKey('refresh'),
                                  tooltip: 'Refresh market data',
                                  icon: const Icon(Icons.refresh_rounded),
                                  onPressed: () {
                                    ref
                                      ..invalidate(topCoinsProvider)
                                      ..invalidate(portfolioSummaryProvider);
                                  },
                                ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<PortfolioSortOption>(
                          tooltip: 'Sort holdings',
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getSortIcon(sortOption), size: 20),
                              const SizedBox(width: 4),
                              Text(
                                _getSortLabel(sortOption),
                                style: theme.textTheme.labelLarge,
                              ),
                              const Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                          initialValue: sortOption,
                          onSelected: (option) {
                            sortController.select(option);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: PortfolioSortOption.valueDesc,
                              child: Row(
                                children: [
                                  Icon(Icons.trending_down),
                                  SizedBox(width: 12),
                                  Text('Value (High to Low)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: PortfolioSortOption.valueAsc,
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up),
                                  SizedBox(width: 12),
                                  Text('Value (Low to High)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: PortfolioSortOption.gainLossDesc,
                              child: Row(
                                children: [
                                  Icon(Icons.show_chart),
                                  SizedBox(width: 12),
                                  Text('Gain/Loss (High to Low)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: PortfolioSortOption.gainLossAsc,
                              child: Row(
                                children: [
                                  Icon(Icons.trending_flat),
                                  SizedBox(width: 12),
                                  Text('Gain/Loss (Low to High)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: PortfolioSortOption.nameAsc,
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha),
                                  SizedBox(width: 12),
                                  Text('Name (A-Z)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: PortfolioSortOption.nameDesc,
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha),
                                  SizedBox(width: 12),
                                  Text('Name (Z-A)'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ];

            summaryAsync.when(
              data: (summary) {
                final dailyPerformance = _calculatePerformance24h(
                  sortedHoldings,
                  coinMap,
                );
                final weeklyPerformance = _calculatePerformance7d(
                  sortedHoldings,
                  coinMap,
                );
                final targetAllocations = targetAllocationsAsync.maybeWhen(
                  data: (value) => value,
                  orElse: () => const <String, double>{},
                );
                widgets
                  ..add(
                    PortfolioSummaryCard(
                      summary: summary,
                      holdingCount: holdings.length,
                      dailyChangeValue: dailyPerformance.changeValue,
                      dailyChangePercent: dailyPerformance.percent,
                    ),
                  )
                  ..add(
                    PortfolioInsightsCard(
                      holdings: sortedHoldings,
                      coinLookup: coinMap,
                      summary: summary,
                      change24hPercent: dailyPerformance.hasData
                          ? dailyPerformance.percent
                          : null,
                      change7dPercent: weeklyPerformance.hasData
                          ? weeklyPerformance.percent
                          : null,
                      targetAllocations: targetAllocations,
                      targetsLoading: targetAllocationsAsync.isLoading &&
                          targetAllocations.isEmpty,
                      onEditTargets: () => _openTargetAllocationsSheet(
                        context,
                        ref,
                        summary: summary,
                        coinLookup: coinMap,
                        initialTargets: targetAllocations,
                      ),
                    ),
                  )
                  ..add(const SizedBox(height: 8));
              },
              loading: () => widgets.add(const _SummaryLoading()),
              error: (error, stackTrace) =>
                  widgets.add(_SummaryError(error: error)),
            );

            for (final holding in sortedHoldings) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: PortfolioHoldingTile(
                    holding: holding,
                    coin: coinMap[holding.coinId],
                    onEdit: () => _openEditSheet(
                      context,
                      ref,
                      coins: coins,
                      initial: holding,
                    ),
                    onDelete: () => _confirmRemove(context, ref, holding),
                  ),
                ),
              );
            }

            widgets.add(const SizedBox(height: 100));

            return ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              children: widgets,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref, {
    required List<CoinEntity> coins,
    HoldingEntity? initial,
  }) async {
    final result = await showModalBottomSheet<({String coinId, bool isEdit})>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          EditHoldingSheet(initialHolding: initial, coins: coins),
    );

    if (!context.mounted || result == null) return;

    final message = result.isEdit
        ? 'Updated holding for ${result.coinId}'
        : 'Added holding for ${result.coinId}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    HoldingEntity holding,
  ) async {
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove holding'),
            content: Text(
              'Remove ${holding.coinId.toUpperCase()} from portfolio?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRemove) return;

    try {
      await ref
          .read(portfolioControllerProvider.notifier)
          .remove(holding.coinId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Removed ${holding.coinId}')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove holding: $error')),
      );
    }
  }

  Future<void> _openTargetAllocationsSheet(
    BuildContext context,
    WidgetRef ref, {
    required PortfolioSummaryEntity summary,
    required Map<String, CoinEntity> coinLookup,
    required Map<String, double> initialTargets,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditTargetAllocationsSheet(
        summary: summary,
        coinLookup: coinLookup,
        initialTargets: initialTargets,
      ),
    );

    if (!context.mounted || result != true) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Target allocations saved')));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPressed});

  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('No holdings yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Add your first holding to start tracking your portfolio performance.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  ((theme.colorScheme.onSurface.a * 255.0) * 0.7).round(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: since this dashboard is just for you, give holdings custom IDs like "btc-cold" or "eth-yield" to separate wallets.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add holding'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Something went wrong when loading your portfolio.'),
            const SizedBox(height: 12),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to compute summary'),
              const SizedBox(height: 8),
              Text('$error'),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _getSortIcon(PortfolioSortOption option) {
  switch (option) {
    case PortfolioSortOption.valueDesc:
    case PortfolioSortOption.valueAsc:
      return Icons.attach_money;
    case PortfolioSortOption.gainLossDesc:
    case PortfolioSortOption.gainLossAsc:
      return Icons.trending_up;
    case PortfolioSortOption.nameAsc:
    case PortfolioSortOption.nameDesc:
      return Icons.sort_by_alpha;
  }
}

String _getSortLabel(PortfolioSortOption option) {
  switch (option) {
    case PortfolioSortOption.valueDesc:
      return 'Value ↓';
    case PortfolioSortOption.valueAsc:
      return 'Value ↑';
    case PortfolioSortOption.gainLossDesc:
      return 'Gain/Loss ↓';
    case PortfolioSortOption.gainLossAsc:
      return 'Gain/Loss ↑';
    case PortfolioSortOption.nameAsc:
      return 'Name A-Z';
    case PortfolioSortOption.nameDesc:
      return 'Name Z-A';
  }
}

void _sortHoldings(
  List<HoldingEntity> holdings,
  PortfolioSortOption option,
  Map<String, CoinEntity> coinMap,
) {
  holdings.sort((a, b) {
    switch (option) {
      case PortfolioSortOption.valueDesc:
        final valueA = _currentValueFor(a, coinMap[a.coinId]);
        final valueB = _currentValueFor(b, coinMap[b.coinId]);
        return valueB.compareTo(valueA);
      case PortfolioSortOption.valueAsc:
        final valueA = _currentValueFor(a, coinMap[a.coinId]);
        final valueB = _currentValueFor(b, coinMap[b.coinId]);
        return valueA.compareTo(valueB);
      case PortfolioSortOption.gainLossDesc:
        final gainLossA = _gainLossFor(a, coinMap[a.coinId]);
        final gainLossB = _gainLossFor(b, coinMap[b.coinId]);
        return gainLossB.compareTo(gainLossA);
      case PortfolioSortOption.gainLossAsc:
        final gainLossA = _gainLossFor(a, coinMap[a.coinId]);
        final gainLossB = _gainLossFor(b, coinMap[b.coinId]);
        return gainLossA.compareTo(gainLossB);
      case PortfolioSortOption.nameAsc:
        final nameA = coinMap[a.coinId]?.name ?? a.coinId;
        final nameB = coinMap[b.coinId]?.name ?? b.coinId;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      case PortfolioSortOption.nameDesc:
        final nameA = coinMap[a.coinId]?.name ?? a.coinId;
        final nameB = coinMap[b.coinId]?.name ?? b.coinId;
        return nameB.toLowerCase().compareTo(nameA.toLowerCase());
    }
  });
}

double _gainLossFor(HoldingEntity holding, CoinEntity? coin) {
  if (coin == null) return 0.0;
  final currentValue = coin.price * holding.amount;
  final costBasis = holding.avgBuyPrice * holding.amount;
  return currentValue - costBasis;
}

class _PortfolioPerformance {
  const _PortfolioPerformance({
    required this.changeValue,
    required this.percent,
    required this.hasData,
  });

  final double changeValue;
  final double percent;
  final bool hasData;
}

_PortfolioPerformance _calculatePerformance24h(
  List<HoldingEntity> holdings,
  Map<String, CoinEntity> coinMap,
) {
  var totalCurrent = 0.0;
  var totalBase = 0.0;
  var hasData = false;

  for (final holding in holdings) {
    final coin = coinMap[holding.coinId];
    if (coin == null) continue;

    final currentValue = _currentValueFor(holding, coin);
    final changeRatio = coin.change24hPct / 100;
    final denom = 1 + changeRatio;
    if (denom.isNaN || denom.isInfinite || denom.abs() < 1e-9) {
      continue;
    }

    final basePrice = coin.price / denom;
    if (basePrice <= 0) continue;

    totalCurrent += currentValue;
    totalBase += holding.amount * basePrice;
    hasData = true;
  }

  final changeValue = hasData ? totalCurrent - totalBase : 0.0;
  final percent = (hasData && totalBase > 0) ? changeValue / totalBase : 0.0;

  return _PortfolioPerformance(
    changeValue: changeValue,
    percent: percent,
    hasData: hasData && totalBase > 0,
  );
}

_PortfolioPerformance _calculatePerformance7d(
  List<HoldingEntity> holdings,
  Map<String, CoinEntity> coinMap,
) {
  var totalCurrent = 0.0;
  var totalBase = 0.0;
  var hasData = false;

  for (final holding in holdings) {
    final coin = coinMap[holding.coinId];
    final sparkline = coin?.sparkline;
    if (coin == null || sparkline == null || sparkline.isEmpty) continue;

    final basePrice = sparkline.first;
    if (basePrice <= 0) continue;

    totalCurrent += _currentValueFor(holding, coin);
    totalBase += holding.amount * basePrice;
    hasData = true;
  }

  final changeValue = hasData ? totalCurrent - totalBase : 0.0;
  final percent = (hasData && totalBase > 0) ? changeValue / totalBase : 0.0;

  return _PortfolioPerformance(
    changeValue: changeValue,
    percent: percent,
    hasData: hasData && totalBase > 0,
  );
}

double _currentValueFor(HoldingEntity holding, CoinEntity? coin) {
  final price = coin?.price ?? holding.avgBuyPrice;
  return holding.amount * price;
}

String _formatLastUpdatedLabel(DateTime? timestamp) {
  if (timestamp == null) {
    return 'Awaiting live market data…';
  }
  final now = DateTime.now().toUtc();
  final diff = now.difference(timestamp);
  if (diff.inSeconds < 30) {
    return 'Updated just now';
  }
  if (diff.inMinutes < 1) {
    return 'Updated ${diff.inSeconds}s ago';
  }
  if (diff.inMinutes < 60) {
    return 'Updated ${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return 'Updated ${diff.inHours}h ago';
  }
  final formatter = DateFormat('MMM d • h:mm a');
  return 'Updated ${formatter.format(timestamp.toLocal())}';
}
