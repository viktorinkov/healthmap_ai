import 'package:flutter/material.dart';
import '../models/pinned_location.dart';
import '../models/air_quality.dart';
import '../models/environmental_measurements.dart';
import '../services/environmental_measurements_service.dart';
import '../screens/charts/location_charts_screen.dart';
import '../screens/charts/location_forecast_screen.dart';
import 'environmental_measurements_card.dart';
import 'pin_info_dialog.dart';

class UnifiedLocationCard extends StatefulWidget {
  final PinnedLocation? location;
  final AirQualityData? airQuality;
  final bool isCurrentLocation;
  final bool showFullDetails;
  final VoidCallback? onRefresh;
  final String? geminiAssessment;
  final String? customTitle;

  const UnifiedLocationCard({
    Key? key,
    this.location,
    this.airQuality,
    this.isCurrentLocation = false,
    this.showFullDetails = false,
    this.onRefresh,
    this.geminiAssessment,
    this.customTitle,
  }) : super(key: key);

  @override
  State<UnifiedLocationCard> createState() => _UnifiedLocationCardState();
}

class _UnifiedLocationCardState extends State<UnifiedLocationCard> {
  EnvironmentalMeasurements? _environmentalMeasurements;
  bool _loadingEnvironmental = false;

  @override
  void initState() {
    super.initState();
    if (widget.showFullDetails && widget.location != null) {
      _loadEnvironmentalHealth();
    }
  }

  Future<void> _loadEnvironmentalHealth() async {
    setState(() {
      _loadingEnvironmental = true;
    });

    try {
      final measurements = await EnvironmentalMeasurementsService.getEnvironmentalMeasurements(
        locationId: widget.location!.id,
        latitude: widget.location!.latitude,
        longitude: widget.location!.longitude,
        locationName: widget.location!.name,
      );

      if (mounted) {
        setState(() {
          _environmentalMeasurements = measurements;
          _loadingEnvironmental = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingEnvironmental = false;
        });
      }
    }
  }

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
        onTap: widget.location != null ? () => _showDetailedInfo() : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (widget.airQuality != null) ...[
                const SizedBox(height: 16),
                _buildUniversalAqi(),
                const SizedBox(height: 12),
                _buildPollutantGrid(),
                const SizedBox(height: 12),
                _buildHealthRecommendationTags(),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ] else ...[
                const SizedBox(height: 12),
                _buildNoDataMessage(),
              ],
              if (widget.showFullDetails && _loadingEnvironmental)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (widget.showFullDetails && _environmentalMeasurements != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: EnvironmentalMeasurementsCard(measurements: _environmentalMeasurements),
                ),
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

  Widget _buildUniversalAqi() {
    // If Gemini assessment is provided, show that instead
    if (widget.geminiAssessment != null && widget.geminiAssessment!.isNotEmpty) {
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

    // Only show Universal AQI if available from API
    final aqi = widget.airQuality!.metrics.universalAqi;
    if (aqi == null) {
      return const SizedBox.shrink(); // Don't show anything if no real AQI data
    }

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
            Icons.air,
            size: 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Universal AQI: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.isCurrentLocation
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            aqi.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantGrid() {
    final metrics = widget.airQuality!.metrics;
    final pollutants = [
      // Core pollutants (always present)
      _PollutantInfo('PM2.5', metrics.pm25, 'μg/m³', true),
      _PollutantInfo('PM10', metrics.pm10, 'μg/m³', true),
      _PollutantInfo('O₃', metrics.o3, 'ppb', true),
      _PollutantInfo('NO₂', metrics.no2, 'ppb', true),
      // Optional pollutants
      _PollutantInfo('CO', metrics.co, 'ppb', metrics.co != null),
      _PollutantInfo('SO₂', metrics.so2, 'ppb', metrics.so2 != null),
      _PollutantInfo('NOx', metrics.nox, 'ppb', metrics.nox != null),
      _PollutantInfo('NO', metrics.no, 'ppb', metrics.no != null),
      _PollutantInfo('NH₃', metrics.nh3, 'ppb', metrics.nh3 != null),
      _PollutantInfo('C₆H₆', metrics.c6h6, 'μg/m³', metrics.c6h6 != null),
      _PollutantInfo('Ox', metrics.ox, 'ppb', metrics.ox != null),
      _PollutantInfo('NMHC', metrics.nmhc, 'ppb', metrics.nmhc != null),
      _PollutantInfo('TRS', metrics.trs, 'μg/m³', metrics.trs != null),
      // Additional metrics - only show if available
      if (metrics.universalAqi != null) _PollutantInfo('Universal AQI', metrics.universalAqi!.toDouble(), '', true),
      _PollutantInfo('Wildfire Index', metrics.wildfireIndex, '', true),
      _PollutantInfo('Radon', metrics.radon, 'pCi/L', true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Air Quality Metrics',
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
          children: pollutants.map((pollutant) => _buildPollutantChip(pollutant)).toList(),
        ),
      ],
    );
  }

  Widget _buildPollutantChip(_PollutantInfo pollutant) {
    final isAvailable = pollutant.isAvailable;
    final displayValue = isAvailable
        ? '${pollutant.value?.toStringAsFixed(1) ?? '0.0'} ${pollutant.unit}'
        : 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? (widget.isCurrentLocation
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.7)
                : Theme.of(context).colorScheme.surfaceContainer)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '${pollutant.name}: $displayValue',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isAvailable
              ? (widget.isCurrentLocation
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurface)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: isAvailable ? FontStyle.normal : FontStyle.italic,
        ),
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
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showDetailedInfo,
            icon: const Icon(Icons.info_outline),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
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



  void _showDetailedInfo() {
    if (widget.location != null && widget.airQuality != null) {
      showDialog(
        context: context,
        builder: (context) => PinInfoDialog(
          location: widget.location!,
          airQuality: widget.airQuality,
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