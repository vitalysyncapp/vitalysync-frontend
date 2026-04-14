import 'package:flutter/material.dart';

class DashboardHeaderCard extends StatelessWidget {
  const DashboardHeaderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [
        Color.fromARGB(255, 30, 203, 154),
        Color.fromARGB(255, 55, 164, 222),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
        color: Colors.blue.withOpacity(0.18),
        blurRadius: 18,
        offset: const Offset(0, 8),
        ),
      ],
      ),
      child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
        "Your Wellness Analytics Dashboard",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        ),
        SizedBox(height: 6),
        Text(
        "Track your wellness trends, sleep, mood, symptoms, and overall performance.",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.4,
        ),
        ),
      ],
      ),
    );
  }
}