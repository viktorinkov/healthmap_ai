import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/pinned_location.dart';
import '../../services/api_service.dart';

class LocationChartsScreen extends StatefulWidget {
  final PinnedLocation location;

  const LocationChartsScreen({
    Key? key,
    required this.location,
  }) : super(key: key);

  @override
  State<LocationChartsScreen> createState() => _LocationChartsScreenState();
}

class _LocationChartsScreenState extends State<LocationChartsScreen> {
  bool _isLoading = true;
  Map<String, List<HistoricalDataPoint>> _historicalData = {};

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch 7 days of historical data from backend
      final pinId = int.tryParse(widget.location.id) ?? 0;
      final airQualityHistory = await ApiService.getAirQualityHistory(
        pinId: pinId,
        days: 7
      );
      final weatherHistory = await ApiService.getWeatherHistory(
        pinId: pinId,
        days: 7
      );
      final radonHistory = await ApiService.getRadonHistory(
        pinId: pinId,
        days: 7
      );

      _historicalData = {
        'airQuality': _parseAirQualityHistory(airQualityHistory),
        'weather': _parseWeatherHistory(weatherHistory),
        'radon': _parseRadonHistory(radonHistory),
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading historical data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<HistoricalDataPoint> _parseAirQualityHistory(List<dynamic> data) {
    return data.map((item) {
      return HistoricalDataPoint(
        timestamp: DateTime.parse(item['timestamp']),
        aqi: item['aqi']?.toDouble() ?? 0.0,
        pm25: item['pm25']?.toDouble() ?? 0.0,
        pm10: item['pm10']?.toDouble() ?? 0.0,
        ozone: item['ozone']?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  List<HistoricalDataPoint> _parseWeatherHistory(List<dynamic> data) {
    return data.map((item) {
      return HistoricalDataPoint(
        timestamp: DateTime.parse(item['timestamp']),
        temperature: item['temperature']?.toDouble() ?? 0.0,
        humidity: item['humidity']?.toDouble() ?? 0.0,
        uvIndex: item['uv_index']?.toDouble() ?? 0.0,
        windSpeed: item['wind_speed']?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  List<HistoricalDataPoint> _parseRadonHistory(List<dynamic> data) {
    return data.map((item) {
      return HistoricalDataPoint(
        timestamp: DateTime.parse(item['timestamp']),
        radonLevel: item['radon_level']?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.location.name} - Charts'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationHeader(),
                  const SizedBox(height: 24),

                  if (_historicalData['airQuality']?.isNotEmpty == true) ...[
                    _buildChartCard(
                      'Air Quality Index (AQI)',
                      Icons.air,
                      _buildAQIChart(),
                    ),
                    const SizedBox(height: 16),

                    _buildChartCard(
                      'PM2.5 Levels',
                      Icons.blur_on,
                      _buildPM25Chart(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_historicalData['weather']?.isNotEmpty == true) ...[
                    _buildChartCard(
                      'Temperature',
                      Icons.thermostat,
                      _buildTemperatureChart(),
                    ),
                    const SizedBox(height: 16),

                    _buildChartCard(
                      'Humidity',
                      Icons.water_drop,
                      _buildHumidityChart(),
                    ),
                    const SizedBox(height: 16),

                    _buildChartCard(
                      'UV Index',
                      Icons.wb_sunny,
                      _buildUVChart(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_historicalData['radon']?.isNotEmpty == true) ...[
                    _buildChartCard(
                      'Radon Levels',
                      Icons.home_outlined,
                      _buildRadonChart(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_historicalData.values.every((list) => list?.isEmpty != false))
                    _buildNoDataCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildLocationHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.location.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.location.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '7-Day Historical Data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.location.address != null)
                    Text(
                      widget.location.address!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildChartCard(String title, IconData icon, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
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
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAQIChart() {
    final data = _historicalData['airQuality'] ?? [];
    if (data.isEmpty) return _buildNoDataMessage();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.aqi);
            }).toList(),
            isCurved: true,
            color: _getAQIColor(data.map((e) => e.aqi).reduce((a, b) => a + b) / data.length),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _getAQIColor(data.map((e) => e.aqi).reduce((a, b) => a + b) / data.length).withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPM25Chart() {
    final data = _historicalData['airQuality'] ?? [];
    if (data.isEmpty) return _buildNoDataMessage();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}µg',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.pm25);
            }).toList(),
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    final data = _historicalData['weather'] ?? [];
    if (data.isEmpty) return _buildNoDataMessage();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°C',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.temperature);
            }).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityChart() {
    final data = _historicalData['weather'] ?? [];
    if (data.isEmpty) return _buildNoDataMessage();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.humidity);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUVChart() {
    final data = _historicalData['weather'] ?? [];
    if (data.isEmpty) return _buildNoDataMessage();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.uvIndex);
            }).toList(),
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.amber.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadonChart() {
    final data = _historicalData['radon'] ?? [];
    if (data.isEmpty) return _buildNoDataMessage();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
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
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)} pCi/L',
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.radonLevel);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Historical Data Available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Historical data will be available after monitoring this location for a few days.',
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

  Widget _buildNoDataMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAQIColor(double aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow[700]!;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }
}

class HistoricalDataPoint {
  final DateTime timestamp;
  final double aqi;
  final double pm25;
  final double pm10;
  final double ozone;
  final double temperature;
  final double humidity;
  final double uvIndex;
  final double windSpeed;
  final double radonLevel;

  HistoricalDataPoint({
    required this.timestamp,
    this.aqi = 0.0,
    this.pm25 = 0.0,
    this.pm10 = 0.0,
    this.ozone = 0.0,
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.uvIndex = 0.0,
    this.windSpeed = 0.0,
    this.radonLevel = 0.0,
  });
}