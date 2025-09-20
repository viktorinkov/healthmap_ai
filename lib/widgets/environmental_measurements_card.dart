import 'package:flutter/material.dart';
import '../models/environmental_measurements.dart';

class EnvironmentalMeasurementsCard extends StatelessWidget {
  final EnvironmentalMeasurements? measurements;

  const EnvironmentalMeasurementsCard({
    Key? key,
    required this.measurements,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (measurements == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.sensors_off, size: 48),
              const SizedBox(height: 16),
              Text(
                'No Environmental Measurements Available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Real-time environmental data is not available for this location.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildMeasurements(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sensors, size: 24),
        const SizedBox(width: 8),
        Text(
          'Environmental Measurements',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (measurements!.airQuality != null) ...[
          _buildSectionHeader(context, 'Air Quality', Icons.air),
          _buildAirQualityMeasurements(context, measurements!.airQuality!),
          const SizedBox(height: 16),
        ],
        if (measurements!.meteorology != null) ...[
          _buildSectionHeader(context, 'Weather Conditions', Icons.wb_sunny),
          _buildWeatherMeasurements(context, measurements!.meteorology!),
          const SizedBox(height: 16),
        ],
        if (measurements!.aeroallergens != null) ...[
          _buildSectionHeader(context, 'Pollen Levels', Icons.grass),
          _buildPollenMeasurements(context, measurements!.aeroallergens!),
          const SizedBox(height: 16),
        ],
        if (measurements!.wildfire != null) ...[
          _buildSectionHeader(context, 'Wildfire Activity', Icons.local_fire_department),
          _buildWildfireMeasurements(context, measurements!.wildfire!),
          const SizedBox(height: 16),
        ],
        if (measurements!.indoorEnvironment != null) ...[
          _buildSectionHeader(context, 'Indoor Environment', Icons.home),
          _buildIndoorMeasurements(context, measurements!.indoorEnvironment!),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAirQualityMeasurements(BuildContext context, AirQualityMeasurements aq) {
    return Column(
      children: [
        if (aq.pm25 != null) _buildMeasurementRow(context, 'PM2.5', '${aq.pm25!.toStringAsFixed(1)} μg/m³', _getAirQualityStatus(aq.pm25!, 35.0)),
        if (aq.pm10 != null) _buildMeasurementRow(context, 'PM10', '${aq.pm10!.toStringAsFixed(1)} μg/m³', _getAirQualityStatus(aq.pm10!, 150.0)),
        if (aq.ozone != null) _buildMeasurementRow(context, 'Ozone', '${aq.ozone!.toStringAsFixed(1)} ppb', _getAirQualityStatus(aq.ozone!, 70.0)),
        if (aq.nitrogenDioxide != null) _buildMeasurementRow(context, 'NO₂', '${aq.nitrogenDioxide!.toStringAsFixed(1)} ppb', _getAirQualityStatus(aq.nitrogenDioxide!, 100.0)),
        if (aq.carbonMonoxide != null) _buildMeasurementRow(context, 'CO', '${aq.carbonMonoxide!.toStringAsFixed(1)} ppb', null),
        if (aq.sulfurDioxide != null) _buildMeasurementRow(context, 'SO₂', '${aq.sulfurDioxide!.toStringAsFixed(1)} ppb', null),
        _buildSourceRow(context, aq.measurementSource),
      ],
    );
  }

  Widget _buildWeatherMeasurements(BuildContext context, MeteorologicalMeasurements weather) {
    return Column(
      children: [
        if (weather.temperatureCelsius != null) _buildMeasurementRow(context, 'Temperature', '${weather.temperatureCelsius!.toStringAsFixed(1)}°C (${weather.temperatureFahrenheit!.toStringAsFixed(1)}°F)', null),
        if (weather.relativeHumidityPercent != null) _buildMeasurementRow(context, 'Humidity', '${weather.relativeHumidityPercent!.toStringAsFixed(0)}%', null),
        if (weather.windSpeedMs != null) _buildMeasurementRow(context, 'Wind Speed', '${weather.windSpeedMs!.toStringAsFixed(1)} m/s (${weather.windSpeedMph!.toStringAsFixed(1)} mph)', null),
        if (weather.uvIndex != null) _buildMeasurementRow(context, 'UV Index', '${weather.uvIndex}', _getUVStatus(weather.uvIndex!)),
        if (weather.atmosphericPressureHpa != null) _buildMeasurementRow(context, 'Pressure', '${weather.atmosphericPressureHpa!.toStringAsFixed(1)} hPa', null),
        _buildMeasurementRow(context, 'Air Stagnation', weather.stagnationEvent ? 'Yes' : 'No', weather.stagnationEvent ? 'Poor air circulation' : null),
        _buildSourceRow(context, weather.measurementSource),
      ],
    );
  }

  Widget _buildPollenMeasurements(BuildContext context, AeroallergenMeasurements pollen) {
    return Column(
      children: [
        if (pollen.treePollenGrainsPerM3 != null) _buildMeasurementRow(context, 'Tree Pollen', '${pollen.treePollenGrainsPerM3} grains/m³', null),
        if (pollen.grassPollenGrainsPerM3 != null) _buildMeasurementRow(context, 'Grass Pollen', '${pollen.grassPollenGrainsPerM3} grains/m³', null),
        if (pollen.weedPollenGrainsPerM3 != null) _buildMeasurementRow(context, 'Weed Pollen', '${pollen.weedPollenGrainsPerM3} grains/m³', null),
        if (pollen.moldSporesPerM3 != null) _buildMeasurementRow(context, 'Mold Spores', '${pollen.moldSporesPerM3} spores/m³', null),
        if (pollen.dominantPollenTypes.isNotEmpty) _buildMeasurementRow(context, 'Dominant Types', pollen.dominantPollenTypes.join(', '), null),
        _buildSourceRow(context, pollen.measurementSource),
      ],
    );
  }

  Widget _buildWildfireMeasurements(BuildContext context, WildfireMeasurements wildfire) {
    return Column(
      children: [
        _buildMeasurementRow(context, 'Active Fires', '${wildfire.activeFireCount}', null),
        if (wildfire.nearestFireDistanceKm != null) _buildMeasurementRow(context, 'Nearest Fire', '${wildfire.nearestFireDistanceKm!.toStringAsFixed(1)} km', null),
        if (wildfire.smokeParticulates != null) _buildMeasurementRow(context, 'Smoke PM2.5', '${wildfire.smokeParticulates!.toStringAsFixed(1)} μg/m³', null),
        if (wildfire.visibilityKm != null) _buildMeasurementRow(context, 'Visibility', '${wildfire.visibilityKm!.toStringAsFixed(1)} km', null),
        _buildSourceRow(context, wildfire.measurementSource),
      ],
    );
  }

  Widget _buildIndoorMeasurements(BuildContext context, IndoorEnvironmentMeasurements indoor) {
    return Column(
      children: [
        if (indoor.radonLevelPciL != null) _buildMeasurementRow(context, 'Radon', '${indoor.radonLevelPciL!.toStringAsFixed(1)} pCi/L', _getRadonStatus(indoor.radonLevelPciL!)),
        if (indoor.volatileOrganicCompoundsPpb != null) _buildMeasurementRow(context, 'VOCs', '${indoor.volatileOrganicCompoundsPpb!.toStringAsFixed(1)} ppb', null),
        if (indoor.carbonMonoxidePpm != null) _buildMeasurementRow(context, 'CO (Indoor)', '${indoor.carbonMonoxidePpm!.toStringAsFixed(1)} ppm', null),
        if (indoor.moldSporesPerM3 != null) _buildMeasurementRow(context, 'Mold Spores', '${indoor.moldSporesPerM3!.toStringAsFixed(0)} spores/m³', null),
        if (indoor.formaldehydePpb != null) _buildMeasurementRow(context, 'Formaldehyde', '${indoor.formaldehydePpb!.toStringAsFixed(1)} ppb', null),
        _buildSourceRow(context, indoor.measurementSource),
      ],
    );
  }

  Widget _buildMeasurementRow(BuildContext context, String label, String value, String? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (status != null)
            Expanded(
              flex: 3,
              child: Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(status),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceRow(BuildContext context, String source) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            Icons.source,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Source: $source',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String? _getAirQualityStatus(double value, double epaStandard) {
    if (value > epaStandard) {
      return 'Exceeds EPA standard ($epaStandard)';
    } else if (value > epaStandard * 0.75) {
      return 'Near EPA standard ($epaStandard)';
    } else {
      return 'Within EPA standard ($epaStandard)';
    }
  }

  String? _getRadonStatus(double value) {
    if (value >= 4.0) {
      return 'EPA action level exceeded (4.0 pCi/L)';
    } else if (value >= 2.0) {
      return 'Consider testing/mitigation';
    } else {
      return 'Below EPA concern level';
    }
  }

  String? _getUVStatus(int uvIndex) {
    if (uvIndex >= 11) return 'Extreme - avoid sun';
    if (uvIndex >= 8) return 'Very high - protection required';
    if (uvIndex >= 6) return 'High - protection recommended';
    if (uvIndex >= 3) return 'Moderate - some protection';
    return 'Low';
  }

  Color _getStatusColor(String status) {
    if (status.contains('Exceeds') || status.contains('Extreme') || status.contains('exceeded')) {
      return Colors.red;
    } else if (status.contains('Near') || status.contains('Very high') || status.contains('Consider')) {
      return Colors.orange;
    } else if (status.contains('High') || status.contains('Moderate')) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }
}