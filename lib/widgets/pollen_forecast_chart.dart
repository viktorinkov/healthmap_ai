import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pollen_data.dart' as pollen;

class PollenForecastChart extends StatelessWidget {
  final List<pollen.PollenDailyInfo> pollenForecast;
  final double height;
  final pollen.PollenType? specificType;

  const PollenForecastChart({
    Key? key,
    required this.pollenForecast,
    this.height = 200,
    this.specificType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pollenForecast.isEmpty) {
      return _buildNoDataCard(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_florist, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getChartTitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: _buildChart(context),
            ),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  String _getChartTitle() {
    if (specificType != null) {
      return '${specificType!.displayName} Pollen Forecast';
    }
    return 'Pollen Forecast (5-Day)';
  }

  Widget _buildChart(BuildContext context) {
    final spots = _generateChartData();

    if (spots.isEmpty) {
      return _buildNoDataMessage(context);
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: 1,
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
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < pollenForecast.length) {
                  final date = pollenForecast[index].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Column(
                      children: [
                        Text(
                          '${date.month}/${date.day}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _getDayOfWeek(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 8,
                          ),
                        ),
                      ],
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
                    value.toInt().toString(),
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
        maxX: (pollenForecast.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: _buildLineBars(context),
      ),
    );
  }

  List<FlSpot> _generateChartData() {
    final spots = <FlSpot>[];

    for (int i = 0; i < pollenForecast.length; i++) {
      final daily = pollenForecast[i];
      double value = 0;

      if (specificType != null) {
        // Show specific pollen type
        final typeInfo = daily.pollenTypeInfo.where((t) => t.code == specificType).firstOrNull;
        value = typeInfo?.indexInfo?.value.toDouble() ?? 0;
      } else {
        // Show overall pollen index (highest among all types)
        value = daily.overallPollenIndex.toDouble();
      }

      if (value > 0) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return spots;
  }

  List<LineChartBarData> _buildLineBars(BuildContext context) {
    if (specificType != null) {
      return [_buildSpecificTypeLineBar(context)];
    } else {
      return [
        _buildPollenTypeLineBar(context, pollen.PollenType.grass, const Color(0xFF4CAF50)),
        _buildPollenTypeLineBar(context, pollen.PollenType.tree, const Color(0xFF8D6E63)),
        _buildPollenTypeLineBar(context, pollen.PollenType.weed, const Color(0xFFFF9800)),
      ];
    }
  }

  LineChartBarData _buildSpecificTypeLineBar(BuildContext context) {
    final spots = _generateChartData();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildPollenTypeLineBar(BuildContext context, pollen.PollenType type, Color color) {
    final spots = <FlSpot>[];

    for (int i = 0; i < pollenForecast.length; i++) {
      final daily = pollenForecast[i];
      final typeInfo = daily.pollenTypeInfo.where((t) => t.code == type).firstOrNull;
      final value = typeInfo?.indexInfo?.value.toDouble() ?? 0;

      if (value > 0) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 7, // Only show dots if we have few data points
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    if (specificType != null) {
      return _buildSpecificTypeLegend(context);
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(context, pollen.PollenType.grass.icon, pollen.PollenType.grass.displayName, const Color(0xFF4CAF50)),
        _buildLegendItem(context, pollen.PollenType.tree.icon, pollen.PollenType.tree.displayName, const Color(0xFF8D6E63)),
        _buildLegendItem(context, pollen.PollenType.weed.icon, pollen.PollenType.weed.displayName, const Color(0xFFFF9800)),
      ],
    );
  }

  Widget _buildSpecificTypeLegend(BuildContext context) {
    final todayData = pollenForecast.isNotEmpty ? pollenForecast.first : null;
    final typeInfo = todayData?.pollenTypeInfo.where((t) => t.code == specificType).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (typeInfo != null) ...[
          Row(
            children: [
              Text(
                '${specificType!.icon} Current Level: ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeInfo.indexInfo?.category.color ?? Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  typeInfo.indexInfo?.category.displayName ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (typeInfo.inSeason) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'In season',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.local_florist,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Pollen Data Unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pollen forecast information is not available for this location.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No pollen data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }
}