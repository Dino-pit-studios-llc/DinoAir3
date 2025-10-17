import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/portfolio_summary_entity.dart';

class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({
    required this.summary,
    required this.holdingCount,
    required this.dailyChangeValue,
    required this.dailyChangePercent,
    super.key,
  });

  final PortfolioSummaryEntity summary;
  final int holdingCount;
  final double dailyChangeValue;
  final double dailyChangePercent;

  static final NumberFormat _currencyFormat = NumberFormat.simpleCurrency();
  static final NumberFormat _percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pnlColor = summary.unrealizedPnl >= 0
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
    final dailyColor = dailyChangeValue >= 0
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
    final dailyValueLabel = '${dailyChangeValue >= 0 ? '+' : '-'}'
        '${_currencyFormat.format(dailyChangeValue.abs())}';
    final dailyPercentLabel = '${dailyChangePercent >= 0 ? '+' : '-'}'
        '${_percentFormat.format(dailyChangePercent.abs())}';
    final formattedDailyLabel =
        (dailyChangeValue == 0 && dailyChangePercent == 0)
            ? _currencyFormat.format(0)
            : '$dailyValueLabel ($dailyPercentLabel)';

    final gradientBegin = theme.brightness == Brightness.dark
        ? theme.colorScheme.primary.withValues(alpha: 0.42)
        : theme.colorScheme.primary.withValues(alpha: 0.55);
    final gradientEnd = theme.colorScheme.secondary.withValues(alpha: 0.32);
    final surfaceTint = theme.colorScheme.surface.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientBegin, gradientEnd, surfaceTint],
        ),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 38,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total net worth',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.75,
                          ),
                          letterSpacing: 0.9,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(summary.totalValue),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily move',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.66,
                          ),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDailyLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: dailyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 18,
              runSpacing: 16,
              children: [
                _SummaryMetric(
                  icon: Icons.inventory_2_outlined,
                  label: 'Holdings tracked',
                  value: '$holdingCount holdings',
                ),
                _SummaryMetric(
                  icon: Icons.ssid_chart,
                  label: 'Unrealized P&L',
                  value: _currencyFormat.format(summary.unrealizedPnl),
                  valueColor: pnlColor,
                ),
                _SummaryMetric(
                  icon: Icons.percent_rounded,
                  label: 'Return',
                  value: _percentFormat.format(summary.unrealizedPnlPct),
                  valueColor: pnlColor,
                ),
                _SummaryMetric(
                  icon: Icons.payments_outlined,
                  label: 'Cost basis',
                  value: _currencyFormat.format(summary.totalCostBasis),
                ),
              ],
            ),
            if (summary.allocations.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Current allocations',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: summary.allocations.map((allocation) {
                  final percentLabel = _percentFormat.format(
                    allocation.percent,
                  );
                  final valueLabel = _currencyFormat.format(
                    allocation.value,
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(
                        alpha: 0.22,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.06,
                        ),
                      ),
                    ),
                    child: Text(
                      '${allocation.coinId.toUpperCase()}  •  $percentLabel  •  $valueLabel',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary.withValues(alpha: 0.86);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.66),
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: valueColor ?? foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
