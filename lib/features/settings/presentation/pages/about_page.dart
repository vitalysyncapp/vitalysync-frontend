import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
            'About',
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
            children: [
              _HeroCard(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'What VitalySync does',
                children: const [
                  _InfoBlock(
                    text:
                        'VitalySync is a wellness-focused app experience for burnout risk awareness, routine tracking, reminders, and personal health insights.',
                  ),
                  _FocusChips(),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Team',
                children: const [
                  _PersonBlock(
                    name: 'Orlandone Estoce',
                    role: 'Lead developer',
                  ),
                  _PersonBlock(name: 'Rynhard Mencede', role: 'Developer'),
                  _PersonBlock(name: 'Krischalyn Estorgio', role: 'Developer'),
                  _PersonBlock(name: 'Jomel Logroño', role: 'Developer'),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Guidance',
                children: const [
                  _CreditBlock(
                    icon: Icons.school_outlined,
                    title: 'Adviser',
                    subtitle: 'Ms. Sheila Mae Anud Lumayag',
                  ),
                  _CreditBlock(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Mental health professional',
                    subtitle: 'To be added',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Illustration credits',
                children: const [
                  _CreditBlock(
                    icon: Icons.face_retouching_natural_outlined,
                    title: 'Personas avatars',
                    subtitle:
                        'Personas by Draftbit, generated with DiceBear · CC BY 4.0',
                  ),
                  _CreditBlock(
                    icon: Icons.badge_outlined,
                    title: 'Professional avatars',
                    subtitle:
                        'Avataaars by Pablo Stanley, generated with DiceBear',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF163447), Color(0xFF17322E)]
              : const [Color(0xFFEAF7FF), Color(0xFFEAFBF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: pageBorderColor(context)),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.spa_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VitalySync',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Burnout risk awareness and adaptive lifestyle support.',
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
          Text(
            'Built as a calm wellness companion for tracking routines, reading personal insights, and supporting healthier daily patterns.',
            style: TextStyle(
              height: 1.55,
              color: pageSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String text;

  const _InfoBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Text(
        text,
        style: TextStyle(height: 1.45, color: pageSecondaryTextColor(context)),
      ),
    );
  }
}

class _FocusChips extends StatelessWidget {
  const _FocusChips();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _FocusChipData(Icons.psychology_alt_outlined, 'Burnout awareness'),
      _FocusChipData(Icons.insights_rounded, 'Wellness analytics'),
      _FocusChipData(Icons.notifications_active_outlined, 'Adaptive reminders'),
      _FocusChipData(Icons.restaurant_menu_rounded, 'Lifestyle logging'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) => _FocusChip(item: item)).toList(),
      ),
    );
  }
}

class _FocusChipData {
  final IconData icon;
  final String label;

  const _FocusChipData(this.icon, this.label);
}

class _FocusChip extends StatelessWidget {
  final _FocusChipData item;

  const _FocusChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonBlock extends StatelessWidget {
  final String name;
  final String role;

  const _PersonBlock({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.14),
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(color: pageSecondaryTextColor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CreditBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    );
  }
}
