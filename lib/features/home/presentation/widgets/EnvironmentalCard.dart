import 'package:flutter/material.dart';

import '../../data/environment_model.dart';
import '../../../../shared/theme/app_page_style.dart';

class EnvironmentalCard extends StatelessWidget {
  final EnvironmentSnapshot? snapshot;
  final bool isLoading;
  final String? errorMessage;

  const EnvironmentalCard({
    super.key,
    required this.snapshot,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.08,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environmental Conditions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            _buildLoadingState(context)
          else if (errorMessage != null)
            _buildErrorState(context, errorMessage!)
          else if (snapshot != null)
            _buildContent(context, snapshot!)
          else
            _buildErrorState(context, 'Environment data is unavailable'),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, EnvironmentSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          snapshot.location,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: pageSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 14),
        _row(
          context: context,
          icon: Icons.wb_sunny_rounded,
          iconColor: Colors.amber,
          label: 'Weather',
          value:
              '${snapshot.weather.description}, ${snapshot.weather.temperatureC.toStringAsFixed(1)}\u00B0C',
          status: _buildWeatherStatus(snapshot.weather.main),
          statusColor: _statusColor(snapshot.weather.main),
        ),
        const SizedBox(height: 12),
        _row(
          context: context,
          icon: Icons.opacity_rounded,
          iconColor: Colors.lightBlueAccent,
          label: 'Humidity',
          value: '${snapshot.weather.humidity}%',
          status: 'Now',
          statusColor: Colors.lightBlueAccent,
        ),
        const SizedBox(height: 12),
        _row(
          context: context,
          icon: Icons.air_rounded,
          iconColor: Colors.blueAccent,
          label: 'Air Quality',
          value: 'AQI ${snapshot.airQuality.aqi}',
          status: snapshot.airQuality.aqiLabel,
          statusColor: _statusColor(snapshot.airQuality.aqiLabel),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Loading live weather and air quality...',
            style: TextStyle(color: pagePrimaryTextColor(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              height: 1.4,
              color: pagePrimaryTextColor(context),
            ),
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
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(color: pagePrimaryTextColor(context)),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
