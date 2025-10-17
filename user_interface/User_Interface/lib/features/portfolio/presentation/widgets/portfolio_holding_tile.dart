import 'package:crypto_dash/core/theme/semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../market/domain/coin_entity.dart';
import '../../domain/holding_entity.dart';
import 'mini_sparkline.dart';

class PortfolioHoldingTile extends StatelessWidget {
  const PortfolioHoldingTile({
    required this.holding,
    this.coin,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final HoldingEntity holding;
  final CoinEntity? coin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final NumberFormat _currencyFormat = NumberFormat.simpleCurrency();
  static final NumberFormat _percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPrice = coin?.price ?? holding.avgBuyPrice;
    final currentValue = holding.amount * currentPrice;
    final costBasis = holding.amount * holding.avgBuyPrice;
    final pnl = currentValue - costBasis;
    final pnlPct = costBasis > 0 ? pnl / costBasis : 0.0;
    final semantic = theme.extension<SemanticColors>();
    final positiveColor = semantic?.gain ?? theme.colorScheme.tertiary;
    final negativeColor = semantic?.loss ?? theme.colorScheme.error;
    final pnlColor = pnl >= 0 ? positiveColor : negativeColor;

    Widget statPill({
      required IconData icon,
      required String label,
      required String value,
      Color? color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface.withValues(alpha: 0.28),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  color ?? theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.24),
          theme.colorScheme.surface.withValues(alpha: 0.08),
          theme.colorScheme.primary.withValues(alpha: 0.14),
        ],
      ),
      border: Border.all(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 18),
        ),
      ],
    );

    final pnlLabel = '${pnl >= 0 ? '+' : ''}${_currencyFormat.format(pnl)}'
        ' (${_percentFormat.format(pnlPct)})';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Ink(
          decoration: boxDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.35),
                        theme.colorScheme.secondary.withValues(alpha: 0.25),
                      ],
                    ),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _symbolLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                                  coin?.name ?? holding.coinId.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: theme.colorScheme.surface
                                            .withValues(alpha: 0.28),
                                      ),
                                      child: Text(
                                        (coin?.symbol ?? holding.coinId)
                                            .toUpperCase(),
                                        style: theme.textTheme.labelMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${holding.coinId.toUpperCase()}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormat.format(currentValue),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pnlLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: pnlColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (coin?.sparkline != null &&
                                      (coin?.sparkline?.isNotEmpty ?? false))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: MiniSparkline(
                                        data: coin!.sparkline!,
                                        color: pnlColor,
                                        width: 60,
                                        height: 24,
                                      ),
                                    ),
                                  Text(
                                    'Now ${_currencyFormat.format(currentPrice)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<_HoldingAction>(
                            tooltip: 'Holding options',
                            offset: const Offset(0, 8),
                            onSelected: (selection) {
                              switch (selection) {
                                case _HoldingAction.edit:
                                  onEdit();
                                case _HoldingAction.delete:
                                  onDelete();
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<_HoldingAction>(
                                value: _HoldingAction.edit,
                                child: Text('Edit position'),
                              ),
                              PopupMenuItem<_HoldingAction>(
                                value: _HoldingAction.delete,
                                child: Text('Remove holding'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          statPill(
                            icon: Icons.layers_rounded,
                            label: 'Units',
                            value: holding.amount.toStringAsFixed(4),
                          ),
                          statPill(
                            icon: Icons.attach_money,
                            label: 'Avg buy',
                            value: _currencyFormat.format(holding.avgBuyPrice),
                          ),
                          statPill(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Cost basis',
                            value: _currencyFormat.format(costBasis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _symbolLabel {
    final raw = (coin?.symbol ?? holding.coinId).toUpperCase();
    if (raw.length <= 3) return raw;
    return raw.substring(0, 3);
  }
}

enum _HoldingAction { edit, delete }
