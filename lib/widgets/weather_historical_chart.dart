import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather_data.dart';

class WeatherHistoricalChart extends StatelessWidget {
  final List<WeatherData> historicalData;

  const WeatherHistoricalChart({
    Key? key,
    required this.historicalData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (historicalData.isEmpty) {
      return _buildNoDataCard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meteorological History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTemperatureHistoryChart(context),
        const SizedBox(height: 16),
        _buildHumidityHistoryChart(context),
        const SizedBox(height: 16),
        _buildWindSpeedHistoryChart(context),
        const SizedBox(height: 16),
        _buildPressureHistoryChart(context),
        const SizedBox(height: 16),
        _buildUVIndexHistoryChart(context),
        const SizedBox(height: 16),
        _buildExtremeConditionsSummary(context),
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
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Weather History Unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Historical weather data is not available for this location.',
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

  Widget _buildTemperatureHistoryChart(BuildContext context) {
    final tempSpots = <FlSpot>[];
    final feelsLikeSpots = <FlSpot>[];

    for (int i = 0; i < historicalData.length; i++) {
      tempSpots.add(FlSpot(i.toDouble(), historicalData[i].temperature));
      feelsLikeSpots.add(FlSpot(i.toDouble(), historicalData[i].feelsLike));
    }

    final maxY = tempSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5;
    final minY = tempSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Temperature History (°C)',
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
                    horizontalInterval: 5,
                    verticalInterval: historicalData.length / 7,
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
                        interval: (historicalData.length / 7).clamp(1, 24),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < historicalData.length) {
                            final date = historicalData[index].timestamp;
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
                        interval: 5,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()}°',
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
                  maxX: (historicalData.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: tempSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    LineChartBarData(
                      spots: feelsLikeSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.secondary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, 'Actual', Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                _buildLegendItem(context, 'Feels Like', Theme.of(context).colorScheme.secondary, dashed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityHistoryChart(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < historicalData.length; i++) {
      spots.add(FlSpot(i.toDouble(), historicalData[i].humidity));
    }

    return _buildSimpleHistoryChart(
      context,
      title: 'Humidity History (%)',
      icon: Icons.water_drop,
      spots: spots,
      color: Colors.blue,
      maxY: 100,
      minY: 0,
      interval: 20,
      formatValue: (value) => '${value.toInt()}%',
    );
  }

  Widget _buildWindSpeedHistoryChart(BuildContext context) {
    final spots = <FlSpot>[];
    final stagnationEvents = <int>[];

    for (int i = 0; i < historicalData.length; i++) {
      spots.add(FlSpot(i.toDouble(), historicalData[i].windSpeed));
      if (historicalData[i].stagnationEvent == true) {
        stagnationEvents.add(i);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.air, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Wind Speed History (m/s)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChartContent(context, spots: spots, color: Colors.teal),
            if (stagnationEvents.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${stagnationEvents.length} stagnation events detected in history',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPressureHistoryChart(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < historicalData.length; i++) {
      spots.add(FlSpot(i.toDouble(), historicalData[i].pressure));
    }

    return _buildSimpleHistoryChart(
      context,
      title: 'Atmospheric Pressure (hPa)',
      icon: Icons.speed,
      spots: spots,
      color: Colors.purple,
      formatValue: (value) => value.toInt().toString(),
    );
  }

  Widget _buildUVIndexHistoryChart(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < historicalData.length; i++) {
      spots.add(FlSpot(i.toDouble(), historicalData[i].uvIndex));
    }

    return _buildSimpleHistoryChart(
      context,
      title: 'UV Index History',
      icon: Icons.wb_sunny,
      spots: spots,
      color: Colors.orange,
      maxY: 12,
      minY: 0,
      interval: 3,
      formatValue: (value) => value.toStringAsFixed(1),
    );
  }

  Widget _buildExtremeConditionsSummary(BuildContext context) {
    final heatWaveDays = historicalData.where((d) => d.heatWaveAlert == true).length;
    final coldWaveDays = historicalData.where((d) => d.coldWaveAlert == true).length;
    final stagnationDays = historicalData.where((d) => d.stagnationEvent == true).length;
    final highHumidityDays = historicalData.where((d) => d.humidity > 80).length;

    if (heatWaveDays == 0 && coldWaveDays == 0 && stagnationDays == 0 && highHumidityDays == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Extreme Conditions Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (heatWaveDays > 0)
              _buildConditionRow(context, Icons.local_fire_department, 'Heat wave conditions', '$heatWaveDays days', Colors.red),
            if (coldWaveDays > 0)
              _buildConditionRow(context, Icons.ac_unit, 'Cold wave conditions', '$coldWaveDays days', Colors.blue),
            if (stagnationDays > 0)
              _buildConditionRow(context, Icons.air, 'Air stagnation events', '$stagnationDays days', Colors.amber),
            if (highHumidityDays > 0)
              _buildConditionRow(context, Icons.water_drop, 'High humidity (>80%)', '$highHumidityDays days', Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionRow(BuildContext context, IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHistoryChart(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<FlSpot> spots,
    required Color color,
    double? maxY,
    double? minY,
    double? interval,
    required String Function(double) formatValue,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChartContent(
              context,
              spots: spots,
              color: color,
              maxY: maxY,
              minY: minY,
              interval: interval,
              formatValue: formatValue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent(
    BuildContext context, {
    required List<FlSpot> spots,
    required Color color,
    double? maxY,
    double? minY,
    double? interval,
    String Function(double)? formatValue,
  }) {
    final calculatedMaxY = maxY ?? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;
    final calculatedMinY = minY ?? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.9;
    final calculatedInterval = interval ?? (calculatedMaxY - calculatedMinY) / 5;

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: calculatedInterval,
            verticalInterval: historicalData.length / 7,
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
                interval: (historicalData.length / 7).clamp(1, 24),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < historicalData.length) {
                    final date = historicalData[index].timestamp;
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
                interval: calculatedInterval,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      formatValue?.call(value) ?? value.toStringAsFixed(1),
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
          maxX: (historicalData.length - 1).toDouble(),
          minY: calculatedMinY,
          maxY: calculatedMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, {bool dashed = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            border: dashed ? Border(
              top: BorderSide(
                color: color,
                width: 2,
                style: BorderStyle.solid,
              ),
            ) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}