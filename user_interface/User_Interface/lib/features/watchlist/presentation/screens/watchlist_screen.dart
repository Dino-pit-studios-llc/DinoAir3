// Watchlist screen showing favorited coins.
import 'package:crypto_dash/app/app_routes.dart';
import 'package:crypto_dash/core/theme/semantic_colors.dart';
import 'package:crypto_dash/features/market/domain/coin_entity.dart';
import 'package:crypto_dash/features/watchlist/presentation/providers/watchlist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistCoinsProvider);

    return Scaffold(
      body: watchlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorState(error: err),
        data: (coins) {
          if (coins.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(watchlistCoinsProvider);
              await ref.read(watchlistCoinsProvider.future);
            },
            child: _WatchlistList(coins: coins),
          );
        },
      ),
    );
  }
}

class _WatchlistList extends ConsumerWidget {
  const _WatchlistList({required this.coins});
  final List<CoinEntity> coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = Theme.of(context).extension<SemanticColors>();

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: coins.length,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final coin = coins[i];
        final gainColor = semantic?.gain ?? Colors.green;
        final lossColor = semantic?.loss ?? Colors.red;
        final changeColor = coin.change24hPct >= 0 ? gainColor : lossColor;

        return ListTile(
          leading: IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () {
              ref.read(watchlistControllerProvider.notifier).toggle(coin.id);
            },
            tooltip: 'Remove from watchlist',
          ),
          title: Text(
            '${coin.rank}. ${coin.name} (${coin.symbol.toUpperCase()})',
          ),
          subtitle: Text(
            'MC: ${_abbrNumber(coin.marketCap)}  Vol: ${_abbrNumber(coin.volume24h)}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${coin.price.toStringAsFixed(2)}'),
              Text(
                '${coin.change24hPct.toStringAsFixed(2)}%',
                style: TextStyle(color: changeColor, fontSize: 12),
              ),
            ],
          ),
          onTap: () {
            context.push(AppRoutes.coinDetailPath(coin.id), extra: coin);
          },
        );
      },
    );
  }

  String _abbrNumber(double n) {
    if (n.abs() < 1000) return n.toStringAsFixed(0);
    const units = ['K', 'M', 'B', 'T'];
    var value = n;
    var unitIndex = -1;
    while (value.abs() >= 1000 && unitIndex < units.length - 1) {
      value /= 1000;
      unitIndex++;
    }
    return '${value.toStringAsFixed(1)}${units[unitIndex]}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('No Favorites Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Tap the star icon on any coin to add it to your watchlist',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  ((theme.colorScheme.onSurface.a * 255.0) * 0.6).round(),
                ),
              ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load watchlist'),
            const SizedBox(height: 8),
            Text('$error', style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}
