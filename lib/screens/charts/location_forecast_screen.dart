import 'package:flutter/material.dart';
import '../../models/pinned_location.dart';
import '../../widgets/air_quality_forecast_section.dart';

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
            ],
          ),
        ),
      ),
    );
  }
}