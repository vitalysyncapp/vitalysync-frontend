import 'package:flutter/material.dart';

import '../../data/weekly_user_metrics.dart';

class SymptomFrequencyCard extends StatefulWidget {
  const SymptomFrequencyCard({super.key});

  @override
  State<SymptomFrequencyCard> createState() => _SymptomFrequencyCardState();
}

class _SymptomFrequencyCardState extends State<SymptomFrequencyCard> {
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
        final counts = snapshot.data?.symptomCounts ?? const <String, int>{};
        final rows = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final visibleRows = rows.take(4).toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Symptom Frequency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F44),
                ),
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleRows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No symptoms logged this week.',
                    style: TextStyle(color: Color(0xFF4F5D75), fontSize: 15),
                  ),
                )
              else
                ...visibleRows.map(
                  (entry) => _symptomRow(
                    label: entry.key,
                    days: '${entry.value} ${entry.value == 1 ? 'day' : 'days'}',
                    progress: (entry.value / 7).clamp(0.0, 1.0),
                    color: _colorFor(entry.value),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _symptomRow({
    required String label,
    required String days,
    required double progress,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF24324A),
                  ),
                ),
              ),
              Text(
                days,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(int days) {
    if (days >= 5) return const Color(0xFFFF3B4A);
    if (days >= 3) return const Color(0xFFFF6B00);
    return const Color(0xFFE6A800);
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
