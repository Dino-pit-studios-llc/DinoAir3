import 'package:crypto_dash/core/theme/semantic_colors.dart';
import 'package:crypto_dash/features/settings/domain/theme_mode_preference.dart';
import 'package:crypto_dash/features/settings/presentation/providers/theme_providers.dart';
import 'package:crypto_dash/services/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_routes.dart';
import '../../../watchlist/presentation/providers/watchlist_providers.dart';
import '../../domain/coin_entity.dart';
import '../providers/market_providers.dart';

/// Basic Market screen scaffold (F1/F3/F4/F5) using mock repository & provider.
class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  static final NumberFormat _priceFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: r'$',
  );

  Color _sourceColor(MarketDataSource src, ThemeData theme) => switch (src) {
        MarketDataSource.mock => theme.colorScheme.outline,
        MarketDataSource.coingecko => theme.colorScheme.tertiary,
        MarketDataSource.coinmarketcap => theme.colorScheme.primary,
      };

  String _sourceLabel(MarketDataSource src) => switch (src) {
        MarketDataSource.mock => 'Mock Data',
        MarketDataSource.coingecko => 'CoinGecko',
        MarketDataSource.coinmarketcap => 'CoinMarketCap',
      };

  AppThemeMode _nextMode(AppThemeMode current) => switch (current) {
        AppThemeMode.system => AppThemeMode.light,
        AppThemeMode.light => AppThemeMode.dark,
        AppThemeMode.dark => AppThemeMode.system,
      };

  IconData _iconFor(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => Icons.brightness_auto,
        AppThemeMode.light => Icons.light_mode,
        AppThemeMode.dark => Icons.dark_mode,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate auto-refresh side-effect (F5).
    ref.watch(marketAutoRefreshActivatorProvider);
    final coinsAsync = ref.watch(topCoinsProvider);
    final source = ref.watch(marketDataSourceProvider);
    final lastUpdated = ref.watch(marketLastUpdatedProvider);
    final cmcKey = ref.watch(coinMarketCapApiKeyProvider);
    final bool showKeyWarning = source == MarketDataSource.coinmarketcap &&
        (cmcKey == null || cmcKey.isEmpty);
    final themeMode = ref.watch(themeModeControllerProvider);
    final theme = Theme.of(context);
    final semantic = theme.extension<SemanticColors>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Market'),
        actions: [
          IconButton(
            tooltip: 'Cycle theme mode (system / light / dark)',
            icon: Icon(_iconFor(themeMode)),
            onPressed: () {
              final next = _nextMode(themeMode);
              ref.read(themeModeControllerProvider.notifier).set(next);
            },
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              theme.colorScheme.surface.withValues(alpha: 0.05),
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            ref.invalidate(topCoinsProvider);
            await ref.read(topCoinsProvider.future);
          },
          child: coinsAsync.when(
            loading: () => const _LoadingList(),
            error: (err, stack) => _ErrorState(error: err, stack: stack),
            data: (coins) {
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                itemCount: coins.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MarketHeader(
                          coinCount: coins.length,
                          dataSourceChip: _DataSourceChip(
                            label: _sourceLabel(source),
                            color: _sourceColor(source, theme),
                            tooltip: 'Active market data source',
                          ),
                          showKeyWarning: showKeyWarning,
                          lastUpdated: lastUpdated,
                          warningChip: showKeyWarning
                              ? const _WarningChip(
                                  label: 'CMC key missing',
                                  tooltip:
                                      'Add CMC_API_KEY in .env or via --dart-define to use CoinMarketCap',
                                )
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const _MarketTableHeader(),
                        const SizedBox(height: 12),
                      ],
                    );
                  }

                  final coin = coins[index - 1];
                  final rank = coin.rank ?? index;
                  final isInWatchlistAsync = ref.watch(
                    isInWatchlistProvider(coin.id),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MarketRowCard(
                      coin: coin,
                      rank: rank,
                      semantic: semantic,
                      priceFormat: _priceFormat,
                      compactCurrency: _compactCurrency,
                      watchlistState: isInWatchlistAsync,
                      onToggleWatchlist: () {
                        ref
                            .read(watchlistControllerProvider.notifier)
                            .toggle(coin.id);
                      },
                      onTap: () {
                        final entity = _mapToCoinEntity(coin);
                        context.push(
                          AppRoutes.coinDetailPath(coin.id),
                          extra: entity,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Map from the data model to CoinEntity for the detail screen
  CoinEntity _mapToCoinEntity(dynamic coin) {
    return CoinEntity(
      id: coin.id,
      symbol: coin.symbol,
      name: coin.name,
      price: coin.price,
      change24hPct: coin.change24hPct,
      marketCap: coin.marketCap,
      volume24h: coin.volume24h,
      rank: coin.rank,
      sparkline: coin.sparkline,
    );
  }
}

String _formatMarketTimestamp(DateTime? timestamp) {
  if (timestamp == null) return 'Awaiting feed';
  final now = DateTime.now().toUtc();
  final diff = now.difference(timestamp);
  if (diff.inSeconds < 30) return 'Just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return DateFormat('MMM d • h:mm a').format(timestamp.toLocal());
}

class _MarketHeader extends StatelessWidget {
  const _MarketHeader({
    required this.coinCount,
    required this.dataSourceChip,
    required this.showKeyWarning,
    required this.lastUpdated,
    this.warningChip,
  });

  final int coinCount;
  final Widget dataSourceChip;
  final bool showKeyWarning;
  final DateTime? lastUpdated;
  final Widget? warningChip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.92);
    final subTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.38 : 0.52,
            ),
            theme.colorScheme.secondary.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.32,
            ),
            theme.colorScheme.surface.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
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
                      'Live market pulse',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stay ahead of price action with quick-glance stats and a search-ready table.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              dataSourceChip,
            ],
          ),
          if (showKeyWarning && warningChip != null) ...[
            const SizedBox(height: 14),
            warningChip!,
          ],
          const SizedBox(height: 22),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _MetricPill(
                icon: Icons.grid_view_rounded,
                label: 'Tracked assets',
                value: coinCount.toString(),
              ),
              _MetricPill(
                icon: Icons.schedule_outlined,
                label: 'Last updated',
                value: _formatMarketTimestamp(lastUpdated),
              ),
              const _MetricPill(
                icon: Icons.refresh_rounded,
                label: 'Auto-refresh',
                value: 'Every 30s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final helper = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: helper,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
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

class _MarketTableHeader extends StatelessWidget {
  const _MarketTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          const SizedBox(width: 46),
          Expanded(
            flex: 4,
            child: Text(
              'Asset',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Price',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '24h',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _MarketRowCard extends StatelessWidget {
  const _MarketRowCard({
    required this.coin,
    required this.rank,
    required this.semantic,
    required this.priceFormat,
    required this.compactCurrency,
    required this.watchlistState,
    required this.onToggleWatchlist,
    required this.onTap,
  });

  final CoinEntity coin;
  final int rank;
  final SemanticColors? semantic;
  final NumberFormat priceFormat;
  final NumberFormat compactCurrency;
  final AsyncValue<bool> watchlistState;
  final VoidCallback onToggleWatchlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gainColor = semantic?.gain ?? theme.colorScheme.tertiary;
    final lossColor = semantic?.loss ?? theme.colorScheme.error;
    final changeColor = coin.change24hPct >= 0 ? gainColor : lossColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: changeColor.withValues(alpha: 0.09),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              _RankBadge(rank: rank),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${coin.symbol.toUpperCase()} • MC ${compactCurrency.format(coin.marketCap)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceFormat.format(coin.price),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vol ${compactCurrency.format(coin.volume24h)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${coin.change24hPct.toStringAsFixed(2)}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                child: Center(
                  child: watchlistState.when(
                    data: (isInWatchlist) => IconButton(
                      icon: Icon(
                        isInWatchlist ? Icons.star : Icons.star_outline,
                        color: isInWatchlist
                            ? Colors.amber
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                      onPressed: onToggleWatchlist,
                      tooltip: isInWatchlist
                          ? 'Remove from watchlist'
                          : 'Add to watchlist',
                    ),
                    loading: () => const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (error, stack) => Tooltip(
                      message: 'Watchlist unavailable: $error',
                      child: Icon(
                        Icons.error_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      alignment: Alignment.center,
      child: Text('#$rank', style: theme.textTheme.labelLarge),
    );
  }
}

class _DataSourceChip extends StatelessWidget {
  const _DataSourceChip({
    required this.label,
    required this.color,
    this.tooltip,
  });
  final String label;
  final Color color;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color.a * 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: color.a * 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color.darken())),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

class _WarningChip extends StatelessWidget {
  const _WarningChip({required this.label, this.tooltip});
  final String label;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final color = Colors.redAccent;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color.a * 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: color.a * 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
          ),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 12,
      itemBuilder: (context, i) => const ListTile(
        title: _ShimmerBox(width: 140),
        subtitle: _ShimmerBox(width: 200, height: 12),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.stack});
  final Object error;
  final StackTrace stack;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load market data'),
            const SizedBox(height: 8),
            Text('$error', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            const Text('Pull down to retry.'),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width = 80, this.height = 14});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .3]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
