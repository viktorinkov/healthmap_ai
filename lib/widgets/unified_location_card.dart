import 'package:flutter/material.dart';
import '../models/pinned_location.dart';
import '../models/air_quality.dart';
import '../models/weather_data.dart';
import '../screens/charts/location_charts_screen.dart';
import '../screens/charts/location_forecast_screen.dart';
import '../screens/main/air_quality_details_screen.dart';

class UnifiedLocationCard extends StatefulWidget {
  final PinnedLocation? location;
  final AirQualityData? airQuality;
  final WeatherData? weatherData;
  final bool isCurrentLocation;
  final bool showFullDetails;
  final VoidCallback? onRefresh;
  final String? geminiAssessment;
  final String? customTitle;
  final bool hideDetailsButton;

  const UnifiedLocationCard({
    Key? key,
    this.location,
    this.airQuality,
    this.weatherData,
    this.isCurrentLocation = false,
    this.showFullDetails = false,
    this.onRefresh,
    this.geminiAssessment,
    this.customTitle,
    this.hideDetailsButton = false,
  }) : super(key: key);

  @override
  State<UnifiedLocationCard> createState() => _UnifiedLocationCardState();
}

class _UnifiedLocationCardState extends State<UnifiedLocationCard> {

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: widget.isCurrentLocation
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.location != null && !widget.hideDetailsButton ? () => _navigateToDetails() : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (widget.airQuality != null) ...[
                const SizedBox(height: 16),
                if (widget.geminiAssessment != null && widget.geminiAssessment!.isNotEmpty) ...[
                  _buildGeminiAssessment(),
                  const SizedBox(height: 12),
                ],
                _buildHighlights(),
                const SizedBox(height: 12),
                _buildHealthRecommendationTags(),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ] else ...[
                const SizedBox(height: 12),
                _buildNoDataMessage(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final locationName = widget.customTitle ??
      (widget.isCurrentLocation
        ? 'Current Location'
        : widget.location?.name ?? 'Unknown Location');

    final locationSubtitle = widget.isCurrentLocation
      ? 'Real-time air quality data'
      : widget.location?.address ?? widget.location?.type.displayName ?? '';

    return Row(
      children: [
        if (widget.isCurrentLocation)
          Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.secondary,
            size: 24,
          )
        else if (widget.location != null)
          Text(
            widget.location!.type.icon,
            style: const TextStyle(fontSize: 20),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locationName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isCurrentLocation
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (locationSubtitle.isNotEmpty)
                Text(
                  locationSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.isCurrentLocation
                      ? Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              if (widget.location != null && !widget.isCurrentLocation)
                Text(
                  '${widget.location!.latitude.toStringAsFixed(4)}, ${widget.location!.longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
        if (widget.airQuality != null) _buildStatusBadge(widget.airQuality!.status),
      ],
    );
  }

  Widget _buildStatusBadge(AirQualityStatus status) {
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildGeminiAssessment() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isCurrentLocation
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.7)
          : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.geminiAssessment!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.isCurrentLocation
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    final metrics = widget.airQuality!.metrics;
    final highlights = <_HighlightInfo>[];

    // Collect metrics with their deviation from normal (higher score = worse)
    final deviations = <_MetricDeviation>[];

    // PM2.5 (normal: 0-12)
    if (metrics.pm25 > 12) {
      deviations.add(_MetricDeviation(
        label: 'PM2.5: ${metrics.pm25.toStringAsFixed(1)} μg/m³',
        score: metrics.pm25 / 12, // Higher score = worse
        severity: metrics.pm25 > 55 ? HighlightSeverity.high
                : metrics.pm25 > 35 ? HighlightSeverity.medium
                : HighlightSeverity.low,
      ));
    }

    // PM10 (normal: 0-54)
    if (metrics.pm10 > 54) {
      deviations.add(_MetricDeviation(
        label: 'PM10: ${metrics.pm10.toStringAsFixed(1)} μg/m³',
        score: metrics.pm10 / 54,
        severity: metrics.pm10 > 154 ? HighlightSeverity.high
                : metrics.pm10 > 100 ? HighlightSeverity.medium
                : HighlightSeverity.low,
      ));
    }

    // Ozone (normal: 0-54)
    if (metrics.o3 > 54) {
      deviations.add(_MetricDeviation(
        label: 'O₃: ${metrics.o3.toStringAsFixed(0)} ppb',
        score: metrics.o3 / 54,
        severity: metrics.o3 > 85 ? HighlightSeverity.high
                : metrics.o3 > 70 ? HighlightSeverity.medium
                : HighlightSeverity.low,
      ));
    }

    // NO2 (normal: 0-53)
    if (metrics.no2 > 53) {
      deviations.add(_MetricDeviation(
        label: 'NO₂: ${metrics.no2.toStringAsFixed(0)} ppb',
        score: metrics.no2 / 53,
        severity: metrics.no2 > 150 ? HighlightSeverity.high
                : metrics.no2 > 100 ? HighlightSeverity.medium
                : HighlightSeverity.low,
      ));
    }

    // CO (normal: 0-4400)
    if (metrics.co != null && metrics.co! > 4400) {
      deviations.add(_MetricDeviation(
        label: 'CO: ${metrics.co!.toStringAsFixed(0)} ppb',
        score: metrics.co! / 4400,
        severity: metrics.co! > 9400 ? HighlightSeverity.high
                : HighlightSeverity.medium,
      ));
    }

    // SO2 (normal: 0-35)
    if (metrics.so2 != null && metrics.so2! > 35) {
      deviations.add(_MetricDeviation(
        label: 'SO₂: ${metrics.so2!.toStringAsFixed(0)} ppb',
        score: metrics.so2! / 35,
        severity: metrics.so2! > 75 ? HighlightSeverity.high
                : HighlightSeverity.medium,
      ));
    }

    // Wildfire Index (normal: 0)
    if (metrics.wildfireIndex != null && metrics.wildfireIndex! > 0) {
      deviations.add(_MetricDeviation(
        label: 'Wildfire Index: ${metrics.wildfireIndex!.toStringAsFixed(0)}',
        score: metrics.wildfireIndex! * 2, // Give wildfire high weight
        severity: metrics.wildfireIndex! > 50 ? HighlightSeverity.high
                : metrics.wildfireIndex! > 10 ? HighlightSeverity.medium
                : HighlightSeverity.low,
      ));
    }


    // Universal AQI (normal: 0-50)
    if (metrics.universalAqi != null && metrics.universalAqi! > 50) {
      deviations.add(_MetricDeviation(
        label: 'Universal AQI: ${metrics.universalAqi}',
        score: metrics.universalAqi! / 50,
        severity: metrics.universalAqi! > 150 ? HighlightSeverity.high
                : metrics.universalAqi! > 100 ? HighlightSeverity.medium
                : HighlightSeverity.low,
      ));
    }

    // If we have deviations, show them
    if (deviations.isNotEmpty) {
      // Sort by score (highest deviation first)
      deviations.sort((a, b) => b.score.compareTo(a.score));

      // Take all significant deviations
      for (final dev in deviations) {
        highlights.add(_HighlightInfo(
          icon: dev.severity == HighlightSeverity.high ? Icons.warning
              : dev.severity == HighlightSeverity.medium ? Icons.priority_high
              : Icons.info,
          label: dev.label,
          severity: dev.severity,
        ));
      }
    }

    // If we have fewer than 3 highlights, add the highest current values even if normal
    if (highlights.length < 3) {
      final additionalMetrics = <_MetricDeviation>[];

      // Add current values with their relative scores
      additionalMetrics.add(_MetricDeviation(
        label: 'PM2.5: ${metrics.pm25.toStringAsFixed(1)} μg/m³',
        score: metrics.pm25,
        severity: HighlightSeverity.good,
      ));

      additionalMetrics.add(_MetricDeviation(
        label: 'PM10: ${metrics.pm10.toStringAsFixed(1)} μg/m³',
        score: metrics.pm10,
        severity: HighlightSeverity.good,
      ));

      additionalMetrics.add(_MetricDeviation(
        label: 'O₃: ${metrics.o3.toStringAsFixed(0)} ppb',
        score: metrics.o3,
        severity: HighlightSeverity.good,
      ));

      additionalMetrics.add(_MetricDeviation(
        label: 'NO₂: ${metrics.no2.toStringAsFixed(0)} ppb',
        score: metrics.no2,
        severity: HighlightSeverity.good,
      ));

      if (metrics.universalAqi != null) {
        additionalMetrics.add(_MetricDeviation(
          label: 'AQI: ${metrics.universalAqi}',
          score: metrics.universalAqi!.toDouble(),
          severity: HighlightSeverity.good,
        ));
      }

      if (metrics.wildfireIndex != null) {
        additionalMetrics.add(_MetricDeviation(
          label: 'Wildfire Index: ${metrics.wildfireIndex!.toStringAsFixed(0)}',
          score: metrics.wildfireIndex!,
          severity: HighlightSeverity.good,
        ));
      }


      // Sort by value and add until we have at least 3
      additionalMetrics.sort((a, b) => b.score.compareTo(a.score));

      for (final metric in additionalMetrics) {
        // Don't duplicate if already in highlights
        if (!highlights.any((h) => h.label == metric.label)) {
          highlights.add(_HighlightInfo(
            icon: Icons.check_circle,
            label: metric.label,
            severity: metric.severity,
          ));
          if (highlights.length >= 3) break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Highlights',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.isCurrentLocation
              ? Theme.of(context).colorScheme.onSecondaryContainer
              : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: highlights.map((highlight) => _buildHighlightChip(highlight)).toList(),
        ),
      ],
    );
  }

  Widget _buildHighlightChip(_HighlightInfo highlight) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    switch (highlight.severity) {
      case HighlightSeverity.good:
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green.shade800;
        iconColor = Colors.green.shade600;
        break;
      case HighlightSeverity.low:
        backgroundColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue.shade800;
        iconColor = Colors.blue.shade600;
        break;
      case HighlightSeverity.medium:
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange.shade800;
        iconColor = Colors.orange.shade600;
        break;
      case HighlightSeverity.high:
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red.shade800;
        iconColor = Colors.red.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            highlight.icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            highlight.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHealthRecommendationTags() {
    final tags = widget.airQuality?.healthRecommendations ?? [];

    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Recommendations',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.isCurrentLocation
              ? Theme.of(context).colorScheme.onSecondaryContainer
              : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => _buildHealthTag(tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildHealthTag(HealthRecommendationTag tag) {
    Color color;
    switch (tag.level) {
      case HealthAdviceLevel.safe:
        color = Colors.green;
        break;
      case HealthAdviceLevel.caution:
        color = Colors.orange;
        break;
      case HealthAdviceLevel.avoid:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.population.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tag.recommendation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: widget.isCurrentLocation
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToCharts,
                icon: const Icon(Icons.analytics),
                label: const Text('History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToForecast,
                icon: const Icon(Icons.schedule),
                label: const Text('Forecast'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _navigateToDetails,
                icon: const Icon(Icons.info_outline),
                label: const Text('Details'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoDataMessage() {
    return Text(
      'Air quality data not available',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: widget.isCurrentLocation
          ? Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.6)
          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  void _navigateToCharts() {
    if (widget.location != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationChartsScreen(location: widget.location!),
        ),
      );
    } else if (widget.isCurrentLocation) {
      // Create a temporary location for current location charts
      final currentLocation = PinnedLocation(
        id: 'current_location',
        name: 'Current Location',
        latitude: 29.7604, // Default Houston coordinates
        longitude: -95.3698,
        type: LocationType.other,
        address: '',
        createdAt: DateTime.now(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationChartsScreen(location: currentLocation),
        ),
      );
    }
  }

  void _navigateToDetails() {
    if (widget.airQuality != null) {
      final locationName = widget.customTitle ??
        (widget.isCurrentLocation
          ? 'Current Location'
          : widget.location?.name ?? 'Unknown Location');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AirQualityDetailsScreen(
            airQuality: widget.airQuality!,
            locationName: locationName,
            weatherData: widget.weatherData,
          ),
        ),
      );
    }
  }

  void _navigateToForecast() {
    if (widget.location != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationForecastScreen(location: widget.location!),
        ),
      );
    } else if (widget.isCurrentLocation) {
      // Create a temporary location for current location forecast
      final currentLocation = PinnedLocation(
        id: 'current_location',
        name: 'Current Location',
        latitude: 29.7604, // Default Houston coordinates
        longitude: -95.3698,
        type: LocationType.other,
        address: '',
        createdAt: DateTime.now(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationForecastScreen(location: currentLocation),
        ),
      );
    }
  }




}

class _PollutantInfo {
  final String name;
  final double? value;
  final String unit;
  final bool isAvailable;

  _PollutantInfo(this.name, this.value, this.unit, this.isAvailable);
}

enum HighlightSeverity {
  good,
  low,
  medium,
  high,
}

class _HighlightInfo {
  final IconData icon;
  final String label;
  final HighlightSeverity severity;

  _HighlightInfo({
    required this.icon,
    required this.label,
    required this.severity,
  });
}

class _MetricDeviation {
  final String label;
  final double score;
  final HighlightSeverity severity;

  _MetricDeviation({
    required this.label,
    required this.score,
    required this.severity,
  });
}