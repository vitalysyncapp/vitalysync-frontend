import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/recovery_mode_service.dart';

class RecoveryModePage extends StatelessWidget {
  final RecoveryModeSnapshot snapshot;
  final VoidCallback? onLogRequested;

  const RecoveryModePage({
    super.key,
    required this.snapshot,
    this.onLogRequested,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom + 24;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F8F2),
              Color(0xFFEAF4FF),
              Color(0xFFF5EDFF),
              Color(0xFFFFF8E6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 18),
                    _buildHero(context),
                    const SizedBox(height: 18),
                    _buildInsightCard(context),
                    const SizedBox(height: 14),
                    _buildAdviceSection(context),
                    const SizedBox(height: 14),
                    _buildHelpSection(context),
                    const SizedBox(height: 14),
                    _buildEvidenceNote(context),
                    const SizedBox(height: 18),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _SoftPill(
          icon: Icons.health_and_safety_rounded,
          label: _isCritical ? 'Critical recovery mode' : 'Recovery mode',
          color: const Color(0xFF177E74),
        ),
        const Spacer(),
        SizedBox(
          width: 42,
          height: 42,
          child: IconButton(
            tooltip: 'Close recovery mode',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF234155),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              shape: const CircleBorder(),
              side: BorderSide(
                color: const Color(0xFF234155).withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final score = snapshot.scorePercent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ScoreBadge(score: score),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pause. Let today get lighter.',
                style: TextStyle(
                  color: const Color(0xFF17364A),
                  fontSize: _responsiveTitleSize(context),
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                score == null
                    ? 'Your last pattern still needs recovery support. This is a signal to go gently, not a failure.'
                    : 'Your burnout risk is $score%. This is a signal to lower pressure and ask for support, not a failure.',
                style: const TextStyle(
                  color: Color(0xFF536879),
                  fontSize: 14.2,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    final nudge = snapshot.primaryNudge;
    final pattern = snapshot.primaryPattern;
    final title = _cleanText(
      nudge?.title,
      fallback: pattern?.title ?? 'Your body is asking for recovery',
    );
    final message = _cleanText(
      nudge?.message,
      fallback:
          pattern?.message ??
          'Keep the next step small. Rest, support, and a lighter load matter today.',
    );
    final report = snapshot.insightReports.isEmpty
        ? null
        : snapshot.insightReports.first;

    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF7357C8),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Generated insight and nudge',
                  style: TextStyle(
                    color: Color(0xFF17364A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF17364A),
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _shortText(message, 190),
            style: const TextStyle(
              color: Color(0xFF536879),
              fontSize: 13.3,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (report != null && report.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _MiniNote(
              icon: Icons.insights_rounded,
              label: _shortText(report.summary, 150),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SoftPill(
                icon: Icons.warning_amber_rounded,
                label: _riskText(),
                color: const Color(0xFFE07A35),
              ),
              _SoftPill(
                icon: Icons.spa_rounded,
                label: 'Recovery first',
                color: const Color(0xFF177E74),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          emoji: '\u{1F33F}',
          title: 'What to do now',
          subtitle: 'Small steps are enough for today.',
        ),
        const SizedBox(height: 10),
        ..._recoveryAdvice.map(
          (advice) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AdviceCard(advice: advice),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeader(
          emoji: '\u{1F90D}',
          title: 'Help that counts',
          subtitle: 'You do not have to carry this alone.',
        ),
        SizedBox(height: 10),
        _HelpCard(
          icon: Icons.volunteer_activism_rounded,
          title: 'Tell one safe person',
          body:
              'Send a short message: "I am running low today. Can you check in?"',
          color: Color(0xFF177E74),
        ),
        SizedBox(height: 10),
        _HelpCard(
          icon: Icons.psychology_alt_rounded,
          title: 'Ask for professional support',
          body:
              'If this keeps affecting sleep, work, school, or relationships, a counselor, doctor, or mental health professional can help.',
          color: Color(0xFF7357C8),
        ),
        SizedBox(height: 10),
        _HelpCard(
          icon: Icons.emergency_share_rounded,
          title: 'If you may not be safe',
          body:
              'Contact local emergency services or a crisis line now. Immediate help is the right step.',
          color: Color(0xFFD85C5C),
        ),
      ],
    );
  }

  Widget _buildEvidenceNote(BuildContext context) {
    return _SectionSurface(
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _IconBubble(
                icon: Icons.fact_check_rounded,
                color: Color(0xFF2067C9),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These tips follow common findings from sleep, movement, social support, and mindfulness research.',
                  style: TextStyle(
                    color: Color(0xFF17364A),
                    fontSize: 13.1,
                    height: 1.38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _EvidenceChip(label: 'Sleep'),
              _EvidenceChip(label: 'Gentle movement'),
              _EvidenceChip(label: 'Support'),
              _EvidenceChip(label: 'Mindful pause'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onLogRequested == null
                ? null
                : () {
                    Navigator.of(context).maybePop();
                    Future<void>.microtask(() => onLogRequested?.call());
                  },
            icon: const Icon(Icons.monitor_heart_rounded, size: 20),
            label: const Text('Log a gentle check-in'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF1EAD83),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('Close for now'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF234155),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  String _riskText() {
    final score = snapshot.scorePercent;
    if (score != null) {
      return '$score% risk';
    }

    return '${_titleCase(snapshot.riskLevel)} risk';
  }

  bool get _isCritical {
    final score = snapshot.scorePercent;
    return score != null && score >= RecoveryModeService.criticalThreshold;
  }
}

class _ScoreBadge extends StatelessWidget {
  final int? score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final label = score == null ? 'Care' : '$score%';

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB37A), Color(0xFFE56F6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE56F6F).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'pause',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  final Widget child;
  final bool compact;

  const _SectionSurface({required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5DA6A0).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 17)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF17364A),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF536879),
                  fontSize: 12.8,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final _RecoveryAdvice advice;

  const _AdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      compact: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: advice.icon, color: advice.color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.title,
                  style: const TextStyle(
                    color: Color(0xFF17364A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  advice.body,
                  style: const TextStyle(
                    color: Color(0xFF536879),
                    fontSize: 12.8,
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _EvidenceChip(label: advice.evidenceLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _HelpCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      compact: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: icon, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF17364A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF536879),
                    fontSize: 12.8,
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniNote extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniNote({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9DBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF2067C9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF25496A),
                fontSize: 12.4,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SoftPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  final String label;

  const _EvidenceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6EEE4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF177E74),
          fontSize: 11.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecoveryAdvice {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String evidenceLabel;

  const _RecoveryAdvice({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.evidenceLabel,
  });
}

const _recoveryAdvice = [
  _RecoveryAdvice(
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF7357C8),
    title: 'Take one quiet pause',
    body:
        'Put both feet down. Take three slow breaths. Pick only the next small step.',
    evidenceLabel: 'Mindful pause',
  ),
  _RecoveryAdvice(
    icon: Icons.bedtime_rounded,
    color: Color(0xFF2067C9),
    title: 'Protect sleep tonight',
    body:
        'Dim screens, keep the room calm, and aim for 7 or more hours if you can.',
    evidenceLabel: 'Sleep recovery',
  ),
  _RecoveryAdvice(
    icon: Icons.low_priority_rounded,
    color: Color(0xFFE07A35),
    title: 'Make the load smaller',
    body:
        'Choose one task to delay, share, or make simpler. Lowering pressure is recovery.',
    evidenceLabel: 'Workload support',
  ),
  _RecoveryAdvice(
    icon: Icons.directions_walk_rounded,
    color: Color(0xFF177E74),
    title: 'Move gently',
    body: 'Try a 10-minute walk or light stretch. Keep it easy, not punishing.',
    evidenceLabel: 'Gentle movement',
  ),
];

double _responsiveTitleSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return math.min(width < 370 ? 26 : 30, 30);
}

String _cleanText(String? value, {required String fallback}) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return fallback;
  }

  return text;
}

String _shortText(String value, int maxChars) {
  final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.length <= maxChars) {
    return text;
  }

  return '${text.substring(0, maxChars - 1).trimRight()}...';
}

String _titleCase(String value) {
  final words = value
      .trim()
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return 'Elevated';
  }

  return words
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
