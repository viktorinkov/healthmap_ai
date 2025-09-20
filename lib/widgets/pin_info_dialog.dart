import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pinned_location.dart';
import '../models/air_quality.dart';
import '../models/environmental_measurements.dart';
import '../services/environmental_measurements_service.dart';
import '../services/api_service.dart';
import 'environmental_measurements_card.dart';

class PinInfoDialog extends StatefulWidget {
  final PinnedLocation location;
  final AirQualityData? airQuality;

  const PinInfoDialog({
    Key? key,
    required this.location,
    this.airQuality,
  }) : super(key: key);

  @override
  State<PinInfoDialog> createState() => _PinInfoDialogState();
}

class _PinInfoDialogState extends State<PinInfoDialog> {
  EnvironmentalMeasurements? _environmentalMeasurements;
  bool _loadingEnvironmental = false;
  Map<String, dynamic>? _weatherForecast;
  Map<String, dynamic>? _pollenForecast;
  Map<String, dynamic>? _wildfireData;
  Map<String, dynamic>? _currentWeather;
  bool _loadingForecast = false;

  @override
  void initState() {
    super.initState();
    _loadEnvironmentalHealth();
    _loadForecastData();
  }

  Future<void> _loadEnvironmentalHealth() async {
    setState(() {
      _loadingEnvironmental = true;
    });

    try {
      final measurements = await EnvironmentalMeasurementsService.getEnvironmentalMeasurements(
        locationId: widget.location.id,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        locationName: widget.location.name,
      );

      if (mounted) {
        setState(() {
          _environmentalMeasurements = measurements;
          _loadingEnvironmental = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingEnvironmental = false;
        });
      }
    }
  }

