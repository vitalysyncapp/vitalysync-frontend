import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class VersionPage extends StatelessWidget {
  const VersionPage({super.key});

  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '1';
  static const String _updatedDate = 'May 28, 2026';

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
            'Version',
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
              _VersionHeroCard(),
              SizedBox(height: 16),
              _DetailsCard(),
              SizedBox(height: 16),
              _ReleaseNotesCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionHeroCard extends StatelessWidget {
  const _VersionHeroCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.78),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: pageBorderColor(context)),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.spa_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'VitalySync',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Version ${VersionPage._appVersion}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build ${VersionPage._buildNumber} - Updated ${VersionPage._updatedDate}',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: pageSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard();

  @override
  Widget build(BuildContext context) {
    return _VersionSection(
      title: 'Build details',
      children: const [
        _DetailRow(
          icon: Icons.verified_outlined,
          label: 'App version',
          value: VersionPage._appVersion,
        ),
        _DetailRow(
          icon: Icons.tag_rounded,
          label: 'Build number',
          value: VersionPage._buildNumber,
        ),
        _DetailRow(
          icon: Icons.school_outlined,
          label: 'Project status',
          value: 'Academic preview',
        ),
        _DetailRow(
          icon: Icons.groups_outlined,
          label: 'Developer',
          value: 'VitalySync team',
        ),
      ],
    );
  }
}

class _ReleaseNotesCard extends StatelessWidget {
  const _ReleaseNotesCard();

  @override
  Widget build(BuildContext context) {
    return _VersionSection(
      title: 'Latest updates',
      children: const [
        _ReleaseNote(text: 'Refined settings layout and section hierarchy.'),
        _ReleaseNote(text: 'Improved help and support contact presentation.'),
        _ReleaseNote(
          text: 'Polished terms, privacy, about, and version pages.',
        ),
      ],
    );
  }
}

class _VersionSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _VersionSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.16
                  : 0.04,
            ),
            blurRadius: 14,
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
                fontWeight: FontWeight.w800,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: pagePrimaryTextColor(context),
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

class _ReleaseNote extends StatelessWidget {
  final String text;

  const _ReleaseNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: pageSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
