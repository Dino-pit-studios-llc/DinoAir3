import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../market/domain/coin_entity.dart';
import '../../domain/holding_entity.dart';
import '../../domain/portfolio_summary_entity.dart';

class PortfolioInsightsCard extends StatelessWidget {
  const PortfolioInsightsCard({
    required this.holdings,
    required this.coinLookup,
    required this.summary,
    this.change24hPercent,
    this.change7dPercent,
    this.targetAllocations = const <String, double>{},
    this.targetsLoading = false,
    this.onEditTargets,
    super.key,
  });

  final List<HoldingEntity> holdings;
  final Map<String, CoinEntity> coinLookup;
  final PortfolioSummaryEntity summary;
  final double? change24hPercent;
  final double? change7dPercent;
  final Map<String, double> targetAllocations;
  final bool targetsLoading;
  final VoidCallback? onEditTargets;

  static final NumberFormat _currencyFormat = NumberFormat.simpleCurrency();
  static final NumberFormat _percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 1,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holdingsCount = holdings.length;
    final topAllocation = summary.allocations.isEmpty
        ? null
        : summary.allocations.reduce(
            (curr, next) => curr.percent >= next.percent ? curr : next,
          );

    final snapshots = holdings
        .map(
          (holding) => _HoldingSnapshot.from(
            holding: holding,
            coin: coinLookup[holding.coinId],
          ),
        )
        .whereType<_HoldingSnapshot>()
        .toList(growable: false);

    final bestPerformer = snapshots.isEmpty
        ? null
        : snapshots.reduce(
            (curr, next) =>
                curr.unrealizedPnl >= next.unrealizedPnl ? curr : next,
          );
    final worstPerformer = snapshots.isEmpty
        ? null
        : snapshots.reduce(
            (curr, next) =>
                curr.unrealizedPnl <= next.unrealizedPnl ? curr : next,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceTint.withValues(alpha: 0.26),
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.32),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.22),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio intelligence',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'One-owner dashboard: tag positions however you like and monitor drift in real time.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You’re the sole user, so feel free to label holdings however you like—'
              'add suffixes such as "-cold" or "-yield" to distinguish wallets.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (change24hPercent != null)
                  _InsightMetric(
                    icon: Icons.query_stats,
                    label: 'Performance 24h',
                    value: _formatPercent(change24hPercent!),
                    accentColor: _performanceColor(theme, change24hPercent!),
                    helper: 'vs yesterday',
                  ),
                if (change7dPercent != null)
                  _InsightMetric(
                    icon: Icons.calendar_view_week,
                    label: 'Performance 7d',
                    value: _formatPercent(change7dPercent!),
                    accentColor: _performanceColor(theme, change7dPercent!),
                    helper: 'rolling window',
                  ),
                _InsightMetric(
                  icon: Icons.inventory_2_outlined,
                  label: 'Holdings tracked',
                  value: '$holdingsCount',
                  helper: 'Unique positions',
                ),
                if (topAllocation != null)
                  _InsightMetric(
                    icon: Icons.pie_chart_outline,
                    label: 'Largest allocation',
                    value:
                        '${topAllocation.coinId.toUpperCase()} • ${_percentFormat.format(topAllocation.percent)}',
                    helper: _currencyFormat.format(topAllocation.value),
                  ),
                if (bestPerformer != null)
                  _InsightMetric(
                    icon: Icons.trending_up,
                    label: 'Top performer',
                    value:
                        '${bestPerformer.displayName} • ${_currencyFormat.format(bestPerformer.currentValue)}',
                    helper: _formatSigned(bestPerformer.unrealizedPnl),
                    accentColor: _pnlColor(theme, bestPerformer.unrealizedPnl),
                  ),
                if (worstPerformer != null &&
                    worstPerformer.holdingId != bestPerformer?.holdingId)
                  _InsightMetric(
                    icon: Icons.trending_down,
                    label: 'Needs attention',
                    value:
                        '${worstPerformer.displayName} • ${_currencyFormat.format(worstPerformer.currentValue)}',
                    helper: _formatSigned(worstPerformer.unrealizedPnl),
                    accentColor: _pnlColor(theme, worstPerformer.unrealizedPnl),
                  ),
              ],
            ),
            if (onEditTargets != null ||
                targetsLoading ||
                targetAllocations.isNotEmpty) ...[
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Target allocations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (onEditTargets != null)
                    FilledButton.tonalIcon(
                      onPressed: onEditTargets,
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Edit targets'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (targetsLoading && targetAllocations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (targetAllocations.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: theme.colorScheme.surface.withValues(alpha: 0.24),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  child: Text(
                    'No targets set yet. Tap “Edit targets” to define your perfect allocation mix.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                _TargetAllocationsOverview(
                  summary: summary,
                  targets: targetAllocations,
                  coinLookup: coinLookup,
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatSigned(double value) {
    final formatted = _currencyFormat.format(value.abs());
    return value >= 0 ? '+$formatted' : '-$formatted';
  }

  static String _formatPercent(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'N/A';
    }
    if (value.abs() < 1e-6) {
      return _percentFormat.format(0);
    }
    final formatted = _percentFormat.format(value.abs());
    return value > 0 ? '+$formatted' : '-$formatted';
  }

  static Color _pnlColor(ThemeData theme, double pnl) {
    if (pnl >= 0) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }

  static Color _performanceColor(ThemeData theme, double percent) {
    if (percent >= 0) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }

  static Color _diffColor(ThemeData theme, double diff) {
    if (diff >= 0) return theme.colorScheme.primary;
    return theme.colorScheme.error;
  }
}

