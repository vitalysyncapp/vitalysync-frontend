import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class EnvironmentalCard extends StatelessWidget {
  final String weather;
  final String weatherStatus;
  final String airQuality;
  final String airStatus;

  const EnvironmentalCard({
    super.key,
    required this.weather,
    required this.weatherStatus,
    required this.airQuality,
    required this.airStatus,
  });

  @override
  Widget build(BuildContext context) {
    final weatherColor =
        weatherStatus.toLowerCase() == 'good' ? Colors.green : Colors.orange;
    final airColor =
        airStatus.toLowerCase() == 'good' ? Colors.green : Colors.redAccent;

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
          _row(
            context: context,
            icon: Icons.wb_sunny_rounded,
            iconColor: Colors.amber,
            label: 'Weather',
            value: weather,
            status: weatherStatus,
            statusColor: weatherColor,
          ),
          const SizedBox(height: 12),
          _row(
            context: context,
            icon: Icons.air_rounded,
            iconColor: Colors.blueAccent,
            label: 'Air Quality',
            value: airQuality,
            status: airStatus,
            statusColor: airColor,
          ),
        ],
      ),
    );
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
