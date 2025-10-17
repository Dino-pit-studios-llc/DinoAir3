// Price chart widget using fl_chart for coin detail screen.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/coin_entity.dart';

class CoinPriceChart extends StatelessWidget {
  // '24H', '7D', '30D', '90D'

  const CoinPriceChart({
    required this.coin,
    required this.timeRange,
    super.key,
  });
  final CoinEntity coin;
  final String timeRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sparkline = coin.sparkline;

    if (sparkline == null || sparkline.isEmpty) {
      return _buildEmptyState(theme);
    }

    final isPositive = coin.change24hPct >= 0;
    final chartColor =
        isPositive ? theme.colorScheme.primary : theme.colorScheme.error;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(sparkline),
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: sparkline.length / 4,
                getTitlesWidget: (value, meta) =>
                    _buildBottomLabel(value.toInt(), sparkline.length, theme),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: _calculateInterval(sparkline),
                getTitlesWidget: (value, meta) => _buildLeftLabel(value, theme),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sparkline.length - 1).toDouble(),
          minY: _getMinY(sparkline),
          maxY: _getMaxY(sparkline),
          lineBarsData: [
            LineChartBarData(
              spots: _generateSpots(sparkline),
              isCurved: true,
              color: chartColor,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    chartColor.withValues(alpha: 0.3),
                    chartColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('No chart data available')),
    );
  }

  List<FlSpot> _generateSpots(List<double> data) {
    return List.generate(
      data.length,
      (index) => FlSpot(index.toDouble(), data[index]),
    );
  }

  double _getMinY(List<double> data) {
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    // If flat line or inverted by rounding, pad symmetrically around value
    if (minVal == maxVal) {
      final pad = (minVal.abs() > 0 ? minVal.abs() : 1) * 0.005;
      return minVal - pad;
    }
    return minVal - (maxVal - minVal) * 0.005;
  }

  double _getMaxY(List<double> data) {
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (minVal == maxVal) {
      final pad = (maxVal.abs() > 0 ? maxVal.abs() : 1) * 0.005;
      return maxVal + pad;
    }
    return maxVal + (maxVal - minVal) * 0.005;
  }

  double _calculateInterval(List<double> data) {
    final range = _getMaxY(data) - _getMinY(data);
    return range == 0 ? 1.0 : range / 5; // Guard against zero interval
  }

  Widget _buildBottomLabel(int index, int total, ThemeData theme) {
    // Show labels at start, quarter points, half, three-quarters, and end
    if (index == 0 ||
        index == total ~/ 4 ||
        index == total ~/ 2 ||
        index == (3 * total) ~/ 4 ||
        index == total - 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          _formatTimeLabel(index, total),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLeftLabel(double value, ThemeData theme) {
    return Text(
      _formatPrice(value),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 10,
      ),
    );
  }

  String _formatTimeLabel(int index, int total) {
    final hoursPerPoint = _getHoursPerPoint();
    // Calculate hours ago from the end of the dataset.
    final hoursAgo = ((total - 1 - index) * hoursPerPoint).round();

    if (timeRange == '24H') {
      if (hoursAgo == 0) return 'Now';
      return '-${hoursAgo}h';
    } else {
      // For 7D, 30D, 90D
      final daysAgo = hoursAgo ~/ 24;
      if (daysAgo == 0 && timeRange == '7D') return 'Now';
      if (daysAgo == 0) return 'Today';
      return '-${daysAgo}d';
    }
  }

  double _getHoursPerPoint() {
    switch (timeRange) {
      case '24H':
        return 24 / (coin.sparkline?.length ?? 24);
      case '7D':
        return 168 / (coin.sparkline?.length ?? 168); // 7 * 24
      case '30D':
        return 720 / (coin.sparkline?.length ?? 720); // 30 * 24
      case '90D':
        return 2160 / (coin.sparkline?.length ?? 2160); // 90 * 24
      default:
        return 1;
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(1)}K';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(0)}';
    } else if (price >= 0.01) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(4)}';
    }
  }
}
