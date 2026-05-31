import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class AboutBurnoutPage extends StatelessWidget {
  const AboutBurnoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: pagePrimaryTextColor(context),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'About Burnout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              pageBottomContentPadding(context),
            ),
            children: const [
              _HeroCard(),
              SizedBox(height: 16),
              _SectionCard(
                icon: Icons.psychology_alt_outlined,
                color: Color(0xFF2563EB),
                title: 'What Burnout Means',
                children: [
                  _Paragraph(
                    text:
                        'The World Health Organization describes burnout as an occupational phenomenon from chronic workplace stress that has not been successfully managed. It is not a medical diagnosis, but it can be an important warning sign that your demands and recovery are out of balance.',
                  ),
                  _Paragraph(
                    text:
                        'Work is the formal definition, but students, caregivers, and people carrying long-term responsibilities can notice similar chronic-stress patterns.',
                  ),
                ],
              ),
              SizedBox(height: 16),
              _SectionCard(
                icon: Icons.bubble_chart_outlined,
                color: Color(0xFF7C3AED),
                title: 'Three Core Signals',
                children: [
                  _SignalItem(
                    emoji: '🔥',
                    icon: Icons.battery_alert_rounded,
                    title: 'Exhaustion',
                    text:
                        'Feeling emotionally or physically drained, even after ordinary rest.',
                  ),
                  _SignalItem(
                    emoji: '🧠',
                    icon: Icons.cloud_outlined,
                    title: 'Distance or cynicism',
                    text:
                        'Feeling detached, negative, numb, or unusually irritable toward work or responsibilities.',
                  ),
                  _SignalItem(
                    emoji: '📉',
                    icon: Icons.trending_down_rounded,
                    title: 'Reduced effectiveness',
                    text:
                        'Feeling less capable, less focused, or less satisfied with what you can accomplish.',
                  ),
                ],
              ),
              SizedBox(height: 16),
              _SectionCard(
                icon: Icons.favorite_border_rounded,
                color: Color(0xFFDC2626),
                title: 'How It Can Affect People',
                children: [
                  _BulletItem(
                    icon: Icons.bedtime_outlined,
                    text:
                        'Sleep can become lighter, shorter, or less restorative.',
                  ),
                  _BulletItem(
                    icon: Icons.mood_bad_outlined,
                    text:
                        'Low mood, anxiety, irritability, or depressive symptoms may become more likely.',
                  ),
                  _BulletItem(
                    icon: Icons.speed_rounded,
                    text:
                        'Attention, memory, motivation, and performance can drop.',
                  ),
                  _BulletItem(
                    icon: Icons.people_outline_rounded,
                    text:
                        'People may withdraw socially, feel less patient, or recover more slowly after stress.',
                  ),
                ],
              ),
              SizedBox(height: 16),
              _SectionCard(
                icon: Icons.balance_rounded,
                color: Color(0xFFF97316),
                title: 'Main Reasons It Grows',
                children: [
                  _Paragraph(
                    text:
                        'Research models often describe burnout as an imbalance: demands stay high while resources, control, support, and recovery stay too low.',
                  ),
                  _ReasonChips(),
                ],
              ),
              SizedBox(height: 16),
              _SectionCard(
                icon: Icons.fact_check_outlined,
                color: Color(0xFF0F766E),
                title: 'Evidence Base',
                children: [
                  _SourceItem(
                    label: 'WHO ICD-11 burnout page',
                    url:
                        'https://www.who.int/standards/classifications/frequently-asked-questions/burn-out-an-occupational-phenomenon',
                  ),
                  _SourceItem(
                    label: 'Maslach burnout dimensions via PubMed',
                    url: 'https://pubmed.ncbi.nlm.nih.gov/1981064/',
                  ),
                  _SourceItem(
                    label: 'Job Demands-Resources model via PubMed',
                    url: 'https://pubmed.ncbi.nlm.nih.gov/11419809/',
                  ),
                  _SourceItem(
                    label: 'Burnout consequences systematic review',
                    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC5627926/',
                  ),
                  _SourceItem(
                    label: 'Burnout, depression, and anxiety meta-analysis',
                    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC6424886/',
                  ),
                ],
              ),
              SizedBox(height: 16),
              _SupportNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF17304A), Color(0xFF163D35)]
              : const [Color(0xFFEAF7FF), Color(0xFFEAFBF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: pageBorderColor(context)),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: isDark
                      ? const Color(0xFFFFB86B)
                      : const Color(0xFFF97316),
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Burnout is a chronic stress signal',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'It usually builds gradually when pressure keeps outpacing recovery.',
                      style: TextStyle(
                        height: 1.4,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroPill(icon: Icons.work_outline_rounded, label: 'Work-first'),
              _HeroPill(icon: Icons.school_outlined, label: 'Student-aware'),
              _HeroPill(icon: Icons.spa_outlined, label: 'Recovery matters'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Text(
        text,
        style: TextStyle(
          height: 1.48,
          color: pageSecondaryTextColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SignalItem extends StatelessWidget {
  final String emoji;
  final IconData icon;
  final String title;
  final String text;

  const _SignalItem({
    required this.emoji,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(emoji: emoji, icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    height: 1.38,
                    color: pageSecondaryTextColor(context),
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

class _BulletItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.38,
                color: pageSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChips extends StatelessWidget {
  const _ReasonChips();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _ReasonChipData(Icons.fitness_center_rounded, 'High demands'),
      _ReasonChipData(Icons.hourglass_empty_rounded, 'Low recovery'),
      _ReasonChipData(Icons.tune_rounded, 'Low control'),
      _ReasonChipData(Icons.emoji_events_outlined, 'Low reward'),
      _ReasonChipData(Icons.groups_outlined, 'Weak support'),
      _ReasonChipData(Icons.gavel_outlined, 'Unfairness'),
      _ReasonChipData(Icons.explore_outlined, 'Values mismatch'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: items.map((item) => _ReasonChip(item: item)).toList(),
      ),
    );
  }
}

class _SourceItem extends StatelessWidget {
  final String label;
  final String url;

  const _SourceItem({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.link_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  url,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 12.5,
                    height: 1.35,
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

class _SupportNote extends StatelessWidget {
  const _SupportNote();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF5BDEC1) : const Color(0xFF0F766E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'VitalySync can help you notice patterns, but it does not diagnose or replace professional care. If stress feels unmanageable, consider talking with a trusted person or a qualified health professional.',
              style: TextStyle(
                height: 1.42,
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final String emoji;
  final IconData icon;

  const _IconBadge({required this.emoji, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

class _ReasonChipData {
  final IconData icon;
  final String label;

  const _ReasonChipData(this.icon, this.label);
}

class _ReasonChip extends StatelessWidget {
  final _ReasonChipData item;

  const _ReasonChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Text(
            item.label,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
