import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WellnessIndexCard extends StatelessWidget {
  const WellnessIndexCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Wellness Index",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F44),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBorderData: const BorderSide(color: Colors.transparent),
                gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.20)),
                tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ticksTextStyle: const TextStyle(
                  color: Color(0xFF9AA5B1),
                  fontSize: 11,
                ),
                getTitle: (index, angle) {
                  const titles = [
                    "Sleep",
                    "Mood",
                    "Energy",
                    "Hydration",
                    "Exercise",
                    "Nutrition",
                  ];
                  return RadarChartTitle(
                    text: titles[index],
                    angle: 0,
                  );
                },
                titleTextStyle: const TextStyle(
                  color: Color(0xFF8A6B52),
                  fontSize: 14,
                ),
                titlePositionPercentageOffset: 0.18,
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFF39C8A5).withOpacity(0.50),
                    borderColor: const Color(0xFF1AB98F),
                    entryRadius: 2,
                    borderWidth: 2,
                    dataEntries: const [
                      RadarEntry(value: 72),
                      RadarEntry(value: 60),
                      RadarEntry(value: 58),
                      RadarEntry(value: 55),
                      RadarEntry(value: 68),
                      RadarEntry(value: 78),
                    ],
                  ),
                ],
                tickCount: 4,
              ),
            ),
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