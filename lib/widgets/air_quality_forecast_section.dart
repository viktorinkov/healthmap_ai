import 'package:flutter/material.dart';
import '../models/air_quality_forecast.dart';
import '../services/air_quality_forecast_service.dart';
import 'pollutant_forecast_chart.dart';
import 'aqi_overview_chart.dart';

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
        // AQI Overview Chart
        AqiOverviewChart(
          forecastHours: _forecast!.next12Hours,
          height: 250,
        ),
        const SizedBox(height: 20),

        // Individual pollutant charts
        ...availablePollutants.map((code) {
          final forecastData = _forecast!.getPollutantForecast(code);

          if (forecastData.isEmpty) {
            return PollutantForecastChart(
              pollutantCode: code,
              forecastData: const [],
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