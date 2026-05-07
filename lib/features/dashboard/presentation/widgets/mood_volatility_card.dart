import 'package:flutter/material.dart';

import '../../data/weekly_user_metrics.dart';

class MoodVolatilityCard extends StatefulWidget {
  const MoodVolatilityCard({super.key});

  @override
  State<MoodVolatilityCard> createState() => _MoodVolatilityCardState();
}

class _MoodVolatilityCardState extends State<MoodVolatilityCard> {
  late Future<WeeklyUserMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = WeeklyUserMetricsService.loadCurrentWeek();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeeklyUserMetrics>(
      future: _future,
      builder: (context, snapshot) {
        final metrics = snapshot.data;
        final days = metrics?.days ?? const <DailyUserMetric>[];
        final progress = ((metrics?.moodIndex ?? 0) / 100).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mood Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F44),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: Color(0xFF1FB489),
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This week',
                      style: TextStyle(color: Color(0xFF5C6B80), fontSize: 15),
                    ),
                  ),
                  Text(
                    metrics?.moodStabilityLabel ?? 'Loading',
                    style: const TextStyle(
                      color: Color(0xFF5C6B80),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF11C95D),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: days.map((day) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _moodEmoji(day.moodIndex),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF24324A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            day.dayLabel.substring(0, 1),
                            style: const TextStyle(
                              color: Color(0xFF5C6B80),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _moodEmoji(int? value) {
    switch (value) {
      case 4:
        return '\u{1F60A}';
      case 3:
        return '\u{1F642}';
      case 2:
        return '\u{1F610}';
      case 1:
        return '\u{1F641}';
      case 0:
        return '\u{1F61E}';
      default:
        return '--';
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.withValues(alpha: 0.10)),
    );
  }
}
