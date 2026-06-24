import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

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
  static const _autoSlideInterval = Duration(seconds: 6);

  static const _slides = <_WelcomeSlideData>[
    _WelcomeSlideData(
      title: 'Feel your rhythm before burnout gets loud',
      subtitle:
          'Check in with sleep, mood, stress, workload, energy, and recovery so your day has a clearer signal.',
      illustrationAsset: authHealthyLifestyleAsset,
      animationAsset: 'assets/animations/auth_stress_management.json',
      semanticsLabel: 'Stress awareness animation',
      fallbackIcon: Icons.favorite_rounded,
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
      illustrationAsset: authWorkoutAsset,
      animationAsset: 'assets/animations/auth_hydration.json',
      semanticsLabel: 'Hydration and wellness animation',
      fallbackIcon: Icons.water_drop_rounded,
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
      illustrationAsset: authMeditationAsset,
      animationAsset: 'assets/animations/auth_breathing.json',
      semanticsLabel: 'Breathing reminder animation',
      fallbackIcon: Icons.self_improvement_rounded,
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
      illustrationAsset: authDashboardAsset,
      animationAsset: 'assets/animations/auth_dashboard.json',
      semanticsLabel: 'Wellness dashboard animation',
      fallbackIcon: Icons.insights_rounded,
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

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlideTimer();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlideTimer() {
    if (_slides.length <= 1) return;

    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;

      final nextSlide = (_currentSlide + 1) % _slides.length;
      _goToSlide(nextSlide);
    });
  }

  void _goToSlide(int index) {
    final target = index.clamp(0, _slides.length - 1).toInt();

    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
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
                              padding: EdgeInsets.fromLTRB(
                                18,
                                compact ? 16 : 20,
                                18,
                                compact ? 14 : 18,
                              ),
                              child: Column(
                                children: [
                                  _WelcomeBrandStrip(compact: compact),
                                  SizedBox(height: compact ? 10 : 14),
                                  Expanded(
                                    child: PageView.builder(
                                      key: const ValueKey(
                                        'auth-welcome-carousel',
                                      ),
                                      controller: _pageController,
                                      itemCount: _slides.length,
                                      onPageChanged: (index) {
                                        setState(() => _currentSlide = index);
                                      },
                                      itemBuilder: (context, index) {
                                        return _WelcomeSlide(
                                          data: _slides[index],
                                          compact: compact,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: compact ? 8 : 12),
                                  _CarouselControls(
                                    currentIndex: _currentSlide,
                                    itemCount: _slides.length,
                                    onPrevious: _currentSlide == 0
                                        ? null
                                        : () => _goToSlide(_currentSlide - 1),
                                    onNext: _currentSlide == _slides.length - 1
                                        ? null
                                        : () => _goToSlide(_currentSlide + 1),
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
  final String animationAsset;
  final String semanticsLabel;
  final IconData fallbackIcon;
  final List<_WelcomeFeature> features;

  const _WelcomeSlideData({
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.animationAsset,
    required this.semanticsLabel,
    required this.fallbackIcon,
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
    return Row(
      children: [
        SizedBox.square(
          dimension: compact ? 42 : 48,
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VitalySync',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 19 : 21,
                  fontWeight: FontWeight.w900,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Burnout awareness for everyday rhythms',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  height: 1.2,
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: pageSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  final _WelcomeSlideData data;
  final bool compact;

  const _WelcomeSlide({required this.data, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortSlide = constraints.maxHeight < 380;
        final visualHeight = shortSlide
            ? 120.0
            : compact
            ? 142.0
            : 166.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WelcomeVisual(data: data, height: visualHeight),
                SizedBox(height: shortSlide ? 10 : 16),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    height: 1.13,
                    fontSize: shortSlide
                        ? 21
                        : compact
                        ? 23
                        : 25,
                    fontWeight: FontWeight.w900,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    height: 1.42,
                    fontSize: shortSlide ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
                SizedBox(height: shortSlide ? 12 : 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: data.features
                      .map((feature) => _FeatureChip(feature: feature))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeVisual extends StatelessWidget {
  final _WelcomeSlideData data;
  final double height;

  const _WelcomeVisual({required this.data, required this.height});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.34
                  : 0.48,
              child: SvgPicture.asset(
                data.illustrationAsset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Container(
            width: height * 0.74,
            height: height * 0.74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.white.withValues(alpha: 0.74),
              border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.18
                        : 0.20,
                  ),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Semantics(
              label: data.semanticsLabel,
              image: true,
              child: Lottie.asset(
                data.animationAsset,
                fit: BoxFit.contain,
                repeat: !reduceMotion,
                animate: !reduceMotion,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    data.fallbackIcon,
                    color: Theme.of(context).colorScheme.primary,
                    size: height * 0.34,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final _WelcomeFeature feature;

  const _FeatureChip({required this.feature});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF4FBF8).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, size: 16, color: primary),
          const SizedBox(width: 6),
          Text(
            feature.label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselControls extends StatelessWidget {
  final int currentIndex;
  final int itemCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _CarouselControls({
    required this.currentIndex,
    required this.itemCount,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Previous',
          child: IconButton.filledTonal(
            key: const ValueKey('auth-welcome-previous'),
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(itemCount, (index) {
              final selected = index == currentIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : pageBorderColor(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ),
        Tooltip(
          message: 'Next',
          child: IconButton.filledTonal(
            key: const ValueKey('auth-welcome-next'),
            onPressed: onNext,
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
              style: GoogleFonts.inter(
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
