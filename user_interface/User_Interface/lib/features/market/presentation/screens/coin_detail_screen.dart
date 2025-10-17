// Coin detail screen showing price, chart, and stats for a single coin.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../watchlist/presentation/providers/watchlist_providers.dart';
import '../../domain/coin_entity.dart';
import '../widgets/coin_price_chart.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  // Optional - passed from list for instant display

  const CoinDetailScreen({required this.coinId, this.coin, super.key});
  final String coinId;
  final CoinEntity? coin;

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  String _selectedTimeRange = '24H';

  @override
  Widget build(BuildContext context) {
    final coin = widget.coin;
    final isInWatchlistAsync = ref.watch(isInWatchlistProvider(widget.coinId));

    if (coin == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.coinId)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Coin details unavailable. Navigate from the market list to see more information.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(coin.symbol.toUpperCase()),
        actions: [
          isInWatchlistAsync.when(
            data: (isInWatchlist) => IconButton(
              icon: Icon(
                isInWatchlist ? Icons.star : Icons.star_outline,
                color: isInWatchlist ? Colors.amber : null,
              ),
              onPressed: () {
                ref
                    .read(watchlistControllerProvider.notifier)
                    .toggle(widget.coinId);
              },
              tooltip:
                  isInWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(coin),
            const Divider(),
            _buildTimeRangeSelector(),
            CoinPriceChart(coin: coin, timeRange: _selectedTimeRange),
            const Divider(),
            _buildStatsGrid(coin),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CoinEntity coin) {
    final theme = Theme.of(context);
    final isPositive = coin.change24hPct >= 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(coin.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '\$${coin.price.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${coin.change24hPct.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '24h',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    ((theme.colorScheme.onSurface.a * 255.0) * 0.6).round(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    const List<String> timeRanges = ['24H', '7D', '30D', '90D'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          for (int i = 0; i < timeRanges.length; i++) ...[
            _TimeRangeChip(
              label: timeRanges[i],
              isSelected: _selectedTimeRange == timeRanges[i],
              onSelected: () =>
                  setState(() => _selectedTimeRange = timeRanges[i]),
            ),
            if (i != timeRanges.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(CoinEntity coin) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _StatCard(
                label: 'Market Cap',
                value: '\$${_formatLargeNumber(coin.marketCap)}',
              ),
              _StatCard(
                label: '24h Volume',
                value: '\$${_formatLargeNumber(coin.volume24h)}',
              ),
              if (coin.rank != null)
                _StatCard(label: 'Market Cap Rank', value: '#${coin.rank}'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(0);
  }
}

class _TimeRangeChip extends StatelessWidget {
  const _TimeRangeChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(
                ((theme.colorScheme.onSurface.a * 255.0) * 0.6).round(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
