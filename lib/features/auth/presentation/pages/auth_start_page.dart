import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

import '../../../../shared/theme/app_page_style.dart';
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
      backgroundColor: Color(0xFFC77D9C),
      foregroundColor: Colors.white,
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
      backgroundColor: Color(0xFFF4A12B),
      foregroundColor: Color(0xFF3C2711),
      features: [
        _WelcomeFeature(icon: Icons.water_drop_rounded, label: 'Hydration'),
        _WelcomeFeature(icon: Icons.restaurant_rounded, label: 'Nutrition'),
        _WelcomeFeature(icon: Icons.directions_walk_rounded, label: 'Activity'),
      ],
    ),
    _WelcomeSlideData(
      title: 'Get nudges that fit your day',
      subtitle:
          'Adaptive reminders and the smart assistant help you notice when to rest, move, drink water, or reset.',
      illustrationAsset: 'assets/images/welcome_reminders.svg',
      semanticsLabel: 'Gentle wellness reminders illustration',
      backgroundColor: Color(0xFF4969E9),
      foregroundColor: Colors.white,
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
      backgroundColor: Color(0xFF43AE91),
      foregroundColor: Colors.white,
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
      if (!mounted || _currentSlide == _slides.length - 1) return;
      _goToSlide(_currentSlide + 1);
    });
  }

  void _goToSlide(int index) {
    final target = index.clamp(0, _slides.length - 1).toInt();
    if (target == _currentSlide) return;

    if (MediaQuery.disableAnimationsOf(context)) {
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 710;
          final panelHeight =
              (constraints.maxHeight - (compact ? 260.0 : 198.0))
                  .clamp(300.0, compact ? 410.0 : 560.0)
                  .toDouble();

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: panelHeight,
                    child: LayoutBuilder(
                      builder: (context, panelConstraints) {
                        final panelWidth = panelConstraints.maxWidth > 440
                            ? 440.0
                            : panelConstraints.maxWidth;

                        return Center(
                          child: SizedBox(
                            width: panelWidth,
                            height: panelConstraints.maxHeight,
                            child: AuthGlassPanel(
                              padding: EdgeInsets.zero,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  LiquidSwipe.builder(
                                    key: const ValueKey(
                                      'auth-welcome-carousel',
                                    ),
                                    itemCount: _slides.length,
                                    itemBuilder: (context, index) =>
                                        _WelcomeSlide(
                                          data: _slides[index],
                                          compact: compact,
                                        ),
                                    liquidController: _liquidController,
                                    initialPage: _currentSlide,
                                    onPageChangeCallback: _handlePageChanged,
                                    waveType: WaveType.liquidReveal,
                                    fullTransitionValue: 420,
                                    enableLoop: false,
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
                                    left: 14,
                                    right: 14,
                                    bottom: compact ? 10 : 14,
                                    child: _CarouselControls(
                                      currentIndex: _currentSlide,
                                      itemCount: _slides.length,
                                      foregroundColor: _slides[_currentSlide]
                                          .foregroundColor,
                                      onPrevious: _currentSlide == 0
                                          ? null
                                          : () => _goToSlide(_currentSlide - 1),
                                      onNext:
                                          _currentSlide == _slides.length - 1
                                          ? null
                                          : () => _goToSlide(_currentSlide + 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _CompactDisclaimer(text: _disclaimer),
                          const SizedBox(height: 12),
                          AuthButton.primary(
                            label: 'Sign up',
                            icon: Icons.person_add_alt_1_rounded,
                            onPressed: _openSignUp,
                          ),
                          const SizedBox(height: 10),
                          AuthButton.secondary(
                            label: 'Log in',
                            icon: Icons.login_rounded,
                            onPressed: _openLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeSlideData {
  final String title;
  final String subtitle;
  final String illustrationAsset;
  final String semanticsLabel;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<_WelcomeFeature> features;

  const _WelcomeSlideData({
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.semanticsLabel,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.features,
  });
}

class _WelcomeFeature {
  final IconData icon;
  final String label;

  const _WelcomeFeature({required this.icon, required this.label});
}

class _WelcomeBrandStrip extends StatelessWidget {
  final bool compact;

  const _WelcomeBrandStrip({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17243A).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            compact ? 7 : 8,
            14,
            compact ? 7 : 8,
          ),
          child: SizedBox(
            width: compact ? 150 : 250,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: compact ? 31 : 35,
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
                          fontSize: compact ? 15.5 : 17,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF17243A),
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
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF526176),
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
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  final _WelcomeSlideData data;
  final bool compact;

  const _WelcomeSlide({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: data.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: _WellnessContourPainter(color: data.foregroundColor),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final shortSlide = constraints.maxHeight < 430;
              final visualHeight = shortSlide
                  ? 108.0
                  : compact
                  ? 136.0
                  : 180.0;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  compact ? 66 : 80,
                  20,
                  compact ? 56 : 70,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (compact ? 122 : 150),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WelcomeVisual(data: data, height: visualHeight),
                      SizedBox(height: shortSlide ? 10 : 16),
                      Text(
                        data.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          height: 1.12,
                          fontSize: shortSlide
                              ? 20
                              : compact
                              ? 22
                              : 25,
                          fontWeight: FontWeight.w900,
                          color: data.foregroundColor,
                        ),
                      ),
                      SizedBox(height: shortSlide ? 6 : 8),
                      Text(
                        data.subtitle,
                        maxLines: shortSlide ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          height: 1.38,
                          fontSize: shortSlide ? 12.2 : 13.5,
                          fontWeight: FontWeight.w600,
                          color: data.foregroundColor.withValues(alpha: 0.88),
                        ),
                      ),
                      SizedBox(height: shortSlide ? 9 : 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 7,
                        runSpacing: 7,
                        children: data.features
                            .map(
                              (feature) => _FeatureChip(
                                feature: feature,
                                foregroundColor: data.foregroundColor,
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
        child: Container(
          width: height * 1.48,
          height: height,
          padding: EdgeInsets.all(height * 0.10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(height * 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF17243A).withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
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
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final _WelcomeFeature feature;
  final Color foregroundColor;

  const _FeatureChip({required this.feature, required this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, size: 15, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            feature.label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessContourPainter extends CustomPainter {
  final Color color;

  const _WellnessContourPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final upperPath = Path()
      ..moveTo(-size.width * 0.08, size.height * 0.18)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.04,
        size.width * 0.28,
        size.height * 0.34,
        size.width * 0.52,
        size.height * 0.17,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.04,
        size.width * 0.83,
        size.height * 0.18,
        size.width * 1.08,
        size.height * 0.08,
      );
    canvas.drawPath(upperPath, paint);

    final middlePath = Path()
      ..moveTo(-size.width * 0.05, size.height * 0.58)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.48,
        size.width * 0.19,
        size.height * 0.76,
        size.width * 0.42,
        size.height * 0.65,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.54,
        size.width * 0.73,
        size.height * 0.82,
        size.width * 1.06,
        size.height * 0.66,
      );
    canvas.drawPath(middlePath, paint);

    final lowerPath = Path()
      ..moveTo(size.width * 0.12, size.height * 1.05)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.79,
        size.width * 0.51,
        size.height * 1.02,
        size.width * 0.61,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.73,
        size.height * 0.65,
        size.width * 0.88,
        size.height * 0.92,
        size.width * 1.08,
        size.height * 0.82,
      );
    canvas.drawPath(lowerPath, paint);
  }

  @override
  bool shouldRepaint(covariant _WellnessContourPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CarouselControls extends StatelessWidget {
  final int currentIndex;
  final int itemCount;
  final Color foregroundColor;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _CarouselControls({
    required this.currentIndex,
    required this.itemCount,
    required this.foregroundColor,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Previous',
          child: IconButton(
            key: const ValueKey('auth-welcome-previous'),
            onPressed: onPrevious,
            style: IconButton.styleFrom(
              backgroundColor: foregroundColor.withValues(alpha: 0.14),
              foregroundColor: foregroundColor,
              disabledForegroundColor: foregroundColor.withValues(alpha: 0.34),
              side: BorderSide(color: foregroundColor.withValues(alpha: 0.24)),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(itemCount, (index) {
              final selected = index == currentIndex;

              return AnimatedContainer(
                key: ValueKey('auth-welcome-dot-$index'),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? foregroundColor
                      : foregroundColor.withValues(alpha: 0.36),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ),
        Tooltip(
          message: 'Next',
          child: IconButton(
            key: const ValueKey('auth-welcome-next'),
            onPressed: onNext,
            style: IconButton.styleFrom(
              backgroundColor: foregroundColor.withValues(alpha: 0.14),
              foregroundColor: foregroundColor,
              disabledForegroundColor: foregroundColor.withValues(alpha: 0.34),
              side: BorderSide(color: foregroundColor.withValues(alpha: 0.24)),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ],
    );
  }
}

class _CompactDisclaimer extends StatelessWidget {
  final String text;

  const _CompactDisclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_rounded,
            size: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                height: 1.32,
                fontSize: 11.5,
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
