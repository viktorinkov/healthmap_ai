import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/air_quality_forecast.dart';

class AqiOverviewChart extends StatelessWidget {
  final List<AirQualityForecastHour> forecastHours;
  final double height;

  const AqiOverviewChart({
    Key? key,
    required this.forecastHours,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chartData = _prepareChartData();

    if (chartData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No AQI data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
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
                Icons.air,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'AQI Overview (12 Hours)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) => _buildBottomTitle(context, value.toInt()),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => _buildLeftTitle(context, value.toInt()),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                minX: 0,
                maxX: (chartData.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY(chartData),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: _getAqiColor(spot.y.toInt()),
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final hour = forecastHours[touchedSpot.spotIndex];
                        final timeStr = _formatTime(hour.timestamp);
                        final aqiValue = touchedSpot.y.toInt();
                        final category = _getAqiCategory(aqiValue);

                        return LineTooltipItem(
                          '$timeStr\nAQI: $aqiValue\n$category',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onInverseSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(context),
        ],
      ),
    );
  }

  List<FlSpot> _prepareChartData() {
    final List<FlSpot> spots = [];

    for (int i = 0; i < forecastHours.length; i++) {
      final hour = forecastHours[i];
      if (hour.universalAqi != null) {
        spots.add(FlSpot(i.toDouble(), hour.universalAqi!.toDouble()));
      }
    }

    return spots;
  }

  double _getMaxY(List<FlSpot> data) {
    if (data.isEmpty) return 300;

    final maxValue = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Round up to next 50 and add some padding
    return ((maxValue / 50).ceil() * 50 + 50).toDouble();
  }

  Widget _buildBottomTitle(BuildContext context, int value) {
    if (value >= 0 && value < forecastHours.length) {
      final hour = forecastHours[value];
      final timeStr = _formatTime(hour.timestamp);

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          timeStr,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLeftTitle(BuildContext context, int value) {
    return Text(
      value.toString(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 10,
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(context, 'Good', Colors.green, '0-50'),
        _buildLegendItem(context, 'Moderate', Colors.yellow, '51-100'),
        _buildLegendItem(context, 'Unhealthy', Colors.orange, '101-150'),
        _buildLegendItem(context, 'Hazardous', Colors.red, '151+'),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, String range) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          range,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 8,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour$period';
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }

  String _getAqiCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}