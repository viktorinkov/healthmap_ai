import 'package:flutter/material.dart';
import '../models/weather_data.dart';

class WeatherConditionsSection extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherConditionsSection({
    Key? key,
    required this.weatherData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Meteorological Conditions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMainConditionsCard(context),
        const SizedBox(height: 16),
        _buildDetailedMetricsGrid(context),
        if (_hasExtremeConditions()) ...[
          const SizedBox(height: 16),
          _buildExtremeConditionsAlert(context),
        ],
      ],
    );
  }

  Widget _buildMainConditionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMainMetric(
                  context,
                  Icons.thermostat,
                  'Temperature',
                  '${weatherData.temperature.toStringAsFixed(1)}°C',
                  'Feels like ${weatherData.feelsLike.toStringAsFixed(1)}°C',
                  _getTemperatureColor(weatherData.temperature),
                ),
                _buildMainMetric(
                  context,
                  Icons.water_drop,
                  'Humidity',
                  '${weatherData.humidity.toInt()}%',
                  weatherData.humidityStatus,
                  _getHumidityColor(weatherData.humidity),
                ),
                _buildMainMetric(
                  context,
                  Icons.air,
                  'Wind',
                  '${weatherData.windSpeed.toStringAsFixed(1)} m/s',
                  weatherData.windStatus,
                  _getWindColor(weatherData.windSpeed),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getWeatherIcon(weatherData.icon),
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weatherData.description,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Updated: ${_formatTime(weatherData.timestamp)}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildMainMetric(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetricsGrid(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricTile(
                  context,
                  Icons.speed,
                  'Pressure',
                  '${weatherData.pressure.toInt()} hPa',
                  Colors.purple,
                ),
                _buildMetricTile(
                  context,
                  Icons.wb_sunny,
                  'UV Index',
                  weatherData.uvIndex.toStringAsFixed(1),
                  _getUVColor(weatherData.uvIndex),
                ),
                _buildMetricTile(
                  context,
                  Icons.visibility,
                  'Visibility',
                  '${(weatherData.visibility / 1000).toStringAsFixed(1)} km',
                  _getVisibilityColor(weatherData.visibility),
                ),
                _buildMetricTile(
                  context,
                  Icons.cloud,
                  'Cloud Cover',
                  '${weatherData.cloudCover.toInt()}%',
                  Colors.grey,
                ),
                _buildMetricTile(
                  context,
                  Icons.water,
                  'Dew Point',
                  '${weatherData.dewPoint.toStringAsFixed(1)}°C',
                  Colors.cyan,
                ),
                _buildMetricTile(
                  context,
                  Icons.navigation,
                  'Wind Dir',
                  '${_getWindDirection(weatherData.windDirection)}',
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtremeConditionsAlert(BuildContext context) {
    final alerts = <Widget>[];

    if (weatherData.heatWaveAlert == true) {
      alerts.add(_buildAlertCard(
        context,
        Icons.local_fire_department,
        'Heat Wave Alert',
        'Extreme heat conditions detected. Stay hydrated and avoid prolonged outdoor exposure.',
        Colors.red,
      ));
    }

    if (weatherData.coldWaveAlert == true) {
      alerts.add(_buildAlertCard(
        context,
        Icons.ac_unit,
        'Cold Wave Alert',
        'Extreme cold conditions detected. Dress warmly and limit outdoor exposure.',
        Colors.blue,
      ));
    }

    if (weatherData.stagnationEvent == true) {
      alerts.add(_buildAlertCard(
        context,
        Icons.warning_amber,
        'Air Stagnation Event',
        'Poor air circulation detected. Pollutants may accumulate. Monitor air quality closely.',
        Colors.amber,
      ));
    }

    if (weatherData.isHighHumidity) {
      alerts.add(_buildAlertCard(
        context,
        Icons.water_drop_outlined,
        'High Humidity Alert',
        'Very high humidity levels. Heat stress risk increased. Stay in air-conditioned areas.',
        Colors.teal,
      ));
    }

    if (weatherData.isLowVisibility) {
      alerts.add(_buildAlertCard(
        context,
        Icons.visibility_off,
        'Low Visibility Warning',
        'Severely reduced visibility. Exercise caution if traveling.',
        Colors.grey,
      ));
    }

    if (weatherData.precipitationIntensity != null && weatherData.precipitationIntensity! > 10) {
      alerts.add(_buildAlertCard(
        context,
        Icons.umbrella,
        'Heavy Precipitation',
        'Heavy ${weatherData.precipitationType ?? "precipitation"} detected. Take appropriate precautions.',
        Colors.indigo,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather Alerts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        ...alerts,
      ],
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    IconData icon,
    String title,
    String message,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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

  bool _hasExtremeConditions() {
    return weatherData.heatWaveAlert == true ||
        weatherData.coldWaveAlert == true ||
        weatherData.stagnationEvent == true ||
        weatherData.isHighHumidity ||
        weatherData.isLowVisibility ||
        (weatherData.precipitationIntensity != null && weatherData.precipitationIntensity! > 10);
  }

  Color _getTemperatureColor(double temp) {
    if (temp > 35) return Colors.red;
    if (temp > 30) return Colors.orange;
    if (temp > 25) return Colors.amber;
    if (temp > 20) return Colors.green;
    if (temp > 15) return Colors.teal;
    if (temp > 10) return Colors.cyan;
    if (temp > 5) return Colors.blue;
    return Colors.indigo;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity > 80) return Colors.teal;
    if (humidity > 60) return Colors.cyan;
    if (humidity > 40) return Colors.blue;
    return Colors.amber;
  }

  Color _getWindColor(double windSpeed) {
    if (windSpeed < 2) return Colors.red; // Stagnant
    if (windSpeed < 5) return Colors.orange;
    if (windSpeed < 10) return Colors.green;
    if (windSpeed < 15) return Colors.teal;
    return Colors.purple;
  }

  Color _getUVColor(double uvIndex) {
    if (uvIndex <= 2) return Colors.green;
    if (uvIndex <= 5) return Colors.yellow[700]!;
    if (uvIndex <= 7) return Colors.orange;
    if (uvIndex <= 10) return Colors.red;
    return Colors.purple;
  }

  Color _getVisibilityColor(double visibility) {
    if (visibility >= 10000) return Colors.green;
    if (visibility >= 5000) return Colors.yellow[700]!;
    if (visibility >= 2000) return Colors.orange;
    return Colors.red;
  }

  String _getWindDirection(double degrees) {
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return '${directions[index]} (${degrees.toInt()}°)';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    if (iconCode.contains('01')) return Icons.wb_sunny;
    if (iconCode.contains('02')) return Icons.wb_cloudy;
    if (iconCode.contains('03')) return Icons.cloud;
    if (iconCode.contains('04')) return Icons.cloud_queue;
    if (iconCode.contains('09')) return Icons.grain;
    if (iconCode.contains('10')) return Icons.beach_access;
    if (iconCode.contains('11')) return Icons.flash_on;
    if (iconCode.contains('13')) return Icons.ac_unit;
    if (iconCode.contains('50')) return Icons.blur_on;
    return Icons.wb_sunny;
  }
}