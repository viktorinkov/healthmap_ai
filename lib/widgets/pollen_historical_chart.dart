import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PollenHistoricalChart extends StatelessWidget {
  final String pollenType;
  final String unit;
  final List<FlSpot> spots;
  final List<DateTime> dates;

  const PollenHistoricalChart({
    Key? key,
    required this.pollenType,
    required this.unit,
    required this.spots,
    required this.dates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '$pollenType ($unit)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'N/A',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.1;
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) * 0.9;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getPollenIcon(pollenType),
                const SizedBox(width: 8),
                Text(
                  '$pollenType ($unit)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY / 5,
                    verticalInterval: dates.length / 7,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (dates.length / 7).clamp(1, 24),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            final date = dates[index];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY / 5,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  minX: 0,
                  maxX: (dates.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          _getPollenColor(pollenType),
                          _getPollenColor(pollenType).withValues(alpha: 0.7),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _getPollenColor(pollenType).withValues(alpha: 0.3),
                            _getPollenColor(pollenType).withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPollenIcon(String pollenType) {
    String icon;
    switch (pollenType.toLowerCase()) {
      case 'grass':
        icon = '🌾';
        break;
      case 'tree':
        icon = '🌳';
        break;
      case 'weed':
        icon = '🌿';
        break;
      case 'overall':
        icon = '🌼';
        break;
      default:
        icon = '🌸';
        break;
    }
    return Text(icon, style: const TextStyle(fontSize: 20));
  }

  Color _getPollenColor(String pollenType) {
    switch (pollenType.toLowerCase()) {
      case 'grass':
        return const Color(0xFF4CAF50);
      case 'tree':
        return const Color(0xFF8D6E63);
      case 'weed':
        return const Color(0xFFFF9800);
      case 'overall':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF2196F3);
    }
  }
}