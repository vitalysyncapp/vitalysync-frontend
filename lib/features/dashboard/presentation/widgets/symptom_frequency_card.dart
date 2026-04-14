import 'package:flutter/material.dart';

class SymptomFrequencyCard extends StatelessWidget {
  const SymptomFrequencyCard({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Symptom Frequency",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F44),
            ),
          ),
          const SizedBox(height: 20),
          _symptomRow(
            label: "Headache",
            days: "2 days",
            progress: 0.28,
            color: const Color(0xFFFF3B4A),
          ),
          _symptomRow(
            label: "Fatigue",
            days: "5 days",
            progress: 0.72,
            color: const Color(0xFFFF6B00),
          ),
          _symptomRow(
            label: "Irritability",
            days: "3 days",
            progress: 0.43,
            color: const Color(0xFFE6A800),
          ),
          _symptomRow(
            label: "Anxiety",
            days: "1 days",
            progress: 0.14,
            color: const Color(0xFFA64DFF),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.94),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.10)),
    );
  }
}