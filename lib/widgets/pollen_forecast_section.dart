import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/weather_api_service.dart';

class PollenForecastSection extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const PollenForecastSection({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.locationName,
  }) : super(key: key);

  @override
  State<PollenForecastSection> createState() => _PollenForecastSectionState();
}

class _PollenForecastSectionState extends State<PollenForecastSection> {
  PollenForecast? _forecast;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPollenData();
  }

  Future<void> _loadPollenData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final forecast = await WeatherApiService.getPollenForecast(
        widget.latitude,
        widget.longitude,
        locationName: widget.locationName,
      );

      if (mounted) {
        setState(() {
          _forecast = forecast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load pollen data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_florist, size: 20),
              const SizedBox(width: 8),
              Text(
                '5-Day Pollen Forecast',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading && _forecast == null)
            _buildLoadingWidget(context)
          else if (_error != null)
            _buildErrorWidget(context)
          else if (_forecast == null || _forecast!.dailyForecasts.isEmpty)
            _buildNoDataWidget(context)
          else
            _buildForecastContent(context),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading pollen data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadPollenData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.local_florist,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Pollen forecast not available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pollen forecast information is currently unavailable for this location.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastContent(BuildContext context) {
    if (_forecast == null || _forecast!.dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Today's pollen overview
        _buildTodaysOverview(context),
        const SizedBox(height: 20),

        // Pollen chart
        _buildPollenChart(context),
      ],
    );
  }

  Widget _buildTodaysOverview(BuildContext context) {
    if (_forecast == null || _forecast!.dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final today = _forecast!.dailyForecasts.first;
    final treePollen = today.levels['tree'] ?? 0.0;
    final grassPollen = today.levels['grass'] ?? 0.0;
    final weedPollen = today.levels['weed'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Pollen Levels',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPollenMetricCard(
                    context,
                    'Tree',
                    treePollen.toStringAsFixed(0),
                    _getPollenColor(treePollen),
                    Icons.park,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPollenMetricCard(
                    context,
                    'Grass',
                    grassPollen.toStringAsFixed(0),
                    _getPollenColor(grassPollen),
                    Icons.grass,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPollenMetricCard(
                    context,
                    'Weed',
                    weedPollen.toStringAsFixed(0),
                    _getPollenColor(weedPollen),
                    Icons.eco,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRiskColor(today.risk).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRiskColor(today.risk).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _getRiskColor(today.risk),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overall Risk: ${today.risk}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getRiskColor(today.risk),
                      fontWeight: FontWeight.w500,
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

  Widget _buildPollenMetricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPollenChart(BuildContext context) {
    if (_forecast == null || _forecast!.dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final treeSpots = <FlSpot>[];
    final grassSpots = <FlSpot>[];
    final weedSpots = <FlSpot>[];

    for (int i = 0; i < _forecast!.dailyForecasts.length && i < 5; i++) {
      final day = _forecast!.dailyForecasts[i];
      treeSpots.add(FlSpot(i.toDouble(), day.levels['tree'] ?? 0.0));
      grassSpots.add(FlSpot(i.toDouble(), day.levels['grass'] ?? 0.0));
      weedSpots.add(FlSpot(i.toDouble(), day.levels['weed'] ?? 0.0));
    }

    final maxY = [
      ...treeSpots.map((s) => s.y),
      ...grassSpots.map((s) => s.y),
      ...weedSpots.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b) * 1.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5-Day Pollen Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                          if (index >= 0 && index < _forecast!.dailyForecasts.length) {
                            final date = _forecast!.dailyForecasts[index].date;
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
                  maxX: (_forecast!.dailyForecasts.length - 1).toDouble().clamp(0, 4),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: treeSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: grassSpots,
                      isCurved: true,
                      color: Colors.brown,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: weedSpots,
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
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
                _buildLegendItem(context, 'Tree', Colors.green),
                const SizedBox(width: 16),
                _buildLegendItem(context, 'Grass', Colors.brown),
                const SizedBox(width: 16),
                _buildLegendItem(context, 'Weed', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
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

  Color _getPollenColor(double level) {
    if (level >= 4) return Colors.red;
    if (level >= 3) return Colors.orange;
    if (level >= 2) return Colors.yellow[700]!;
    if (level >= 1) return Colors.green;
    return Colors.grey;
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'very high':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      case 'very low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}