class _HoldingSnapshot {
  const _HoldingSnapshot({
    required this.holdingId,
    required this.displayName,
    required this.currentValue,
    required this.unrealizedPnl,
  });

  factory _HoldingSnapshot.from({
    required HoldingEntity holding,
    CoinEntity? coin,
  }) {
    final price = coin?.price ?? holding.avgBuyPrice;
    final currentValue = holding.amount * price;
    final costBasis = holding.amount * holding.avgBuyPrice;
    final pnl = currentValue - costBasis;
    final displayName = coin?.name ?? holding.coinId.toUpperCase();
    return _HoldingSnapshot(
      holdingId: holding.coinId,
      displayName: displayName,
      currentValue: currentValue,
      unrealizedPnl: pnl,
    );
  }

  final String holdingId;
  final String displayName;
  final double currentValue;
  final double unrealizedPnl;
}

class _TargetAllocationsOverview extends StatelessWidget {
  const _TargetAllocationsOverview({
    required this.summary,
    required this.targets,
    required this.coinLookup,
  });

  final PortfolioSummaryEntity summary;
  final Map<String, double> targets;
  final Map<String, CoinEntity> coinLookup;

  static final NumberFormat _percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 1,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualMap = {
      for (final allocation in summary.allocations)
        allocation.coinId: allocation.percent,
    };
    final drifts = targets.entries.map((entry) {
      final actual = actualMap[entry.key] ?? 0.0;
      return _AllocationDrift(
        coinId: entry.key,
        displayName: coinLookup[entry.key]?.name ?? entry.key.toUpperCase(),
        actual: actual,
        target: entry.value,
        diff: actual - entry.value,
        hasHolding: actualMap.containsKey(entry.key),
      );
    }).toList()
      ..sort((a, b) => b.diff.abs().compareTo(a.diff.abs()));

    final overweight = drifts.firstWhere(
      (drift) => drift.diff > 0.002,
      orElse: () => _AllocationDrift.empty,
    );
    final underweight = drifts.firstWhere(
      (drift) => drift.diff < -0.002,
      orElse: () => _AllocationDrift.empty,
    );

    final coverage = targets.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final coverageHelper = _buildCoverageHelper(coverage);
    final coverageColor = coverage > 1.0
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    final untargetedHoldings = summary.allocations
        .where((allocation) => !targets.containsKey(allocation.coinId))
        .map((allocation) => allocation.coinId.toUpperCase())
        .toList(growable: false);
    final orphanTargets = drifts
        .where((drift) => !drift.hasHolding)
        .map((drift) => drift.displayName)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _InsightMetric(
              icon: Icons.donut_large_outlined,
              label: 'Targets coverage',
              value: _percentFormat.format(coverage.clamp(0, 1.5)),
              helper: coverageHelper,
              accentColor: coverageColor,
            ),
            if (!overweight.isEmpty)
              _InsightMetric(
                icon: Icons.trending_up,
                label: 'Over target',
                value:
                    '${overweight.displayName} • ${_percentFormat.format(overweight.actual)}',
                helper:
                    'Target ${_percentFormat.format(overweight.target)} (${PortfolioInsightsCard._formatPercent(overweight.diff)})',
                accentColor: PortfolioInsightsCard._diffColor(
                  theme,
                  overweight.diff,
                ),
              ),
            if (!underweight.isEmpty)
              _InsightMetric(
                icon: Icons.flag_outlined,
                label: 'Needs allocation',
                value:
                    '${underweight.displayName} • ${_percentFormat.format(underweight.actual)}',
                helper:
                    'Target ${_percentFormat.format(underweight.target)} (${PortfolioInsightsCard._formatPercent(underweight.diff)})',
                accentColor: PortfolioInsightsCard._diffColor(
                  theme,
                  underweight.diff,
                ),
              ),
          ],
        ),
        if (untargetedHoldings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'No targets for: ${_truncateList(untargetedHoldings)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (orphanTargets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Targets without holdings: ${_truncateList(orphanTargets)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  static String _buildCoverageHelper(double coverage) {
    if (coverage <= 0.0001) {
      return 'No targets assigned yet';
    }
    if (coverage < 1.0) {
      final remaining = 1 - coverage;
      return '${_percentFormat.format(remaining)} unassigned';
    }
    if (coverage > 1.02) {
      return '${_percentFormat.format(coverage - 1)} above 100%';
    }
    return 'Almost perfectly allocated';
  }

  static String _truncateList(List<String> values, {int max = 3}) {
    if (values.length <= max) {
      return values.join(', ');
    }
    final shown = values.take(max).join(', ');
    return '$shown, +${values.length - max} more';
  }
}

class _AllocationDrift {
  const _AllocationDrift({
    required this.coinId,
    required this.displayName,
    required this.actual,
    required this.target,
    required this.diff,
    required this.hasHolding,
  });

  final String coinId;
  final String displayName;
  final double actual;
  final double target;
  final double diff;
  final bool hasHolding;

  bool get isEmpty => coinId.isEmpty;

  static const _AllocationDrift empty = _AllocationDrift(
    coinId: '',
    displayName: '',
    actual: 0,
    target: 0,
    diff: 0,
    hasHolding: false,
  );
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface.withValues(alpha: 0.28),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.055),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(
              helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
