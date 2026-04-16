import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class VersionPage extends StatefulWidget {
  const VersionPage({super.key});

  @override
  State<VersionPage> createState() => _VersionPageState();
}

class _VersionPageState extends State<VersionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formattedDate() {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = pagePrimaryTextColor(context);
    final secondary = pageSecondaryTextColor(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF08111E)
          : const Color(0xFFF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Version',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _AnimatedBackdrop(
                progress: _controller.value,
                isDark: isDark,
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    pageBottomContentPadding(context, extra: 24),
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 560),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : const Color(0xFFDBEAFE),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.22 : 0.08,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Version 1.0',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _formattedDate(),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Developer: VitalySync Team',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primary.withOpacity(0.88),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Release Notes: \n- App is still in early stage of development, but you can explore the home screen and settings. More features coming soon!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 1.45,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _AnimatedBackdrop({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final background = isDark
        ? const [
            Color(0xFF07101D),
            Color(0xFF0F1C2F),
            Color(0xFF0A1626),
          ]
        : const [
            Color(0xFFE6F4FF),
            Color(0xFFFDFEFF),
            Color(0xFFDFF1FF),
          ];

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: background,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        _MovingOrb(
          alignment: Alignment(
            math.sin(progress * math.pi * 2) * 0.75,
            -0.6 + math.cos(progress * math.pi * 2) * 0.22,
          ),
          size: 240,
          color: isDark
              ? const Color(0xFF3B82F6).withOpacity(0.22)
              : const Color(0xFF60A5FA).withOpacity(0.26),
        ),
        _MovingOrb(
          alignment: Alignment(
            0.7 + math.cos(progress * math.pi * 2) * 0.18,
            math.sin(progress * math.pi * 2) * 0.55,
          ),
          size: 300,
          color: isDark
              ? const Color(0xFF22D3EE).withOpacity(0.16)
              : const Color(0xFF22C55E).withOpacity(0.16),
        ),
        _MovingOrb(
          alignment: Alignment(
            -0.7 + math.sin(progress * math.pi * 2 + 1.4) * 0.2,
            0.7 + math.cos(progress * math.pi * 2 + 0.8) * 0.16,
          ),
          size: 220,
          color: isDark
              ? const Color(0xFFF59E0B).withOpacity(0.12)
              : const Color(0xFF38BDF8).withOpacity(0.18),
        ),
      ],
    );
  }
}

class _MovingOrb extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final Color color;

  const _MovingOrb({
    required this.alignment,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
