import 'package:flutter/material.dart';
import '../models/pinned_location.dart';
import '../models/air_quality.dart';

class PinInfoDialog extends StatelessWidget {
  final PinnedLocation location;
  final AirQualityData? airQuality;

  const PinInfoDialog({
    Key? key,
    required this.location,
    this.airQuality,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            if (airQuality != null)
              Expanded(child: _buildContent(context))
            else
              _buildNoDataContent(context),
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
            location.type.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  location.address ?? location.type.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (airQuality != null) _buildStatusBadge(context, airQuality!.status),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = airQuality!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAirScoreSection(context, data),
          const SizedBox(height: 20),
          _buildJustificationSection(context, data),
          const SizedBox(height: 20),
          _buildPollutantSummary(context, data.metrics),
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