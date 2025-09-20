import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/air_quality.dart';

class AirQualityDetailsScreen extends StatelessWidget {
  final AirQualityData airQuality;
  final String locationName;

  const AirQualityDetailsScreen({
    Key? key,
    required this.airQuality,
    required this.locationName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCategory(
              context,
              'Core Pollutants',
              [
                _MetricDetail(
                  name: 'PM2.5',
                  value: airQuality.metrics.pm25,
                  unit: 'μg/m³',
                  normalRange: '0-12',
                  description: 'Fine particles smaller than 2.5 micrometers',
                  learnMoreUrl: 'https://www.epa.gov/pm-pollution/particulate-matter-pm-basics',
                ),
                _MetricDetail(
                  name: 'PM10',
                  value: airQuality.metrics.pm10,
                  unit: 'μg/m³',
                  normalRange: '0-54',
                  description: 'Particles smaller than 10 micrometers',
                  learnMoreUrl: 'https://www.epa.gov/pm-pollution/particulate-matter-pm-basics',
                ),
                _MetricDetail(
                  name: 'O₃',
                  value: airQuality.metrics.o3,
                  unit: 'ppb',
                  normalRange: '0-54',
                  description: 'Ground-level ozone',
                  learnMoreUrl: 'https://www.epa.gov/ground-level-ozone-pollution/ground-level-ozone-basics',
                ),
                _MetricDetail(
                  name: 'NO₂',
                  value: airQuality.metrics.no2,
                  unit: 'ppb',
                  normalRange: '0-53',
                  description: 'Nitrogen dioxide gas',
                  learnMoreUrl: 'https://www.epa.gov/no2-pollution/basic-information-about-no2',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricCategory(
              context,
              'Additional Pollutants',
              [
                _MetricDetail(
                  name: 'CO',
                  value: airQuality.metrics.co,
                  unit: 'ppb',
                  normalRange: '0-4400',
                  description: 'Carbon monoxide',
                  learnMoreUrl: 'https://www.epa.gov/co-pollution/basic-information-about-carbon-monoxide-co-outdoor-air-pollution',
                ),
                _MetricDetail(
                  name: 'SO₂',
                  value: airQuality.metrics.so2,
                  unit: 'ppb',
                  normalRange: '0-35',
                  description: 'Sulfur dioxide',
                  learnMoreUrl: 'https://www.epa.gov/so2-pollution/sulfur-dioxide-basics',
                ),
                _MetricDetail(
                  name: 'NOx',
                  value: airQuality.metrics.nox,
                  unit: 'ppb',
                  normalRange: '0-100',
                  description: 'Nitrogen oxides',
                  learnMoreUrl: 'https://www.epa.gov/nox',
                ),
                _MetricDetail(
                  name: 'NO',
                  value: airQuality.metrics.no,
                  unit: 'ppb',
                  normalRange: '0-50',
                  description: 'Nitric oxide',
                  learnMoreUrl: 'https://www.epa.gov/nox',
                ),
                _MetricDetail(
                  name: 'NH₃',
                  value: airQuality.metrics.nh3,
                  unit: 'ppb',
                  normalRange: '0-200',
                  description: 'Ammonia',
                  learnMoreUrl: 'https://www.epa.gov/ammonia',
                ),
                _MetricDetail(
                  name: 'C₆H₆',
                  value: airQuality.metrics.c6h6,
                  unit: 'μg/m³',
                  normalRange: '0-5',
                  description: 'Benzene',
                  learnMoreUrl: 'https://www.epa.gov/sites/default/files/2016-09/documents/benzene.pdf',
                ),
                _MetricDetail(
                  name: 'Ox',
                  value: airQuality.metrics.ox,
                  unit: 'ppb',
                  normalRange: '0-100',
                  description: 'Photochemical oxidants',
                  learnMoreUrl: 'https://www.epa.gov/ground-level-ozone-pollution',
                ),
                _MetricDetail(
                  name: 'NMHC',
                  value: airQuality.metrics.nmhc,
                  unit: 'ppb',
                  normalRange: '0-100',
                  description: 'Non-methane hydrocarbons',
                  learnMoreUrl: 'https://www.epa.gov/air-emissions-inventories/what-are-volatile-organic-compounds-vocs',
                ),
                _MetricDetail(
                  name: 'TRS',
                  value: airQuality.metrics.trs,
                  unit: 'μg/m³',
                  normalRange: '0-10',
                  description: 'Total reduced sulfur',
                  learnMoreUrl: 'https://www.epa.gov/air-emissions-monitoring-knowledge-base/sulfur-compounds',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricCategory(
              context,
              'Indices & Special Metrics',
              [
                _MetricDetail(
                  name: 'Universal AQI',
                  value: airQuality.metrics.universalAqi?.toDouble(),
                  unit: '',
                  normalRange: '0-50',
                  description: 'Universal air quality index',
                  learnMoreUrl: 'https://www.airnow.gov/aqi/aqi-basics/',
                ),
                _MetricDetail(
                  name: 'Wildfire Index',
                  value: airQuality.metrics.wildfireIndex,
                  unit: '',
                  normalRange: '0',
                  description: 'Fire impact on air quality',
                  learnMoreUrl: 'https://www.airnow.gov/fires/',
                ),
                _MetricDetail(
                  name: 'Radon',
                  value: airQuality.metrics.radon,
                  unit: 'pCi/L',
                  normalRange: '<2.0',
                  description: 'Radioactive gas from soil',
                  learnMoreUrl: 'https://www.epa.gov/radon/what-radon',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricCategory(
              context,
              'Radon Details',
              [
                _MetricDetail(
                  name: 'EPA Zone',
                  value: airQuality.metrics.radonEpaZone?.toDouble(),
                  unit: '',
                  normalRange: '3',
                  description: 'EPA radon zone classification',
                  learnMoreUrl: 'https://www.epa.gov/radon/epa-map-radon-zones',
                ),
                _MetricDetail(
                  name: 'Radon Risk',
                  textValue: airQuality.metrics.radonRiskLevel ?? 'N/A',
                  unit: '',
                  normalRange: 'Low',
                  description: 'Overall radon risk level',
                  learnMoreUrl: 'https://www.epa.gov/radon/health-risk-radon',
                ),
                _MetricDetail(
                  name: 'Zone Desc',
                  textValue: airQuality.metrics.radonZoneDescription ?? 'N/A',
                  unit: '',
                  normalRange: '-',
                  description: 'Zone description',
                  learnMoreUrl: 'https://www.epa.gov/radon',
                ),
                _MetricDetail(
                  name: 'Radon Recommendation',
                  textValue: airQuality.metrics.radonRecommendation ?? 'N/A',
                  unit: '',
                  normalRange: '-',
                  description: 'Recommended actions',
                  learnMoreUrl: 'https://www.epa.gov/radon/radon-action-levels',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricCategory(
              context,
              'Wildfire Details',
              [
                _MetricDetail(
                  name: 'Nearby Fires',
                  value: airQuality.metrics.wildfireNearbyFires?.toDouble(),
                  unit: 'fires',
                  normalRange: '0',
                  description: 'Number of active fires in the area',
                  learnMoreUrl: 'https://inciweb.wildfire.gov/',
                ),
                _MetricDetail(
                  name: 'Closest Fire',
                  value: airQuality.metrics.wildfireClosestDistance,
                  unit: 'km',
                  normalRange: '>100',
                  description: 'Distance to nearest fire',
                  learnMoreUrl: 'https://www.fire.ca.gov/incidents/',
                ),
                _MetricDetail(
                  name: 'Fire Risk',
                  textValue: airQuality.metrics.wildfireRiskLevel ?? 'N/A',
                  unit: '',
                  normalRange: 'Low',
                  description: 'Current fire risk level',
                  learnMoreUrl: 'https://www.nifc.gov/fire-information',
                ),
                _MetricDetail(
                  name: 'Smoke Impact',
                  textValue: airQuality.metrics.wildfireSmokeImpact ?? 'N/A',
                  unit: '',
                  normalRange: 'None',
                  description: 'Smoke effect on air quality',
                  learnMoreUrl: 'https://www.airnow.gov/wildfires-and-indoor-air-quality/',
                ),
                _MetricDetail(
                  name: 'Fire AQ Impact',
                  textValue: airQuality.metrics.wildfireAirQualityImpact ?? 'N/A',
                  unit: '',
                  normalRange: 'None',
                  description: 'Fire impact on air quality',
                  learnMoreUrl: 'https://www.airnow.gov/fires/',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMetricCategory(
    BuildContext context,
    String title,
    List<_MetricDetail> metrics,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            ...metrics.map((metric) => _buildMetricRow(context, metric)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, _MetricDetail metric) {
    final String displayValue;
    if (metric.textValue != null) {
      displayValue = metric.textValue!;
    } else if (metric.value != null) {
      displayValue = '${metric.value!.toStringAsFixed(1)} ${metric.unit}'.trim();
    } else {
      displayValue = 'N/A';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayValue,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getValueColor(context, metric),
                          ),
                    ),
                    Text(
                      'Normal: ${metric.normalRange}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                onPressed: () => _launchUrl(metric.learnMoreUrl),
                tooltip: 'Learn more',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  Color _getValueColor(BuildContext context, _MetricDetail metric) {
    if (metric.value == null && metric.textValue == null) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    }

    // Simple color coding based on whether value is available
    // In a real app, you'd compare against thresholds
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _getStatusColor(AirQualityStatus status) {
    switch (status) {
      case AirQualityStatus.good:
        return Colors.green;
      case AirQualityStatus.caution:
        return Colors.orange;
      case AirQualityStatus.avoid:
        return Colors.red;
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}

class _MetricDetail {
  final String name;
  final double? value;
  final String? textValue;
  final String unit;
  final String normalRange;
  final String description;
  final String learnMoreUrl;

  _MetricDetail({
    required this.name,
    this.value,
    this.textValue,
    required this.unit,
    required this.normalRange,
    required this.description,
    required this.learnMoreUrl,
  });
}