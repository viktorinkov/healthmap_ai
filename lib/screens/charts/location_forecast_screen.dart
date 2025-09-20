import 'package:flutter/material.dart';
import '../../models/pinned_location.dart';
import '../../models/weather_data.dart';
import '../../services/weather_api_service.dart' as weather_service;
import '../../widgets/air_quality_forecast_section.dart';
import '../../widgets/pollen_forecast_section.dart';
import '../../widgets/weather_forecast_chart.dart';

class LocationForecastScreen extends StatefulWidget {
  final PinnedLocation location;

  const LocationForecastScreen({
    Key? key,
    required this.location,
  }) : super(key: key);

  @override
  State<LocationForecastScreen> createState() => _LocationForecastScreenState();
}

class _LocationForecastScreenState extends State<LocationForecastScreen> {
  WeatherForecast? _weatherForecast;
  bool _loadingWeatherForecast = true;

  @override
  void initState() {
    super.initState();
    _loadWeatherForecast();
  }

  Future<void> _loadWeatherForecast() async {
    try {
      setState(() {
        _loadingWeatherForecast = true;
      });

      final forecast = await weather_service.WeatherApiService.getWeatherForecast(
        widget.location.latitude,
        widget.location.longitude,
        locationName: widget.location.name,
      );

      setState(() {
        _weatherForecast = forecast;
        _loadingWeatherForecast = false;
      });
    } catch (e) {
      debugPrint('Error loading weather forecast: $e');
      setState(() {
        _weatherForecast = null;
        _loadingWeatherForecast = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.location.name} - Forecast'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger refresh by rebuilding the widget
          setState(() {});
          await _loadWeatherForecast();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Air Quality Forecast',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Predictions for the next 12 hours',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              AirQualityForecastSection(
                latitude: widget.location.latitude,
                longitude: widget.location.longitude,
                locationName: widget.location.name,
              ),
              PollenForecastSection(
                latitude: widget.location.latitude,
                longitude: widget.location.longitude,
                locationName: widget.location.name,
              ),
              const SizedBox(height: 24),
              Text(
                'Weather Forecast',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '7-day meteorological forecast',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingWeatherForecast)
                const Center(child: CircularProgressIndicator())
              else if (_weatherForecast != null)
                WeatherForecastChart(forecast: _weatherForecast!)
              else
                _buildNoWeatherForecastCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoWeatherForecastCard() {
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
}