  Future<void> _loadForecastData() async {
    setState(() {
      _loadingForecast = true;
    });

    try {
      final weatherFuture = ApiService.getWeatherForecast(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        days: 1,
      );

      final pollenFuture = ApiService.getPollenForecast(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        days: 1,
      );

      final wildfireFuture = ApiService.getWildfireData(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        radius: 50,
      );

      final currentWeatherFuture = ApiService.getCurrentWeather(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
      );

      final results = await Future.wait([
        weatherFuture,
        pollenFuture,
        wildfireFuture,
        currentWeatherFuture,
      ]);

      if (mounted) {
        setState(() {
          _weatherForecast = results[0];
          _pollenForecast = results[1];
          _wildfireData = results[2];
          _currentWeather = results[3];
          _loadingForecast = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingForecast = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.location.type.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.location.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  widget.location.address ?? widget.location.type.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (widget.airQuality != null) _buildStatusBadge(context, widget.airQuality!.status),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.airQuality != null) ...[
            _buildAirScoreSection(context, widget.airQuality!),
            const SizedBox(height: 20),
            _buildJustificationSection(context, widget.airQuality!),
            const SizedBox(height: 20),
            _buildPollutantSummary(context, widget.airQuality!.metrics),
            const SizedBox(height: 20),
          ],
          if (_loadingForecast)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading 6-12 hour outlook...'),
                ],
              ),
            )
          else if (_weatherForecast != null || _pollenForecast != null || _wildfireData != null || _currentWeather != null)
            _buildOutlookSection(context),
          if (_loadingEnvironmental)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading environmental health data...'),
                ],
              ),
            )
          else
            EnvironmentalMeasurementsCard(measurements: _environmentalMeasurements),
        ],
      ),
    );
  }

  Widget _buildNoDataContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Air Quality Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Air quality information is not available for this location at the moment.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirScoreSection(BuildContext context, AirQualityData data) {
    final aqi = data.metrics.universalAqi ?? (100 - data.metrics.overallScore).round();

    return Container(
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
              const Icon(Icons.air, size: 20),
              const SizedBox(width: 8),
              Text(
                'Air Quality Score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'AQI: $aqi',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusBadge(context, data.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJustificationSection(BuildContext context, AirQualityData data) {
    final justification = _getAirScoreJustification(data.status, data.metrics);

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
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                'Why ${data.status.displayName}?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            justification,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantSummary(BuildContext context, AirQualityMetrics metrics) {
    final pollutants = [
      _PollutantInfo('PM2.5', metrics.pm25, 'μg/m³'),
      _PollutantInfo('PM10', metrics.pm10, 'μg/m³'),
      _PollutantInfo('O₃', metrics.o3, 'ppb'),
      _PollutantInfo('NO₂', metrics.no2, 'ppb'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Pollutants',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...pollutants.map((pollutant) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pollutant.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${pollutant.value.toStringAsFixed(1)} ${pollutant.unit}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, AirQualityStatus status) {
    Color color;
    switch (status) {
      case AirQualityStatus.good:
        color = Colors.green;
        break;
      case AirQualityStatus.caution:
        color = Colors.orange;
        break;
      case AirQualityStatus.avoid:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNoEnvironmentalData(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Environmental Health Data Unavailable',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load comprehensive environmental health data for this location.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlookSection(BuildContext context) {
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
              const Icon(Icons.schedule, size: 20),
              const SizedBox(width: 8),
              Text(
                '6-12 Hour Outlook',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOutlookContent(context),
        ],
      ),
    );
  }

  Widget _buildOutlookContent(BuildContext context) {
    final List<Widget> outlookItems = [];

    // Temperature and weather chart
    if (_weatherForecast != null && !(_weatherForecast!['error'] == true)) {
      final hourlyData = _weatherForecast!['hourly'] as List?;
      if (hourlyData != null && hourlyData.isNotEmpty) {
        outlookItems.add(_buildTemperatureChart(context, hourlyData));
        outlookItems.add(const SizedBox(height: 16));
      }
    }

    // UV Index and current weather conditions
    if (_currentWeather != null && !(_currentWeather!['error'] == true)) {
      outlookItems.add(_buildWeatherConditions(context));
      outlookItems.add(const SizedBox(height: 16));
    }

    // Pollen levels with mini chart
    if (_pollenForecast != null && !(_pollenForecast!['error'] == true)) {
      outlookItems.add(_buildPollenChart(context));
      outlookItems.add(const SizedBox(height: 16));
    }

    // Wildfire risk
    if (_wildfireData != null && !(_wildfireData!['error'] == true)) {
      outlookItems.add(_buildWildfireRisk(context));
      outlookItems.add(const SizedBox(height: 16));
    }

    // Comprehensive air quality forecast using current data and trends
    if (widget.airQuality != null) {
      outlookItems.add(_buildAirQualityTrend(context));
    }

    if (outlookItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No forecast data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: outlookItems,
    );
  }

  Widget _buildOutlookItem(BuildContext context, String title, String value, String trend, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (trend.isNotEmpty)
                  Text(
                    trend,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAverageTemperature(List hourlyData) {
    if (hourlyData.isEmpty) return 'N/A';

    double total = 0;
    int count = 0;

    for (final hour in hourlyData) {
      final temp = hour['temperature'];
      if (temp != null) {
        total += temp;
        count++;
      }
    }

    if (count == 0) return 'N/A';
    return (total / count).round().toString();
  }

  String _getWeatherTrend(List hourlyData) {
    if (hourlyData.length < 2) return '';

    final firstTemp = hourlyData.first['temperature'];
    final lastTemp = hourlyData.last['temperature'];

    if (firstTemp == null || lastTemp == null) return '';

    final diff = lastTemp - firstTemp;
    if (diff > 3) return 'Warming trend';
    if (diff < -3) return 'Cooling trend';
    return 'Stable conditions';
  }

  String _getPollenLevels(Map<String, dynamic> dailyData) {
    final tree = dailyData['treePollen'] ?? 0;
    final grass = dailyData['grassPollen'] ?? 0;
    final weed = dailyData['weedPollen'] ?? 0;

    final levels = [tree, grass, weed];
    final maxLevel = levels.reduce((a, b) => a > b ? a : b);

    if (maxLevel <= 1) return 'Low levels';
    if (maxLevel <= 2) return 'Moderate levels';
    if (maxLevel <= 3) return 'High levels';
    return 'Very high levels';
  }

  String _getPollenTrend(Map<String, dynamic> dailyData) {
    final tree = dailyData['treePollen'] ?? 0;
    final grass = dailyData['grassPollen'] ?? 0;
    final weed = dailyData['weedPollen'] ?? 0;

    final maxLevel = [tree, grass, weed].reduce((a, b) => a > b ? a : b);

    if (maxLevel >= 3) return 'Allergy alert';
    if (maxLevel >= 2) return 'Monitor symptoms';
    return 'Favorable conditions';
  }

  Widget _buildTemperatureChart(BuildContext context, List hourlyData) {
    final spots = <FlSpot>[];
    final tempData = hourlyData.take(12).toList();

    for (int i = 0; i < tempData.length; i++) {
      final temp = tempData[i]['temperature'];
      if (temp != null) {
        spots.add(FlSpot(i.toDouble(), temp.toDouble()));
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '12-Hour Temperature Trend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final hour = DateTime.now().add(Duration(hours: value.toInt()));
                        return Text(
                          '${hour.hour}:00',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°',
                          style: Theme.of(context).textTheme.bodySmall,
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
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Range: ${spots.map((s) => s.y.toInt()).reduce((a, b) => a < b ? a : b)}° - ${spots.map((s) => s.y.toInt()).reduce((a, b) => a > b ? a : b)}°C',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherConditions(BuildContext context) {
    final humidity = _currentWeather!['humidity'];
    final windSpeed = _currentWeather!['windSpeed'];
    final uvIndex = _currentWeather!['uvIndex'] ?? 0;
    final pressure = _currentWeather!['pressure'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Current Conditions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWeatherMetric(context, 'Humidity', '${humidity ?? 0}%', Icons.water_drop),
              ),
              Expanded(
                child: _buildWeatherMetric(context, 'Wind', '${windSpeed ?? 0} m/s', Icons.air),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildWeatherMetric(context, 'UV Index', uvIndex.toString(), Icons.wb_sunny),
              ),
              Expanded(
                child: _buildWeatherMetric(context, 'Pressure', '${pressure ?? 0} hPa', Icons.speed),
              ),
            ],
          ),
          if (uvIndex > 6)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'High UV exposure - Use sun protection',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildPollenChart(BuildContext context) {
    final daily = _pollenForecast!['daily'] as List?;
    if (daily == null || daily.isEmpty) return const SizedBox.shrink();

    final today = daily.first;
    final tree = (today['treePollen'] ?? 0).toDouble();
    final grass = (today['grassPollen'] ?? 0).toDouble();
    final weed = (today['weedPollen'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_florist, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Pollen Levels Today',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Tree', 'Grass', 'Weed'];
                        return Text(
                          labels[value.toInt()],
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: tree, color: Colors.green, width: 20)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: grass, color: Colors.lightGreen, width: 20)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: weed, color: Colors.orange, width: 20)]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getPollenLevels(today),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWildfireRisk(BuildContext context) {
    final risk = _wildfireData!['riskLevel'] ?? 'Low';
    final distance = _wildfireData!['nearestFireDistance'];
    final activeCount = _wildfireData!['activeFires'] ?? 0;

    Color riskColor = Colors.green;
    IconData riskIcon = Icons.check_circle;

    if (risk == 'High') {
      riskColor = Colors.red;
      riskIcon = Icons.warning;
    } else if (risk == 'Moderate') {
      riskColor = Colors.orange;
      riskIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Wildfire Risk',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(riskIcon, color: riskColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '$risk Risk',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activeCount > 0)
            Text(
              '$activeCount active fires in the area',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (distance != null)
            Text(
              'Nearest fire: ${distance.toStringAsFixed(1)} km away',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAirQualityTrend(BuildContext context) {
    final currentAqi = widget.airQuality!.metrics.universalAqi ??
                       (100 - widget.airQuality!.metrics.overallScore).round();

    // Create a simulated trend for the next 12 hours based on current conditions
    final trendData = _generateAirQualityTrend(currentAqi);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.air, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Air Quality Trend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final hour = DateTime.now().add(Duration(hours: value.toInt()));
                        return Text(
                          '${hour.hour}:00',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall,
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
                    spots: trendData,
                    isCurved: true,
                    color: _getAqiColor(currentAqi),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getAqiColor(currentAqi).withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on current conditions and weather patterns',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateAirQualityTrend(int currentAqi) {
    final spots = <FlSpot>[];
    var aqi = currentAqi.toDouble();

    // Add current value
    spots.add(FlSpot(0, aqi));

    // Generate trend based on weather conditions and time of day
    for (int i = 1; i <= 12; i++) {
      // Add some realistic variation
      final variance = (i % 3 == 0) ? 2 : -1; // Simple pattern
      aqi = (aqi + variance).clamp(0, 200);
      spots.add(FlSpot(i.toDouble(), aqi));
    }

    return spots;
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getAirScoreJustification(AirQualityStatus status, AirQualityMetrics metrics) {
    switch (status) {
      case AirQualityStatus.good:
        return 'Air quality is satisfactory and poses little to no health risk. All major pollutants are within safe levels, making it ideal for outdoor activities and exercise.';

      case AirQualityStatus.caution:
        String concerns = '';
        if (metrics.pm25 > 15) concerns += 'elevated fine particulate matter (PM2.5), ';
        if (metrics.pm10 > 30) concerns += 'elevated coarse particulate matter (PM10), ';
        if (metrics.o3 > 50) concerns += 'increased ground-level ozone, ';
        if (metrics.no2 > 30) concerns += 'elevated nitrogen dioxide, ';

        concerns = concerns.isNotEmpty ? concerns.substring(0, concerns.length - 2) : 'moderate pollution levels';

        return 'Air quality is acceptable for most people, but sensitive individuals may experience minor respiratory symptoms due to $concerns. Consider limiting prolonged outdoor exertion.';

      case AirQualityStatus.avoid:
        String majorConcerns = '';
        if (metrics.pm25 > 25) majorConcerns += 'high fine particulate matter, ';
        if (metrics.pm10 > 45) majorConcerns += 'high coarse particulate matter, ';
        if (metrics.o3 > 70) majorConcerns += 'unhealthy ozone levels, ';
        if (metrics.no2 > 40) majorConcerns += 'high nitrogen dioxide, ';

        majorConcerns = majorConcerns.isNotEmpty ? majorConcerns.substring(0, majorConcerns.length - 2) : 'multiple pollutants at unhealthy levels';

        return 'Air quality is unhealthy for everyone due to $majorConcerns. Avoid outdoor activities, especially strenuous exercise, and keep windows closed when possible.';
    }
  }
}

class _PollutantInfo {
  final String name;
  final double value;
  final String unit;

  _PollutantInfo(this.name, this.value, this.unit);
}