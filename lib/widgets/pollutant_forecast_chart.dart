import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/air_quality_forecast.dart';

class PollutantForecastChart extends StatelessWidget {
  final String pollutantCode;
  final List<PollutantForecastPoint> forecastData;
  final double? height;

  const PollutantForecastChart({
    Key? key,
    required this.pollutantCode,
    required this.forecastData,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (forecastData.isEmpty) {
      return _buildNoDataWidget(context);
    }

    final pollutantInfo = PollutantInfo.getPollutantInfo(pollutantCode);
    final displayName = pollutantInfo?.displayName ?? pollutantCode.toUpperCase();
    final unit = pollutantInfo?.unit ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPollutantIcon(pollutantCode),
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '$displayName Forecast',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateGridInterval(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= forecastData.length) {
                          return const SizedBox.shrink();
                        }

                        final point = forecastData[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${point.timestamp.hour}:00',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: _calculateGridInterval(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildSpots(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: _getPollutantColor(pollutantCode),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: _getPollutantColor(pollutantCode),
                          strokeColor: Theme.of(context).colorScheme.surface,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getPollutantColor(pollutantCode).withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: _getMinY(),
                maxY: _getMaxY(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsSummary(context, unit),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    final pollutantInfo = PollutantInfo.getPollutantInfo(pollutantCode);
    final displayName = pollutantInfo?.displayName ?? pollutantCode.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getPollutantIcon(pollutantCode),
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                '$displayName Forecast',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'N/A',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Forecast data not available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return forecastData
        .asMap()
        .entries
        .where((entry) => entry.value.value != null)
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value!))
        .toList();
  }

  double _getMinY() {
    if (forecastData.isEmpty) return 0;
    final values = forecastData
        .where((point) => point.value != null)
        .map((point) => point.value!)
        .toList();
    if (values.isEmpty) return 0;
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min * 0.9).floorToDouble(); // Add 10% padding below
  }

  double _getMaxY() {
    if (forecastData.isEmpty) return 100;
    final values = forecastData
        .where((point) => point.value != null)
        .map((point) => point.value!)
        .toList();
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max * 1.1).ceilToDouble(); // Add 10% padding above
  }

  double _calculateGridInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 50;
    return 100;
  }

  Widget _buildStatsSummary(BuildContext context, String unit) {
    if (forecastData.isEmpty) return const SizedBox.shrink();

    final values = forecastData
        .where((point) => point.value != null)
        .map((point) => point.value!)
        .toList();

    if (values.isEmpty) return const SizedBox.shrink();

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(context, 'Min', '${min.toStringAsFixed(1)} $unit'),
        _buildStatItem(context, 'Avg', '${avg.toStringAsFixed(1)} $unit'),
        _buildStatItem(context, 'Max', '${max.toStringAsFixed(1)} $unit'),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  IconData _getPollutantIcon(String code) {
    switch (code) {
      case 'pm25':
      case 'pm10':
        return Icons.grain;
      case 'o3':
        return Icons.wb_sunny;
      case 'no2':
        return Icons.local_gas_station;
      case 'so2':
        return Icons.cloud;
      case 'co':
        return Icons.smoke_free;
      default:
        return Icons.air;
    }
  }

  Color _getPollutantColor(String code) {
    switch (code) {
      case 'pm25':
        return Colors.purple;
      case 'pm10':
        return Colors.orange;
      case 'o3':
        return Colors.blue;
      case 'no2':
        return Colors.red;
      case 'so2':
        return Colors.green;
      case 'co':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}