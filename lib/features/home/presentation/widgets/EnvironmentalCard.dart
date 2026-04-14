import 'package:flutter/material.dart';

class EnvironmentalCard extends StatelessWidget {
  final String weather;
  final String weatherStatus;
  final String airQuality;
  final String airStatus;

  const EnvironmentalCard({
    Key? key,
    required this.weather,
    required this.weatherStatus,
    required this.airQuality,
    required this.airStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive colors
    final cardBackground = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[700];

    // Status colors
    final weatherColor = weatherStatus.toLowerCase() == 'good'
        ? Colors.greenAccent
        : Colors.orangeAccent;
    final airColor = airStatus.toLowerCase() == 'good'
        ? Colors.greenAccent
        : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
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
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Weather: $weather',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
              Text(
                weatherStatus,
                style: TextStyle(
                  color: weatherColor,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.air, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Air Quality: $airQuality',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
              Text(
                airStatus,
                style: TextStyle(
                  color: airColor,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sample usage
Widget sampleEnvironmentalCard() {
  return EnvironmentalCard(
    weather: '26°C',
    weatherStatus: 'Good',
    airQuality: 'Moderate',
    airStatus: 'Moderate',
  );
}