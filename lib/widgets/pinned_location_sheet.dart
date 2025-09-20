import 'package:flutter/material.dart';
import '../models/pinned_location.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import 'environmental_alerts_card.dart';

class PinnedLocationSheet extends StatefulWidget {
  final PinnedLocation location;
  final VoidCallback? onDeleted;

  const PinnedLocationSheet({
    Key? key,
    required this.location,
    this.onDeleted,
  }) : super(key: key);

  @override
  State<PinnedLocationSheet> createState() => _PinnedLocationSheetState();
}

class _PinnedLocationSheetState extends State<PinnedLocationSheet> {
  Map<String, dynamic> _environmentalData = {};
  bool _isLoadingEnvironmentalData = true;
  bool _expandEnvironmentalData = false;

  @override
  void initState() {
    super.initState();
    _loadEnvironmentalData();
  }

  Future<void> _loadEnvironmentalData() async {
    try {
      final data = await ApiService.getAllEnvironmentalData(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
      );

      if (mounted) {
        setState(() {
          _environmentalData = data;
          _isLoadingEnvironmentalData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _environmentalData = {'error': 'Unable to fetch data'};
          _isLoadingEnvironmentalData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.location.type.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.location.name,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  Text(
                                    widget.location.type.displayName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(context),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),

                        // Environmental Data Summary
                        const SizedBox(height: 24),
                        _buildEnvironmentalSummary(context),

                        if (widget.location.address != null) ...[
                          const SizedBox(height: 24),
                          _buildInfoCard(
                            context,
                            icon: Icons.location_on_outlined,
                            title: 'Address',
                            content: widget.location.address!,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          context,
                          icon: Icons.map_outlined,
                          title: 'Coordinates',
                          content: '${widget.location.latitude.toStringAsFixed(6)}, ${widget.location.longitude.toStringAsFixed(6)}',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          context,
                          icon: Icons.calendar_today_outlined,
                          title: 'Added on',
                          content: _formatDate(widget.location.createdAt),
                        ),

                        // Expandable Detailed Environmental Data
                        if (!_isLoadingEnvironmentalData && _environmentalData.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandEnvironmentalData = !_expandEnvironmentalData;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primaryContainer,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Detailed Environmental Data',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _expandEnvironmentalData
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_expandEnvironmentalData) ...[
                            const SizedBox(height: 16),
                            EnvironmentalAlertsCard(
                              environmentalData: _environmentalData,
                              isLoading: _isLoadingEnvironmentalData,
                            ),
                          ],
                        ],

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Close'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _loadEnvironmentalData,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Refresh Data'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnvironmentalSummary(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingEnvironmentalData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_environmentalData.containsKey('error')) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unable to fetch environmental data',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    final weather = _environmentalData['weather'] as Map<String, dynamic>?;
    final airQuality = _environmentalData['airQuality'] as Map<String, dynamic>?;
    final wildfire = _environmentalData['wildfire'] as Map<String, dynamic>?;
    final pollen = _environmentalData['pollen'] as Map<String, dynamic>?;
    final radon = _environmentalData['radon'] as Map<String, dynamic>?;

    // Count active alerts
    int alertCount = 0;
    String highestRiskLevel = 'Low';

    if (weather != null && weather['alerts'] != null) {
      alertCount += (weather['alerts'] as List).length;
    }

    if (wildfire != null && wildfire['riskLevel'] != null) {
      final risk = wildfire['riskLevel'].toString();
      if (risk == 'High' || risk == 'Critical') {
        alertCount++;
        highestRiskLevel = risk;
      }
    }

    if (airQuality != null && airQuality['aqi'] != null) {
      final aqi = airQuality['aqi'];
      if (aqi > 150) {
        alertCount++;
        if (highestRiskLevel != 'Critical') highestRiskLevel = 'High';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: alertCount > 0
              ? [
                  theme.colorScheme.errorContainer.withOpacity(0.3),
                  theme.colorScheme.errorContainer.withOpacity(0.1),
                ]
              : [
                  theme.colorScheme.primaryContainer.withOpacity(0.3),
                  theme.colorScheme.primaryContainer.withOpacity(0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alertCount > 0 ? Icons.warning : Icons.check_circle,
                color: alertCount > 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                alertCount > 0
                    ? '$alertCount Environmental Alert${alertCount > 1 ? 's' : ''}'
                    : 'Good Environmental Conditions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick stats grid
          Row(
            children: [
              _buildQuickStat(
                context,
                'AQI',
                airQuality?['aqi']?.toString() ?? 'N/A',
                Icons.air,
                _getAQIColor(airQuality?['aqi']),
              ),
              const SizedBox(width: 8),
              _buildQuickStat(
                context,
                'UV',
                weather?['uvIndex']?.toString() ?? 'N/A',
                Icons.wb_sunny,
                _getUVColor(weather?['uvIndex']),
              ),
              const SizedBox(width: 8),
              _buildQuickStat(
                context,
                'Temp',
                weather?['temperature'] != null
                    ? '${weather!['temperature']}°C'
                    : 'N/A',
                Icons.thermostat,
                _getTempColor(weather?['temperature']),
              ),
              const SizedBox(width: 8),
              _buildQuickStat(
                context,
                'Radon',
                radon?['radonRisk'] ?? 'N/A',
                Icons.home_outlined,
                _getRadonColor(radon?['radonRisk']),
              ),
            ],
          ),

          if (weather?['stagnationEvent']?['active'] == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atmospheric Stagnation Detected',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAQIColor(dynamic aqi) {
    if (aqi == null) return Colors.grey;
    final value = aqi is int ? aqi : int.tryParse(aqi.toString()) ?? 0;
    if (value <= 50) return Colors.green;
    if (value <= 100) return Colors.yellow[700]!;
    if (value <= 150) return Colors.orange;
    if (value <= 200) return Colors.red;
    return Colors.purple;
  }

  Color _getUVColor(dynamic uv) {
    if (uv == null) return Colors.grey;
    final value = uv is num ? uv.toDouble() : double.tryParse(uv.toString()) ?? 0;
    if (value <= 2) return Colors.green;
    if (value <= 5) return Colors.yellow[700]!;
    if (value <= 7) return Colors.orange;
    if (value <= 10) return Colors.red;
    return Colors.purple;
  }

  Color _getTempColor(dynamic temp) {
    if (temp == null) return Colors.grey;
    final value = temp is num ? temp.toDouble() : double.tryParse(temp.toString()) ?? 0;
    if (value < 0) return Colors.blue[900]!;
    if (value < 10) return Colors.blue;
    if (value < 20) return Colors.green;
    if (value < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getFireColor(String? risk) {
    if (risk == null) return Colors.grey;
    switch (risk) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.yellow[700]!;
      case 'High':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRadonColor(String? risk) {
    if (risk == null) return Colors.grey;
    switch (risk) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.yellow[700]!;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        icon: Icon(
          Icons.delete_outline_rounded,
          size: 48,
          color: theme.colorScheme.error,
        ),
        title: const Text('Delete Location'),
        content: Text(
          'Are you sure you want to delete "${widget.location.name}"? This action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await DatabaseService().deletePinnedLocation(widget.location.id);
              if (context.mounted) {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                widget.onDeleted?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('${widget.location.name} deleted'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}