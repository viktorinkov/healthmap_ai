import 'package:flutter/material.dart';
import '../models/pollen_data.dart';
import '../services/pollen_api_service.dart';
import 'pollen_forecast_chart.dart';

class PollenForecastSection extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const PollenForecastSection({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.locationName,
  }) : super(key: key);

  @override
  State<PollenForecastSection> createState() => _PollenForecastSectionState();
}

class _PollenForecastSectionState extends State<PollenForecastSection> {
  PollenForecast? _forecast;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPollenData();
  }

  Future<void> _loadPollenData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final forecast = await PollenApiService.getPollenForecast(
        widget.latitude,
        widget.longitude,
        days: 5,
      );

      if (mounted) {
        setState(() {
          _forecast = forecast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load pollen data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              const Icon(Icons.local_florist, size: 20),
              const SizedBox(width: 8),
              Text(
                '5-Day Pollen Forecast',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading && _forecast == null)
            _buildLoadingWidget(context)
          else if (_error != null)
            _buildErrorWidget(context)
          else if (_forecast == null)
            _buildNoDataWidget(context)
          else
            _buildPollenCharts(context),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading pollen data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadPollenData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.local_florist,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Pollen data not available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pollen forecast information is currently unavailable for this location.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollenCharts(BuildContext context) {
    if (_forecast == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Overall pollen forecast chart
        PollenForecastChart(
          pollenForecast: _forecast!.dailyInfo,
          height: 250,
        ),
        const SizedBox(height: 20),

        // Today's detailed pollen breakdown
        _buildTodaysBreakdown(context),
        const SizedBox(height: 20),

        // Individual pollen type charts
        _buildIndividualTypeCharts(context),
      ],
    );
  }

  Widget _buildTodaysBreakdown(BuildContext context) {
    final todaysPollen = PollenApiService.getTodaysPollen(_forecast!);

    if (todaysPollen == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Pollen Levels',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPollenTypeCard(
                    context,
                    PollenType.grass,
                    todaysPollen.pollenTypeInfo.where((t) => t.code == PollenType.grass).firstOrNull,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPollenTypeCard(
                    context,
                    PollenType.tree,
                    todaysPollen.pollenTypeInfo.where((t) => t.code == PollenType.tree).firstOrNull,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPollenTypeCard(
                    context,
                    PollenType.weed,
                    todaysPollen.pollenTypeInfo.where((t) => t.code == PollenType.weed).firstOrNull,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollenTypeCard(BuildContext context, PollenType type, PollenTypeInfo? info) {
    final index = info?.indexInfo?.value ?? 0;
    final category = info?.indexInfo?.category ?? PollenIndexCategory.none;
    final inSeason = info?.inSeason ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: category.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            type.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            type.displayName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            index.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: category.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (inSeason) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'In Season',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.green[700],
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndividualTypeCharts(BuildContext context) {
    if (_forecast == null) return const SizedBox.shrink();

    // Check which pollen types have data
    final hasGrassData = _forecast!.dailyInfo.any((day) =>
      day.pollenTypeInfo.any((type) => type.code == PollenType.grass && (type.indexInfo?.value ?? 0) > 0));
    final hasTreeData = _forecast!.dailyInfo.any((day) =>
      day.pollenTypeInfo.any((type) => type.code == PollenType.tree && (type.indexInfo?.value ?? 0) > 0));
    final hasWeedData = _forecast!.dailyInfo.any((day) =>
      day.pollenTypeInfo.any((type) => type.code == PollenType.weed && (type.indexInfo?.value ?? 0) > 0));

    return Column(
      children: [
        if (hasGrassData) ...[
          PollenForecastChart(
            pollenForecast: _forecast!.dailyInfo,
            height: 180,
            specificType: PollenType.grass,
          ),
          const SizedBox(height: 16),
        ],
        if (hasTreeData) ...[
          PollenForecastChart(
            pollenForecast: _forecast!.dailyInfo,
            height: 180,
            specificType: PollenType.tree,
          ),
          const SizedBox(height: 16),
        ],
        if (hasWeedData) ...[
          PollenForecastChart(
            pollenForecast: _forecast!.dailyInfo,
            height: 180,
            specificType: PollenType.weed,
          ),
        ],
      ],
    );
  }
}