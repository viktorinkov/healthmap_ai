import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather_data.dart';

class WeatherForecastChart extends StatelessWidget {
  final WeatherForecast forecast;

  const WeatherForecastChart({
    Key? key,
    required this.forecast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (forecast.daily.isEmpty) {
      return _buildNoDataCard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTemperatureForecastChart(context),
        const SizedBox(height: 16),
        _buildHumidityForecastChart(context),
        const SizedBox(height: 16),
        _buildWindSpeedForecastChart(context),
        const SizedBox(height: 16),
        _buildPrecipitationForecastChart(context),
        const SizedBox(height: 16),
        _buildUVIndexForecastChart(context),
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
              Icons.wb_sunny_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Weather Forecast Unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Weather forecast data is not available for this location.',
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

  Widget _buildTemperatureForecastChart(BuildContext context) {
    final spots = <FlSpot>[];
    final feelsLikeSpots = <FlSpot>[];

    for (int i = 0; i < forecast.daily.length && i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), forecast.daily[i].temperature));
      feelsLikeSpots.add(FlSpot(i.toDouble(), forecast.daily[i].feelsLike));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5;

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
                  'Temperature Forecast (°C)',
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
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < forecast.daily.length) {
                            final date = forecast.daily[index].timestamp;
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
                  maxX: (forecast.daily.length - 1).toDouble().clamp(0, 6),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
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
            // Check for extreme temperatures
            if (forecast.daily.any((d) => d.heatWaveAlert == true))
              _buildAlertBanner(context, Icons.warning, 'Heat wave conditions expected', Colors.orange),
            if (forecast.daily.any((d) => d.coldWaveAlert == true))
              _buildAlertBanner(context, Icons.ac_unit, 'Cold wave conditions expected', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityForecastChart(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < forecast.daily.length && i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), forecast.daily[i].humidity));
    }

    return _buildSimpleChart(
      context,
      title: 'Humidity Forecast (%)',
      icon: Icons.water_drop,
      spots: spots,
      color: Colors.blue,
      maxY: 100,
      minY: 0,
      interval: 20,
      formatValue: (value) => '${value.toInt()}%',
    );
  }

  Widget _buildWindSpeedForecastChart(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < forecast.daily.length && i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), forecast.daily[i].windSpeed));
    }

    final hasStagnation = forecast.daily.any((d) => d.stagnationEvent == true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.air, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Wind Speed Forecast (m/s)',
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
              color: Colors.teal,
              formatValue: (value) => '${value.toInt()}',
            ),
            if (hasStagnation)
              _buildAlertBanner(
                context,
                Icons.warning_amber,
                'Air stagnation conditions expected - poor pollutant dispersion',
                Colors.amber,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecipitationForecastChart(BuildContext context) {
    final spots = <FlSpot>[];
    bool hasPrecipitation = false;

    for (int i = 0; i < forecast.daily.length && i < 7; i++) {
      final intensity = forecast.daily[i].precipitationIntensity ?? 0.0;
      spots.add(FlSpot(i.toDouble(), intensity));
      if (intensity > 0) hasPrecipitation = true;
    }

    if (!hasPrecipitation) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.umbrella, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    'Precipitation Forecast',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No precipitation expected',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSimpleChart(
      context,
      title: 'Precipitation Forecast (mm)',
      icon: Icons.umbrella,
      spots: spots,
      color: Colors.indigo,
      formatValue: (value) => '${value.toStringAsFixed(1)}',
    );
  }

  Widget _buildUVIndexForecastChart(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < forecast.daily.length && i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), forecast.daily[i].uvIndex));
    }

    return _buildSimpleChart(
      context,
      title: 'UV Index Forecast',
      icon: Icons.wb_sunny,
      spots: spots,
      color: Colors.orange,
      maxY: 12,
      minY: 0,
      interval: 3,
      formatValue: (value) => value.toStringAsFixed(1),
    );
  }

  Widget _buildSimpleChart(
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
    final calculatedMaxY = maxY ?? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;
    final calculatedMinY = minY ?? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.9;

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
              maxY: calculatedMaxY,
              minY: calculatedMinY,
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
    required String Function(double) formatValue,
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
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < forecast.daily.length) {
                    final date = forecast.daily[index].timestamp;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '${date.day}',
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
                      formatValue(value),
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
          maxX: (forecast.daily.length - 1).toDouble().clamp(0, 6),
          minY: calculatedMinY,
          maxY: calculatedMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
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

  Widget _buildAlertBanner(BuildContext context, IconData icon, String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}