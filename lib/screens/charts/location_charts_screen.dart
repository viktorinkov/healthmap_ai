import 'package:flutter/material.dart';
import '../../models/pinned_location.dart';
import '../../models/air_quality.dart';
import '../../services/air_quality_api_service.dart';

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
  AirQualityData? _currentAirQuality;

  @override
  void initState() {
    super.initState();
    _loadCurrentAirQuality();
  }

  Future<void> _loadCurrentAirQuality() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get real-time air quality data from Google API
      final airQuality = await AirQualityApiService.getAirQuality(
        widget.location.latitude,
        widget.location.longitude,
        locationName: widget.location.name,
      );

      setState(() {
        _currentAirQuality = airQuality;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading current air quality: $e');
      setState(() {
        _currentAirQuality = null;
        _isLoading = false;
      });
    }
  }

  // Color helper methods
  Color _getStatusColor(AirQualityStatus status) {
    switch (status) {
      case AirQualityStatus.good:
        return Colors.green;
      case AirQualityStatus.caution:
        return Colors.orange;
      case AirQualityStatus.avoid:
        return Colors.red;
    }
  }

  Color _getPM25Color(double value) {
    if (value <= 12) return Colors.green;
    if (value <= 35) return Colors.yellow[700]!;
    if (value <= 55) return Colors.orange;
    if (value <= 150) return Colors.red;
    return Colors.purple;
  }

  Color _getPM10Color(double value) {
    if (value <= 54) return Colors.green;
    if (value <= 154) return Colors.yellow[700]!;
    if (value <= 254) return Colors.orange;
    if (value <= 354) return Colors.red;
    return Colors.purple;
  }

  Color _getOzoneColor(double value) {
    if (value <= 70) return Colors.green;
    if (value <= 85) return Colors.yellow[700]!;
    if (value <= 105) return Colors.orange;
    if (value <= 200) return Colors.red;
    return Colors.purple;
  }

  Color _getNO2Color(double value) {
    if (value <= 53) return Colors.green;
    if (value <= 100) return Colors.yellow[700]!;
    if (value <= 360) return Colors.orange;
    if (value <= 649) return Colors.red;
    return Colors.purple;
  }

  Color _getCOColor(double value) {
    if (value <= 4400) return Colors.green;
    if (value <= 9400) return Colors.yellow[700]!;
    if (value <= 12400) return Colors.orange;
    if (value <= 15400) return Colors.red;
    return Colors.purple;
  }

  Color _getSO2Color(double value) {
    if (value <= 35) return Colors.green;
    if (value <= 75) return Colors.yellow[700]!;
    if (value <= 185) return Colors.orange;
    if (value <= 304) return Colors.red;
    return Colors.purple;
  }

  Color _getRecommendationLevelColor(HealthAdviceLevel level) {
    switch (level) {
      case HealthAdviceLevel.safe:
        return Colors.green;
      case HealthAdviceLevel.caution:
        return Colors.orange;
      case HealthAdviceLevel.avoid:
        return Colors.red;
    }
  }

  int _getPollutantLevel(String name, double value) {
    switch (name) {
      case 'PM2.5':
        return ((value / 150) * 100).clamp(0, 100).round();
      case 'PM10':
        return ((value / 354) * 100).clamp(0, 100).round();
      case 'Ozone':
        return ((value / 200) * 100).clamp(0, 100).round();
      case 'NO2':
        return ((value / 649) * 100).clamp(0, 100).round();
      case 'CO':
        return ((value / 15400) * 100).clamp(0, 100).round();
      case 'SO2':
        return ((value / 304) * 100).clamp(0, 100).round();
      default:
        return (value.clamp(0, 100)).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.location.name} - Current Data'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentAirQuality,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentAirQuality == null
              ? _buildNoDataCard()
              : RefreshIndicator(
                  onRefresh: _loadCurrentAirQuality,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationHeader(),
                        const SizedBox(height: 24),
                        _buildCurrentDataOverview(),
                        const SizedBox(height: 16),
                        _buildPollutantCards(),
                        const SizedBox(height: 16),
                        if (_currentAirQuality!.healthRecommendations?.isNotEmpty == true)
                          _buildHealthRecommendationsCard(),
                        const SizedBox(height: 16),
                        _buildHistoricalDataMessage(),
                      ],
                    ),
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
                    'Real-time Air Quality Data',
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
                  if (_currentAirQuality != null)
                    Text(
                      'Updated: ${_formatTime(_currentAirQuality!.timestamp)}',
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCurrentDataOverview() {
    if (_currentAirQuality == null) return const SizedBox.shrink();

    final metrics = _currentAirQuality!.metrics;
    final aqi = metrics.universalAqi ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.air,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Air Quality Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile('AQI', aqi.toString(), _getAQIColor(aqi.toDouble())),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile('Status', _currentAirQuality!.status.displayName, _getStatusColor(_currentAirQuality!.status)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentAirQuality!.statusReason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollutantCards() {
    if (_currentAirQuality == null) return const SizedBox.shrink();

    final metrics = _currentAirQuality!.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pollutant Concentrations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPollutantGrid(metrics),
      ],
    );
  }

  Widget _buildPollutantGrid(AirQualityMetrics metrics) {
    final pollutants = <Map<String, dynamic>>[
      {
        'name': 'PM2.5',
        'value': metrics.pm25,
        'unit': 'μg/m³',
        'icon': Icons.blur_on,
        'color': _getPM25Color(metrics.pm25),
      },
      {
        'name': 'PM10',
        'value': metrics.pm10,
        'unit': 'μg/m³',
        'icon': Icons.grain,
        'color': _getPM10Color(metrics.pm10),
      },
      {
        'name': 'Ozone',
        'value': metrics.o3,
        'unit': 'ppb',
        'icon': Icons.wb_sunny_outlined,
        'color': _getOzoneColor(metrics.o3),
      },
      {
        'name': 'NO2',
        'value': metrics.no2,
        'unit': 'ppb',
        'icon': Icons.local_gas_station,
        'color': _getNO2Color(metrics.no2),
      },
      if (metrics.co != null) {
        'name': 'CO',
        'value': metrics.co!,
        'unit': 'ppb',
        'icon': Icons.smoke_free,
        'color': _getCOColor(metrics.co!),
      },
      if (metrics.so2 != null) {
        'name': 'SO2',
        'value': metrics.so2!,
        'unit': 'ppb',
        'icon': Icons.factory,
        'color': _getSO2Color(metrics.so2!),
      },
      if (metrics.nh3 != null) {
        'name': 'NH3',
        'value': metrics.nh3!,
        'unit': 'ppb',
        'icon': Icons.agriculture,
        'color': Colors.brown,
      },
      if (metrics.c6h6 != null) {
        'name': 'Benzene',
        'value': metrics.c6h6!,
        'unit': 'μg/m³',
        'icon': Icons.oil_barrel,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pollutants.length,
      itemBuilder: (context, index) {
        final pollutant = pollutants[index];
        return _buildPollutantCard(
          pollutant['name'],
          pollutant['value'],
          pollutant['unit'],
          pollutant['icon'],
          pollutant['color'],
        );
      },
    );
  }

  Widget _buildPollutantCard(
    String name,
    double value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _getPollutantLevel(name, value),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 100 - _getPollutantLevel(name, value),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecommendationsCard() {
    if (_currentAirQuality?.healthRecommendations?.isEmpty != false) {
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
                Icon(
                  Icons.health_and_safety,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Health Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._currentAirQuality!.healthRecommendations!.map((recommendation) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.population.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.population.displayName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation.recommendation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRecommendationLevelColor(recommendation.level),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recommendation.level.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalDataMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Historical Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Historical air quality trends are not currently available. The Google Air Quality API provides real-time data only. For historical trends, data would need to be collected and stored over time.',
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

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

  Color _getAQIColor(double aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow[700]!;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }
}