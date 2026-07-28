import 'package:flutter/material.dart';

class SmartNudgeCard extends StatelessWidget {
  final String message;
  final String severity;

  const SmartNudgeCard({
    super.key,
    required this.message,
    this.severity = 'steady',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF7C2D12), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFDE68A), Color(0xFFFDE68A), Color(0xFFFFF7CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final textColor = isDark ? Colors.white : const Color(0xFF3F2A00);
    final userFacingSeverity = _userFacingSeverity(severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.amber.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's smart nudge",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _severityLabel(userFacingSeverity),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              color: textColor,
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String _userFacingSeverity(String value) {
    switch (value.trim().toLowerCase().replaceAll(RegExp(r'[-\s]+'), '_')) {
      case 'critical':
      case 'urgent':
      case 'needs_support':
        return 'needs support';
      case 'high_risk':
      case 'high':
        return 'high';
      case 'watch':
      case 'moderate':
      case 'medium':
        return 'watch';
      default:
        return 'steady';
    }
  }

  String _severityLabel(String value) {
    return value
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
