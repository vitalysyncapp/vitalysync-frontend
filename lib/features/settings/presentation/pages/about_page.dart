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
              _SectionCard(
                title: 'About VitalySync',
                children: const [
                  _InfoBlock(
                    text:
                        'VitalySync is a wellness-focused app experience designed to help users keep track of burnout risk, routines, reminders, and personal health insights.',
                  ),
                  _InfoBlock(
                    text:
                        'This project is developed as part of a university course on Computer Science and Technology.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Team',
                children: const [
                  _InfoBlock(
                    text:
                        'Developers: \n  Orlandone Estoce \n  Rynhard Mencede \n  Krischalyn Estorgio \n  Jomel Logroño',
                  ),
                  _InfoBlock(
                    text:
                        'Adviser: Ms. Sheila Mae Anud Lumayag \nMental Health Professional: Phd. Atty. Raymond Culas Jr.',
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
