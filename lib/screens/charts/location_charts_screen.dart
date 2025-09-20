import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/pinned_location.dart';
import '../../models/air_quality.dart';
import '../../models/weather_data.dart';
import '../../services/air_quality_api_service.dart';
import '../../services/weather_api_service.dart' as weather_service;
import '../../widgets/weather_historical_chart.dart';
import '../../widgets/weather_conditions_section.dart';

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
  List<AirQualityData>? _historicalData;
  bool _loadingHistorical = false;
  WeatherData? _currentWeather;
  List<WeatherData>? _weatherHistoricalData;
  bool _loadingWeatherHistorical = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAirQuality();
    _loadHistoricalData();
    _loadCurrentWeather();
    _loadWeatherHistoricalData();
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
        title: Text('${widget.location.name} - History'),
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
                        // Air Quality Historical Data
                        if (_loadingHistorical)
                          _buildLoadingHistoricalCard()
                        else if (_historicalData != null && _historicalData!.isNotEmpty)
                          _buildHistoricalCharts()
                        else
                          _buildNoHistoricalDataCard(),

                        // Meteorological Conditions Section
                        const SizedBox(height: 24),
                        if (_currentWeather != null) ...[
                          WeatherConditionsSection(weatherData: _currentWeather!),
                          const SizedBox(height: 24),
                        ],

                        // Weather Historical Data
                        if (_loadingWeatherHistorical)
                          _buildLoadingWeatherCard()
                        else if (_weatherHistoricalData != null && _weatherHistoricalData!.isNotEmpty)
                          WeatherHistoricalChart(historicalData: _weatherHistoricalData!)
                        else
                          _buildNoWeatherDataCard(),
                      ],
                    ),
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

  Future<void> _loadCurrentWeather() async {
    try {
      final weather = await weather_service.WeatherApiService.getCurrentWeather(
        widget.location.latitude,
        widget.location.longitude,
        locationName: widget.location.name,
      );

      setState(() {
        _currentWeather = weather;
      });
    } catch (e) {
      debugPrint('Error loading current weather: $e');
      setState(() {
        _currentWeather = null;
      });
    }
  }

  Future<void> _loadWeatherHistoricalData() async {
    try {
      setState(() {
        _loadingWeatherHistorical = true;
      });

      final historicalData = await weather_service.WeatherApiService.getHistoricalWeather(
        widget.location.latitude,
        widget.location.longitude,
        locationName: widget.location.name,
      );

      setState(() {
        _weatherHistoricalData = historicalData;
        _loadingWeatherHistorical = false;
      });
    } catch (e) {
      debugPrint('Error loading weather historical data: $e');
      setState(() {
        _weatherHistoricalData = null;
        _loadingWeatherHistorical = false;
      });
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      setState(() {
        _loadingHistorical = true;
      });

      final historicalData = await AirQualityApiService.getHistoricalAirQuality(
        widget.location.latitude,
        widget.location.longitude,
        locationName: widget.location.name,
      );

      setState(() {
        _historicalData = historicalData;
        _loadingHistorical = false;
      });
    } catch (e) {
      debugPrint('Error loading historical air quality: $e');
      setState(() {
        _historicalData = null;
        _loadingHistorical = false;
      });
    }
  }

  Widget _buildLoadingHistoricalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading Historical Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching 7-day air quality history...',
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

  Widget _buildNoHistoricalDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Historical Data N/A',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Historical air quality data is not available for this location.',
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

  Widget _buildHistoricalCharts() {
    if (_historicalData == null || _historicalData!.isEmpty) {
      return _buildNoHistoricalDataCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Historical Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Core pollutants (always present)
        _buildPollutantChart('PM2.5', 'μg/m³', (AirQualityData data) => data.metrics.pm25),
        const SizedBox(height: 16),
        _buildPollutantChart('PM10', 'μg/m³', (AirQualityData data) => data.metrics.pm10),
        const SizedBox(height: 16),
        _buildPollutantChart('Ozone (O₃)', 'ppb', (AirQualityData data) => data.metrics.o3),
        const SizedBox(height: 16),
        _buildPollutantChart('NO₂', 'ppb', (AirQualityData data) => data.metrics.no2),

        // Optional pollutants
        if (_historicalData!.any((AirQualityData data) => data.metrics.co != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('CO', 'ppb', (AirQualityData data) => data.metrics.co ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.so2 != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('SO₂', 'ppb', (data) => data.metrics.so2 ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.nox != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('NOx', 'ppb', (data) => data.metrics.nox ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.no != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('NO', 'ppb', (data) => data.metrics.no ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.nh3 != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('NH₃', 'ppb', (data) => data.metrics.nh3 ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.c6h6 != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('Benzene (C₆H₆)', 'μg/m³', (data) => data.metrics.c6h6 ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.ox != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('Ox', 'ppb', (data) => data.metrics.ox ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.nmhc != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('NMHC', 'ppb', (data) => data.metrics.nmhc ?? 0),
        ],
        if (_historicalData!.any((data) => data.metrics.trs != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('TRS', 'μg/m³', (data) => data.metrics.trs ?? 0),
        ],

        // Additional metrics
        const SizedBox(height: 16),
        _buildPollutantChart('Wildfire Index', '0-100', (data) => data.metrics.wildfireIndex),
        const SizedBox(height: 16),
        _buildPollutantChart('Radon', 'pCi/L', (data) => data.metrics.radon),
        if (_historicalData!.any((data) => data.metrics.universalAqi != null)) ...[
          const SizedBox(height: 16),
          _buildPollutantChart('Universal AQI', '0-500', (data) => (data.metrics.universalAqi ?? 0).toDouble()),
        ],

        // Pollen data section
        const SizedBox(height: 24),
        Text(
          'Pollen Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPollenDataUnavailableCard(),
      ],
    );
  }

  Widget _buildPollenDataUnavailableCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.local_florist,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Historical Pollen Data N/A',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Historical pollen data is not available through the Google Pollen API. Please check the forecast section for current and upcoming pollen levels.',
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

  Widget _buildLoadingWeatherCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading Weather Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching meteorological conditions...',
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

  Widget _buildNoWeatherDataCard() {
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
              'Weather Data Unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Meteorological data is not available for this location.',
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

  Widget _buildPollutantChart(String name, String unit, double Function(AirQualityData) valueExtractor) {
    final spots = <FlSpot>[];

    for (int i = 0; i < _historicalData!.length; i++) {
      final data = _historicalData![i];
      final value = valueExtractor(data);
      if (value > 0) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    if (spots.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '$name ($unit)',
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
            Text(
              '$name ($unit)',
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
                    verticalInterval: _historicalData!.length / 7,
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
                        interval: (_historicalData!.length / 7).clamp(1, 24),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _historicalData!.length) {
                            final data = _historicalData![index];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${data.timestamp.day}/${data.timestamp.month}',
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
                              value.toStringAsFixed(1),
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
                  maxX: (_historicalData!.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
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
                      dotData: const FlDotData(
                        show: false,
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
}