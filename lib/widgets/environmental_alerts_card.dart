import 'package:flutter/material.dart';

class EnvironmentalAlertsCard extends StatelessWidget {
  final Map<String, dynamic> environmentalData;
  final bool isLoading;

  const EnvironmentalAlertsCard({
    Key? key,
    required this.environmentalData,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading environmental data...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (environmentalData.isEmpty || environmentalData.containsKey('error')) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.warning_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Environmental data unavailable',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to fetch current environmental conditions. Please check your connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final weather = environmentalData['weather'] as Map<String, dynamic>?;
    final airQuality = environmentalData['airQuality'] as Map<String, dynamic>?;
    final pollen = environmentalData['pollen'] as Map<String, dynamic>?;
    final wildfire = environmentalData['wildfire'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environmental Conditions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Air Quality Section
            if (airQuality != null && !airQuality.containsKey('error'))
              _buildAirQualitySection(context, airQuality),

            // Weather Section with enhanced data
            if (weather != null && !weather.containsKey('error'))
              _buildWeatherSection(context, weather),

            // Pollen Section
            if (pollen != null && !pollen.containsKey('error'))
              _buildPollenSection(context, pollen),

            // Wildfire Section
            if (wildfire != null && !wildfire.containsKey('error'))
              _buildWildfireSection(context, wildfire),

            // Weather Alerts
            if (weather != null && weather['alerts'] != null)
              _buildWeatherAlerts(context, weather['alerts']),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualitySection(BuildContext context, Map<String, dynamic> airQuality) {
    final aqi = airQuality['aqi']?.toString() ?? 'No data';
    final category = airQuality['category'] ?? 'Unknown';
    final pm25 = airQuality['pm25']?.toString() ?? 'No data';
    final pm10 = airQuality['pm10']?.toString() ?? 'No data';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.air, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Air Quality',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataPoint(context, 'AQI', aqi, null),
            _buildDataPoint(context, 'PM2.5', pm25, 'µg/m³'),
            _buildDataPoint(context, 'PM10', pm10, 'µg/m³'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Status: $category',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWeatherSection(BuildContext context, Map<String, dynamic> weather) {
    final temp = weather['temperature']?.toString() ?? 'No data';
    final humidity = weather['humidity']?.toString() ?? 'No data';
    final uvIndex = weather['uvIndex']?.toString() ?? 'No data';
    final uvRisk = weather['uvRisk'] ?? 'No data';
    final windSpeed = weather['windSpeed']?.toString() ?? 'No data';
    final visibility = weather['visibility']?.toString() ?? 'No data';
    final pressure = weather['pressure']?.toString() ?? 'No data';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Weather Conditions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataPoint(context, 'Temp', temp, '°C'),
            _buildDataPoint(context, 'Humidity', humidity, '%'),
            _buildDataPoint(context, 'UV Index', uvIndex, null),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataPoint(context, 'Wind', windSpeed, 'm/s'),
            _buildDataPoint(context, 'Visibility', _formatVisibility(visibility), null),
            _buildDataPoint(context, 'Pressure', pressure, 'hPa'),
          ],
        ),
        if (uvRisk != 'No data' && uvRisk != 'No data available')
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'UV Risk: $uvRisk',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        // Stagnation Event
        if (weather['stagnationEvent'] != null && weather['stagnationEvent']['active'] == true)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atmospheric Stagnation: ${weather['stagnationEvent']['description']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPollenSection(BuildContext context, Map<String, dynamic> pollen) {
    final treePollen = pollen['treePollen']?.toString() ?? 'No data';
    final grassPollen = pollen['grassPollen']?.toString() ?? 'No data';
    final weedPollen = pollen['weedPollen']?.toString() ?? 'No data';
    final overallRisk = pollen['overallRisk'] ?? 'No data';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.eco, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Pollen Levels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataPoint(context, 'Tree', treePollen, 'index'),
            _buildDataPoint(context, 'Grass', grassPollen, 'index'),
            _buildDataPoint(context, 'Weed', weedPollen, 'index'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Overall Risk: $overallRisk',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWildfireSection(BuildContext context, Map<String, dynamic> wildfire) {
    final riskLevel = wildfire['riskLevel'] ?? 'No data';
    final nearbyFires = wildfire['nearbyFires']?.toString() ?? '0';
    final closestDistance = wildfire['closestFireDistance']?.toString();
    final smokeImpact = wildfire['smokeImpact'] ?? 'No data';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Wildfire Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDataPoint(context, 'Risk Level', riskLevel, null),
            _buildDataPoint(context, 'Nearby Fires', nearbyFires, 'active'),
            _buildDataPoint(
              context,
              'Closest Fire',
              closestDistance ?? 'None detected',
              closestDistance != null ? 'km' : null
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Smoke Impact: $smokeImpact',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),

        // High risk warning
        if (riskLevel == 'High' || riskLevel == 'Critical')
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wildfire Alert: ${wildfire['airQualityImpact'] ?? 'Monitor conditions closely'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWeatherAlerts(BuildContext context, List<dynamic> alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Weather Alerts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...alerts.map((alert) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: alert['severity'] == 'High'
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert['title'] ?? 'Alert',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: alert['severity'] == 'High'
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              if (alert['description'] != null)
                Text(
                  alert['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: alert['severity'] == 'High'
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDataPoint(BuildContext context, String label, String value, String? unit) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value == 'No data' ? 'N/A' : value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: value == 'No data'
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
          if (unit != null && value != 'No data')
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatVisibility(String visibility) {
    if (visibility == 'No data' || visibility.isEmpty) return 'No data';

    try {
      final visibilityMeters = double.parse(visibility);
      if (visibilityMeters >= 1000) {
        return '${(visibilityMeters / 1000).toStringAsFixed(1)} km';
      } else {
        return '${visibilityMeters.toInt()} m';
      }
    } catch (e) {
      return visibility;
    }
  }
}