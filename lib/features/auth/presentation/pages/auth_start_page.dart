import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

import '../widgets/auth_chrome.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class AuthStartPage extends StatefulWidget {
  const AuthStartPage({super.key});

  @override
  State<AuthStartPage> createState() => _AuthStartPageState();
}

class _AuthStartPageState extends State<AuthStartPage> {
  static const _disclaimer =
      'VitalySync provides wellness insights for awareness only and does not replace medical advice.';
  static const _autoSlideInterval = Duration(seconds: 7);

  static const _slides = <_WelcomeSlideData>[
    _WelcomeSlideData(
      title: 'Feel your rhythm before burnout gets loud',
      subtitle:
          'Check in with sleep, mood, stress, workload, energy, and recovery so your day has a clearer signal.',
      illustrationAsset: 'assets/images/welcome_morning.svg',
      semanticsLabel: 'A calm morning wellness check-in illustration',
      gradientStart: Color(0xFFE8D5E0),
      gradientEnd: Color(0xFFF5E6EE),
      foregroundColor: Color(0xFF4A2D3F),
      accentColor: Color(0xFFBF7BA0),
      features: [
        _WelcomeFeature(icon: Icons.bedtime_rounded, label: 'Sleep'),
        _WelcomeFeature(icon: Icons.psychology_rounded, label: 'Mood'),
        _WelcomeFeature(icon: Icons.spa_rounded, label: 'Recovery'),
      ],
    ),
    _WelcomeSlideData(
      title: 'Track the signals that matter',
      subtitle:
          'Daily logs turn small habits like hydration, symptoms, activity, meals, and breaks into useful patterns.',
      illustrationAsset: 'assets/images/welcome_mindfulness.svg',
      semanticsLabel: 'A mindful daily balance illustration',
      gradientStart: Color(0xFFF5E6D0),
      gradientEnd: Color(0xFFFAF0E4),
      foregroundColor: Color(0xFF4A3520),
      accentColor: Color(0xFFD4A060),
      features: [
        _WelcomeFeature(icon: Icons.water_drop_rounded, label: 'Hydration'),
        _WelcomeFeature(icon: Icons.restaurant_rounded, label: 'Nutrition'),
        _WelcomeFeature(
          icon: Icons.directions_walk_rounded,
          label: 'Activity',
        ),
      ],
    ),
    _WelcomeSlideData(
      title: 'Get nudges that fit your day',
      subtitle:
          'Adaptive reminders and the smart assistant help you notice when to rest, move, drink water, or reset.',
      illustrationAsset: 'assets/images/welcome_reminders.svg',
      semanticsLabel: 'Gentle wellness reminders illustration',
      gradientStart: Color(0xFFD6DFF0),
      gradientEnd: Color(0xFFE8EEF8),
      foregroundColor: Color(0xFF293B54),
      accentColor: Color(0xFF7090C0),
      features: [
        _WelcomeFeature(
          icon: Icons.notifications_active_rounded,
          label: 'Reminders',
        ),
        _WelcomeFeature(icon: Icons.auto_awesome_rounded, label: 'Assistant'),
        _WelcomeFeature(icon: Icons.air_rounded, label: 'Breathing'),
      ],
    ),
    _WelcomeSlideData(
      title: 'See progress over time',
      subtitle:
          'Dashboards make trends easier to understand, from burnout risk and weekly analytics to goal progress.',
      illustrationAsset: 'assets/images/welcome_insights.svg',
      semanticsLabel: 'Personal wellness reports illustration',
      gradientStart: Color(0xFFCDE8E0),
      gradientEnd: Color(0xFFE2F4EE),
      foregroundColor: Color(0xFF1E3F34),
      accentColor: Color(0xFF5EAE90),
      features: [
        _WelcomeFeature(icon: Icons.show_chart_rounded, label: 'Trends'),
        _WelcomeFeature(icon: Icons.flag_rounded, label: 'Goals'),
        _WelcomeFeature(
          icon: Icons.health_and_safety_rounded,
          label: 'Awareness',
        ),
      ],
    ),
  ];

