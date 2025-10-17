import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A minimal sparkline chart for showing price trends.
class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    required this.data,
    required this.color,
    this.width = 80,
    this.height = 40,
    super.key,
  });

  final List<double> data;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    // Find min and max for scaling
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;

    // Avoid division by zero if all values are the same
    final effectiveRange = range == 0 ? 1.0 : range;

    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - (effectiveRange * 0.1),
          maxY: maxY + (effectiveRange * 0.1),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
