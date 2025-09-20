import 'package:flutter/material.dart';
import '../models/air_quality_forecast.dart';
import '../services/air_quality_forecast_service.dart';
import 'pollutant_forecast_chart.dart';

class AirQualityForecastSection extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const AirQualityForecastSection({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.locationName,
  }) : super(key: key);

  @override
  State<AirQualityForecastSection> createState() => _AirQualityForecastSectionState();
}

class _AirQualityForecastSectionState extends State<AirQualityForecastSection> {
  AirQualityForecast? _forecast;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForecastData();
  }

  Future<void> _loadForecastData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final forecast = await AirQualityForecastService.getForecast(
        widget.latitude,
        widget.longitude,
        locationName: widget.locationName,
        hoursAhead: 12,
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
          _error = 'Failed to load forecast data';
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
              const Icon(Icons.schedule, size: 20),
              const SizedBox(width: 8),
              Text(
                '12-Hour Air Quality Forecast',
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
          else if (_forecast == null)
            _buildNoDataWidget(context)
          else
            _buildForecastCharts(context),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading forecast data...'),
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
            onPressed: _loadForecastData,
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
            Icons.cloud_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Forecast data not available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Air quality forecast information is currently unavailable for this location.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCharts(BuildContext context) {
    if (_forecast == null) return const SizedBox.shrink();

    // Get available pollutants from the forecast data
    final availablePollutants = _getAvailablePollutants();

    if (availablePollutants.isEmpty) {
      return _buildNoDataWidget(context);
    }

    return Column(
      children: [
        // Summary of next 12 hours
        _buildForecastSummary(context),
        const SizedBox(height: 20),

        // Individual pollutant charts
        ...availablePollutants.map((code) {
          final forecastData = _forecast!.getPollutantForecast(code);

          if (forecastData.isEmpty) {
            return PollutantForecastChart(
              pollutantCode: code,
              forecastData: [],
              height: 180,
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PollutantForecastChart(
              pollutantCode: code,
              forecastData: forecastData,
              height: 180,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildForecastSummary(BuildContext context) {
    if (_forecast == null || _forecast!.next12Hours.isEmpty) {
      return const SizedBox.shrink();
    }

    final next12Hours = _forecast!.next12Hours;
    final aqiValues = next12Hours
        .where((hour) => hour.universalAqi != null)
        .map((hour) => hour.universalAqi!)
        .toList();

    if (aqiValues.isEmpty) {
      return const SizedBox.shrink();
    }

    final minAqi = aqiValues.reduce((a, b) => a < b ? a : b);
    final maxAqi = aqiValues.reduce((a, b) => a > b ? a : b);
    final avgAqi = (aqiValues.reduce((a, b) => a + b) / aqiValues.length).round();

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
                'AQI Overview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAqiStatItem(context, 'Min', minAqi, _getAqiColor(minAqi)),
              _buildAqiStatItem(context, 'Avg', avgAqi, _getAqiColor(avgAqi)),
              _buildAqiStatItem(context, 'Max', maxAqi, _getAqiColor(maxAqi)),
            ],
          ),
          if (maxAqi > 100)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Air quality may be unhealthy during some hours',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAqiStatItem(BuildContext context, String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }

  List<String> _getAvailablePollutants() {
    if (_forecast == null || _forecast!.next12Hours.isEmpty) {
      return [];
    }

    // Get all unique pollutant codes from the forecast data
    final Set<String> allPollutants = {};
    for (final hour in _forecast!.next12Hours) {
      allPollutants.addAll(hour.availablePollutants);
    }

    // Return in preferred order (common pollutants first)
    final preferredOrder = ['pm25', 'pm10', 'o3', 'no2', 'so2', 'co'];
    final List<String> result = [];

    // Add pollutants in preferred order
    for (final code in preferredOrder) {
      if (allPollutants.contains(code)) {
        result.add(code);
      }
    }

    // Add any remaining pollutants
    for (final code in allPollutants) {
      if (!result.contains(code)) {
        result.add(code);
      }
    }

    return result;
  }
}