  late final LiquidController _liquidController;
  Timer? _autoSlideTimer;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    _liquidController = LiquidController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _autoSlideTimer?.cancel();
      _autoSlideTimer = null;
    } else if (_autoSlideTimer == null) {
      _scheduleAutoSlide();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoSlide() {
    if (_slides.length <= 1 || MediaQuery.disableAnimationsOf(context)) return;

    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(_autoSlideInterval, () {
      if (!mounted) return;
      _goToSlide((_currentSlide + 1) % _slides.length);
    });
  }

  void _goToSlide(int index) {
    final target = index % _slides.length;
    if (target == _currentSlide) return;

    if (MediaQuery.disableAnimationsOf(context) ||
        (_currentSlide == _slides.length - 1 && target == 0)) {
      _liquidController.jumpToPage(page: target);
    } else {
      _liquidController.animateToPage(page: target, duration: 620);
    }

    _scheduleAutoSlide();
  }

  void _handlePageChanged(int index) {
    if (!mounted || index == _currentSlide) return;
    setState(() => _currentSlide = index);
    _scheduleAutoSlide();
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      illustrationAsset: authHealthyLifestyleAsset,
      topOverlayAsset: authMeditationAsset,
      bottomOverlayAssets: const [authHealthyLifestyleAsset, authWorkoutAsset],
      backdropStyle: AuthBackdropStyle.welcome,
      centerContent: false,
      scrollable: false,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
          final panelWidth =
              constraints.maxWidth > 560 ? 560.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: panelWidth,
              height: constraints.maxHeight,
              child: AuthGlassPanel(
                maxWidth: 560,
                padding: EdgeInsets.zero,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LiquidSwipe.builder(
                      key: const ValueKey('auth-welcome-carousel'),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) => _WelcomeSlide(
                        data: _slides[index],
                        compact: compact,
                        bottomContentInset: compact ? 210 : 224,
                      ),
                      liquidController: _liquidController,
                      initialPage: _currentSlide,
                      onPageChangeCallback: _handlePageChanged,
                      waveType: WaveType.liquidReveal,
                      fullTransitionValue: 420,
                      enableLoop: true,
                      enableSideReveal: true,
                      preferDragFromRevealedArea: false,
                      ignoreUserGestureWhileAnimating: true,
                    ),
                    Positioned(
                      top: compact ? 12 : 16,
                      left: 16,
                      right: 16,
                      child: _WelcomeBrandStrip(compact: compact),
                    ),
                    Positioned(
                      left: compact ? 12 : 16,
                      right: compact ? 12 : 16,
                      bottom: compact ? 12 : 16,
                      child: _CarouselFooter(
                        currentIndex: _currentSlide,
                        itemCount: _slides.length,
                        accentColor: _slides[_currentSlide].accentColor,
                        foregroundColor: _slides[_currentSlide].foregroundColor,
                        disclaimer: _disclaimer,
                        onSignUp: _openSignUp,
                        onLogin: _openLogin,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _WelcomeSlideData {
  final String title;
  final String subtitle;
  final String illustrationAsset;
  final String semanticsLabel;
  final Color gradientStart;
  final Color gradientEnd;
  final Color foregroundColor;
  final Color accentColor;
  final List<_WelcomeFeature> features;

  const _WelcomeSlideData({
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.semanticsLabel,
    required this.gradientStart,
    required this.gradientEnd,
    required this.foregroundColor,
    required this.accentColor,
    required this.features,
  });
}

class _WelcomeFeature {
  final IconData icon;
  final String label;

  const _WelcomeFeature({required this.icon, required this.label});
}

// ---------------------------------------------------------------------------
// Brand strip — frosted glass
// ---------------------------------------------------------------------------

class _WelcomeBrandStrip extends StatelessWidget {
  final bool compact;

  const _WelcomeBrandStrip({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              10,
              compact ? 7 : 9,
              14,
              compact ? 7 : 9,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.58),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.50),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF17243A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: compact ? 150 : 250,
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: compact ? 30 : 34,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VitalySync',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            height: 1.05,
                            fontSize: compact ? 15 : 16.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2D3E),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Your daily wellness rhythm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7D90),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide — soft gradient background
// ---------------------------------------------------------------------------

class _WelcomeSlide extends StatelessWidget {
  final _WelcomeSlideData data;
  final bool compact;
  final double bottomContentInset;

  const _WelcomeSlide({
    required this.data,
    required this.compact,
    required this.bottomContentInset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [data.gradientStart, data.gradientEnd],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: _WellnessContourPainter(color: data.accentColor),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _BokehDotsPainter(color: data.accentColor),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final shortSlide = constraints.maxHeight < 430;
              final visualHeight =
                  shortSlide
                      ? 116.0
                      : compact
                          ? 148.0
                          : 195.0;
              final topContentInset = compact ? 68.0 : 82.0;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  22,
                  topContentInset,
                  22,
                  bottomContentInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        (constraints.maxHeight -
                                topContentInset -
                                bottomContentInset)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WelcomeVisual(data: data, height: visualHeight),
                      SizedBox(height: shortSlide ? 12 : 20),
                      Text(
                        data.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          height: 1.15,
                          fontSize:
                              shortSlide
                                  ? 20
                                  : compact
                                      ? 22
                                      : 26,
                          fontWeight: FontWeight.w800,
                          color: data.foregroundColor,
                        ),
                      ),
                      SizedBox(height: shortSlide ? 7 : 10),
                      Text(
                        data.subtitle,
                        maxLines: shortSlide ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          height: 1.45,
                          fontSize: shortSlide ? 12.5 : 13.8,
                          fontWeight: FontWeight.w500,
                          color: data.foregroundColor.withValues(alpha: 0.76),
                        ),
                      ),
                      SizedBox(height: shortSlide ? 10 : 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: data.features
                            .map(
                              (feature) => _FeatureChip(
                                feature: feature,
                                foregroundColor: data.foregroundColor,
                                accentColor: data.accentColor,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Illustration frame — frosted glass
// ---------------------------------------------------------------------------

class _WelcomeVisual extends StatelessWidget {
  final _WelcomeSlideData data;
  final double height;

  const _WelcomeVisual({required this.data, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height * 0.20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: height * 1.55,
              height: height,
              padding: EdgeInsets.all(height * 0.10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.80),
                    Colors.white.withValues(alpha: 0.50),
                  ],
                ),
                borderRadius: BorderRadius.circular(height * 0.20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.accentColor.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.60),
                    blurRadius: 1,
                    spreadRadius: 0,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SvgPicture.asset(
                data.illustrationAsset,
                fit: BoxFit.contain,
                semanticsLabel: data.semanticsLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature chips — glassmorphism pills
// ---------------------------------------------------------------------------

class _FeatureChip extends StatelessWidget {
  final _WelcomeFeature feature;
  final Color foregroundColor;
  final Color accentColor;

  const _FeatureChip({
    required this.feature,
    required this.foregroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.60),
                Colors.white.withValues(alpha: 0.30),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(feature.icon, size: 15, color: accentColor),
              const SizedBox(width: 6),
              Text(
                feature.label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background decoration — delicate contour lines
// ---------------------------------------------------------------------------

class _WellnessContourPainter extends CustomPainter {
  final Color color;

  const _WellnessContourPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final upperPath = Path()
      ..moveTo(-size.width * 0.10, size.height * 0.15)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.02,
        size.width * 0.30,
        size.height * 0.30,
        size.width * 0.54,
        size.height * 0.14,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.01,
        size.width * 0.85,
        size.height * 0.20,
        size.width * 1.10,
        size.height * 0.06,
      );
    canvas.drawPath(upperPath, paint);

    final middlePath = Path()
      ..moveTo(-size.width * 0.06, size.height * 0.55)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.44,
        size.width * 0.22,
        size.height * 0.72,
        size.width * 0.44,
        size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.52,
        size.width * 0.75,
        size.height * 0.78,
        size.width * 1.08,
        size.height * 0.63,
      );
    canvas.drawPath(middlePath, paint);

    final lowerPath = Path()
      ..moveTo(size.width * 0.08, size.height * 1.04)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.82,
        size.width * 0.48,
        size.height * 1.00,
        size.width * 0.60,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.68,
        size.width * 0.90,
        size.height * 0.94,
        size.width * 1.10,
        size.height * 0.80,
      );
    canvas.drawPath(lowerPath, paint);
  }

  @override
  bool shouldRepaint(covariant _WellnessContourPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// Background decoration — bokeh dots for depth
// ---------------------------------------------------------------------------

class _BokehDotsPainter extends CustomPainter {
  final Color color;

  const _BokehDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final softPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Soft filled circles
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.12),
      18,
      softPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.38),
      12,
      softPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.78),
      22,
      softPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.88),
      10,
      softPaint,
    );

    // Ring outlines
    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.22),
      size.width * 0.08,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.50),
      size.width * 0.12,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BokehDotsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// Footer — frosted glass container
// ---------------------------------------------------------------------------

class _CarouselFooter extends StatelessWidget {
  final int currentIndex;
  final int itemCount;
  final Color accentColor;
  final Color foregroundColor;
  final String disclaimer;
  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  const _CarouselFooter({
    required this.currentIndex,
    required this.itemCount,
    required this.accentColor,
    required this.foregroundColor,
    required this.disclaimer,
    required this.onSignUp,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.78),
                Colors.white.withValues(alpha: 0.62),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF17243A).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageIndicator(
                currentIndex: currentIndex,
                itemCount: itemCount,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              _CompactDisclaimer(text: disclaimer),
              const SizedBox(height: 10),
              _GradientPrimaryCta(
                key: const ValueKey('auth-welcome-sign-up'),
                label: 'Sign up',
                icon: Icons.person_add_alt_1_rounded,
                accentColor: accentColor,
                onPressed: onSignUp,
              ),
              const SizedBox(height: 8),
              AuthButton.secondary(
                key: const ValueKey('auth-welcome-login'),
                label: 'Log in',
                icon: Icons.login_rounded,
                onPressed: onLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page indicator — gradient active dot
// ---------------------------------------------------------------------------

class _PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int itemCount;
  final Color accentColor;

  const _PageIndicator({
    required this.currentIndex,
    required this.itemCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final selected = index == currentIndex;

        return AnimatedContainer(
          key: ValueKey('auth-welcome-dot-$index'),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: selected ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.60),
                    ],
                  )
                : null,
            color: selected ? null : const Color(0xFFCDD5DE),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient primary CTA button
// ---------------------------------------------------------------------------

class _GradientPrimaryCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onPressed;

  const _GradientPrimaryCta({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [primary, primary.withValues(alpha: 0.82)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.30),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 9),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disclaimer — frosted glass row
// ---------------------------------------------------------------------------

class _CompactDisclaimer extends StatelessWidget {
  final String text;

  const _CompactDisclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.60),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.70),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                height: 1.32,
                fontSize: 10.8,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7D90),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
