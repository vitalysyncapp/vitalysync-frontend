import 'package:flutter/material.dart';

class MoodVolatilityCard extends StatelessWidget {
  const MoodVolatilityCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final moods = [
      {"emoji": "😊", "day": "M"},
      {"emoji": "😳", "day": "T"},
      {"emoji": "😳", "day": "W"},
      {"emoji": "😰", "day": "T"},
      {"emoji": "😊", "day": "F"},
      {"emoji": "😊", "day": "S"},
      {"emoji": "😳", "day": "S"},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mood Volatility",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F44),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Text("😊", style: TextStyle(fontSize: 34)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "This Week",
                  style: TextStyle(
                    color: Color(0xFF5C6B80),
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                "Stable",
                style: TextStyle(
                  color: Color(0xFF5C6B80),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              Container(
                height: 10,
                width: MediaQuery.of(context).size.width * 0.58,
                decoration: BoxDecoration(
                  color: const Color(0xFF11C95D),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: moods.map((item) {
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
                        item["emoji"]!,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item["day"]!,
                        style: const TextStyle(
                          color: Color(0xFF5C6B80),
                          fontSize: 15,
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