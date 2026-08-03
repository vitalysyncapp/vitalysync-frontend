import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/environment_model.dart';
import '../../data/environment_localization.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class EnvironmentalCard extends StatelessWidget {
  final EnvironmentSnapshot? snapshot;
  final bool isLoading;
  final bool isCached;
  final bool hasError;

  const EnvironmentalCard({
    super.key,
    required this.snapshot,
    required this.isLoading,
    this.isCached = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            'Environmental conditions',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            _buildLoadingState(context)
          else if (hasError)
            _buildErrorState(context)
          else if (snapshot != null)
            _buildContent(context, snapshot!)
          else
            _buildErrorState(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, EnvironmentSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCached) ...[
          _buildCachedBanner(context, snapshot),
          const SizedBox(height: 10),
        ],
        LocalizedText(
          snapshot.location,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: pageSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 10),
        _row(
          context: context,
          icon: Icons.wb_sunny_rounded,
          iconColor: Colors.amber,
          label: 'Weather',
          value:
              '${snapshot.weather.localizedDescription(context.l10n)}, ${snapshot.weather.temperatureC.toStringAsFixed(1)}\u00B0C',
          status: _buildWeatherStatus(snapshot.weather.main),
          statusColor: _statusColor(snapshot.weather.main),
        ),
        const SizedBox(height: 9),
        _row(
          context: context,
          icon: Icons.opacity_rounded,
          iconColor: Colors.lightBlueAccent,
          label: 'Humidity',
          value: '${snapshot.weather.humidity}%',
          status: 'Now',
          statusColor: Colors.lightBlueAccent,
        ),
        const SizedBox(height: 9),
        _row(
          context: context,
          icon: Icons.air_rounded,
          iconColor: Colors.blueAccent,
          label: 'Air quality',
          value: 'AQI ${snapshot.airQuality.aqi}',
          status: snapshot.airQuality.localizedLabel(context.l10n),
          statusColor: _statusColor(snapshot.airQuality.aqiLabel),
        ),
      ],
    );
  }

  Widget _buildCachedBanner(
    BuildContext context,
    EnvironmentSnapshot snapshot,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.history_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LocalizedText(
              'Using last saved environment snapshot from ${_formatSnapshotTime(snapshot.fetchedAt)}.',
              style: TextStyle(
                height: 1.35,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const AppSkeletonRows(count: 3, spacing: 9, showLeading: true);
  }

  Widget _buildErrorState(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LocalizedText(
            'Environment data is unavailable',
            style: TextStyle(height: 1.4, color: pagePrimaryTextColor(context)),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'fair':
      case 'clear':
        return Colors.green;
      case 'moderate':
      case 'clouds':
      case 'cloudy':
        return Colors.orange;
      case 'poor':
      case 'very poor':
      case 'rain':
      case 'storm':
      case 'thunderstorm':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _buildWeatherStatus(String main) {
    final normalized = main.toLowerCase();
    if (normalized == 'clear') return 'Clear';
    if (normalized == 'clouds') return 'Cloudy';
    if (normalized == 'rain' || normalized == 'drizzle') return 'Rain';
    if (normalized == 'thunderstorm') return 'Storm';
    return main;
  }

  String _formatSnapshotTime(DateTime fetchedAt) {
    return DateFormat.yMMMd().add_jm().format(fetchedAt.toLocal());
  }

  Widget _row({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: LocalizedText(
            '$label: $value',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 12.5,
            ),
          ),
        ),
        LocalizedText(
          status,
          style: TextStyle(
            color: statusColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
