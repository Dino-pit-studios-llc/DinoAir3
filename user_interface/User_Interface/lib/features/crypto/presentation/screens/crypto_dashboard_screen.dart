import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:crypto_dash/app/app_routes.dart';
import 'package:crypto_dash/features/market/presentation/providers/market_providers.dart';
import 'package:crypto_dash/features/watchlist/presentation/providers/watchlist_providers.dart';
import 'package:crypto_dash/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:crypto_dash/features/portfolio/presentation/widgets/portfolio_summary_card.dart';
import 'package:crypto_dash/features/market/domain/coin_entity.dart';

class CryptoDashboardScreen extends ConsumerWidget {
  const CryptoDashboardScreen({super.key});

  static final NumberFormat _priceFormat = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(marketAutoRefreshActivatorProvider);
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final holdingsAsync = ref.watch(portfolioHoldingsProvider);
    final watchlistAsync = ref.watch(watchlistCoinsProvider);
    final marketAsync = ref.watch(topCoinsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(topCoinsProvider)
            ..invalidate(watchlistCoinsProvider)
            ..invalidate(portfolioHoldingsProvider)
            ..invalidate(portfolioSummaryProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildPortfolioSection(context, summaryAsync, holdingsAsync),
            const SizedBox(height: 12),
            _buildWatchlistSection(context, watchlistAsync),
            const SizedBox(height: 12),
            _buildMarketHighlightsSection(context, marketAsync),
            const SizedBox(height: 12),
            _buildQuickNavSection(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.assessment_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('Crypto dashboard', style: theme.textTheme.titleLarge),
      ],
    );
  }

  Widget _buildPortfolioSection(BuildContext context, AsyncValue<dynamic> summaryAsync, AsyncValue<dynamic> holdingsAsync) {
    final theme = Theme.of(context);
    final holdingCount = holdingsAsync.maybeWhen(data: (list) => (list as List).length, orElse: () => 0);
    return summaryAsync.when(
      loading: () => const Card(child: SizedBox(height: 110, child: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.redAccent),
          title: const Text('Portfolio summary unavailable'),
          subtitle: Text('$err'),
          trailing: TextButton(onPressed: () => context.go(AppRoutes.cryptoPortfolio), child: const Text('Open')),
        ),
      ),
      data: (summary) {
        if (summary == null) {
          return Card(
            child: ListTile(
              title: const Text('Portfolio'),
              subtitle: Text('You have $holdingCount holdings tracked'),
              trailing: TextButton(onPressed: () => context.go(AppRoutes.cryptoPortfolio), child: const Text('Open')),
            ),
          );
        }
        return PortfolioSummaryCard(
          summary: summary,
          holdingCount: holdingCount,
          dailyChangeValue: summary.dailyChangeValue ?? 0,
          dailyChangePercent: summary.dailyChangePercent ?? 0,
        );
      },
    );
  }

  Widget _buildWatchlistSection(BuildContext context, AsyncValue<List<CoinEntity>> watchlistAsync) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Watchlist preview')),
                TextButton(onPressed: () => context.go(AppRoutes.cryptoWatchlist), child: const Text('See all')),
              ],
            ),
            watchlistAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Failed to load watchlist: $err', style: TextStyle(color: theme.colorScheme.error)),
              ),
              data: (coins) {
                if (coins.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No favorites yet.'),
                  );
                }
                final preview = coins.take(5).toList();
                return Column(
                  children: [
                    for (final c in preview)
                      ListTile(
                        dense: true,
                        title: Text('${c.symbol.toUpperCase()} • ${c.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(_priceFormat.format(c.price)),
                        onTap: () => context.push(AppRoutes.coinDetailPath(c.id), extra: c),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketHighlightsSection(BuildContext context, AsyncValue<List<CoinEntity>> marketAsync) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Market highlights')),
                TextButton(onPressed: () => context.go(AppRoutes.cryptoMarket), child: const Text('See market')),
              ],
            ),
            marketAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Failed to load market data: $err', style: TextStyle(color: theme.colorScheme.error)),
              ),
              data: (coins) {
                if (coins.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No market data available.',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  );
                }
                final top = coins.take(5).toList();
                return Column(
                  children: [
                    for (final c in top)
                      ListTile(
                        dense: true,
                        title: Text('${c.rank ?? '-'} • ${c.name} (${c.symbol.toUpperCase()})'),
                        subtitle: Text('MC ${_abbrNumber(c.marketCap)} • Vol ${_abbrNumber(c.volume24h)}'),
                        trailing: _buildChangePill(context, c),
                        onTap: () => context.push(AppRoutes.coinDetailPath(c.id), extra: c),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePill(BuildContext context, CoinEntity c) {
    final theme = Theme.of(context);
    final isUp = c.change24hPct >= 0;
    final color = isUp ? theme.colorScheme.tertiary : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
      child: Text('${c.change24hPct.toStringAsFixed(2)}%', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildQuickNavSection(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _QuickNavCard(icon: Icons.trending_up, label: 'Market', onTap: () => context.go(AppRoutes.cryptoMarket))),
        const SizedBox(width: 8),
        Expanded(child: _QuickNavCard(icon: Icons.star_border, label: 'Watchlist', onTap: () => context.go(AppRoutes.cryptoWatchlist))),
        const SizedBox(width: 8),
        Expanded(child: _QuickNavCard(icon: Icons.account_balance_wallet_outlined, label: 'Portfolio', onTap: () => context.go(AppRoutes.cryptoPortfolio))),
      ],
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

class _QuickNavCard extends StatelessWidget {
  const _QuickNavCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
