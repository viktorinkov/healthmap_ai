import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_api_service.dart';
import 'weather_forecast_chart.dart';

class WeatherForecastSection extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const WeatherForecastSection({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.locationName,
  }) : super(key: key);

  @override
  State<WeatherForecastSection> createState() => _WeatherForecastSectionState();
}

class _WeatherForecastSectionState extends State<WeatherForecastSection> {
  WeatherForecast? _forecast;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final forecast = await WeatherApiService.getWeatherForecast(
        widget.latitude,
        widget.longitude,
        days: 5,
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
          _error = 'Failed to load weather forecast';
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
              const Icon(Icons.wb_sunny, size: 20),
              const SizedBox(width: 8),
              Text(
                '5-Day Weather Forecast',
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
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading weather forecast...'),
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
            onPressed: _loadWeatherData,
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
            'Weather forecast not available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weather forecast information is currently unavailable for this location.',
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

    return Column(
      children: [
        // Today's weather overview
        _buildTodaysOverview(context),
        const SizedBox(height: 20),

        // Full weather forecast chart
        WeatherForecastChart(
          forecast: _forecast!,
        ),
      ],
    );
  }

  Widget _buildTodaysOverview(BuildContext context) {
    if (_forecast == null || _forecast!.daily.isEmpty) {
      return const SizedBox.shrink();
    }

    final today = _forecast!.daily.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Weather',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherMetricCard(
                    context,
                    'Temperature',
                    '${today.temperature.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeatherMetricCard(
                    context,
                    'Humidity',
                    '${today.humidity.toStringAsFixed(0)}%',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeatherMetricCard(
                    context,
                    'Wind',
                    '${today.windSpeed.toStringAsFixed(1)} m/s',
                    Icons.air,
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherMetricCard(
                    context,
                    'UV Index',
                    today.uvIndex.toStringAsFixed(1),
                    Icons.wb_sunny,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeatherMetricCard(
                    context,
                    'Pressure',
                    '${today.pressure.toStringAsFixed(0)} hPa',
                    Icons.speed,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeatherMetricCard(
                    context,
                    'Visibility',
                    '${(today.visibility / 1000).toStringAsFixed(1)} km',
                    Icons.visibility,
                    Colors.grey,
                  ),
                ),
              ],
            ),
            // Weather alerts
            if (today.heatWaveAlert == true || today.coldWaveAlert == true || today.stagnationEvent == true) ...[
              const SizedBox(height: 16),
              _buildWeatherAlerts(context, today),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
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

  Widget _buildWeatherAlerts(BuildContext context, WeatherData today) {
    final alerts = <Widget>[];

    if (today.heatWaveAlert == true) {
      alerts.add(_buildAlertBanner(
        context,
        Icons.local_fire_department,
        'Heat Wave Alert - Extreme temperatures expected',
        Colors.red,
      ));
    }

    if (today.coldWaveAlert == true) {
      alerts.add(_buildAlertBanner(
        context,
        Icons.ac_unit,
        'Cold Wave Alert - Extreme cold temperatures expected',
        Colors.blue,
      ));
    }

    if (today.stagnationEvent == true) {
      alerts.add(_buildAlertBanner(
        context,
        Icons.air_outlined,
        'Air Stagnation Alert - Poor air circulation expected',
        Colors.amber,
      ));
    }

    return Column(
      children: alerts.map((alert) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: alert,
      )).toList(),
    );
  }

  Widget _buildAlertBanner(BuildContext context, IconData icon, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
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