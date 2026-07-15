import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/animated_gradient_background.dart';
import '../../../../shared/theme/app_page_style.dart';

const authHealthyLifestyleAsset = 'assets/images/auth_healthy_lifestyle.svg';
const authMeditationAsset = 'assets/images/auth_meditation.svg';
const authWorkoutAsset = 'assets/images/auth_workout.svg';
const authWorkStressAsset = 'assets/images/auth_work_stress.svg';
const authDashboardAsset = 'assets/images/auth_dashboard.svg';

enum AuthBackdropStyle { welcome, login, signUp }

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final String illustrationAsset;
  final String? topOverlayAsset;
  final List<String>? bottomOverlayAssets;
  final AuthBackdropStyle backdropStyle;
  final EdgeInsetsGeometry padding;
  final bool centerContent;
  final bool scrollable;

  const AuthScaffold({
    super.key,
    required this.child,
    required this.illustrationAsset,
    this.topOverlayAsset,
    this.bottomOverlayAssets,
    this.backdropStyle = AuthBackdropStyle.welcome,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    this.centerContent = true,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedGradientBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AuthBackdropWash(style: backdropStyle),
            _BackgroundHealthMotif(
              illustrationAsset: illustrationAsset,
              topOverlayAsset: topOverlayAsset,
              bottomOverlayAssets: bottomOverlayAssets,
              style: backdropStyle,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!scrollable) {
                    return Padding(
                      padding: padding,
                      child: centerContent ? Center(child: child) : child,
                    );
                  }

                  final scrollChild = ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: centerContent
                        ? Center(child: child)
                        : Align(alignment: Alignment.topCenter, child: child),
                  );

                  return SingleChildScrollView(
                    padding: padding,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: scrollChild,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackdropWash extends StatelessWidget {
  final AuthBackdropStyle style;

  const _AuthBackdropWash({required this.style});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = switch (style) {
      AuthBackdropStyle.welcome => const Color(0xFFC789B5),
      AuthBackdropStyle.login => const Color(0xFF67A7E8),
      AuthBackdropStyle.signUp => const Color(0xFFF0A35C),
    };
    final lightEnd = switch (style) {
      AuthBackdropStyle.welcome => const Color(0xFFF8F2FC),
      AuthBackdropStyle.login => const Color(0xFFF0F5FF),
      AuthBackdropStyle.signUp => const Color(0xFFFFF7EF),
    };

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF071421).withValues(alpha: 0.78),
                        const Color(0xFF10263A).withValues(alpha: 0.70),
                        const Color(0xFF111B31).withValues(alpha: 0.76),
                      ]
                    : [
                        const Color(0xFFF9FFFD).withValues(alpha: 0.78),
                        const Color(0xFFEAF8F3).withValues(alpha: 0.72),
                        lightEnd.withValues(alpha: 0.76),
                      ],
              ),
            ),
          ),
          Positioned(
            top: -110,
            right: -90,
            child: _AmbientBlob(
              size: 280,
              color: accent.withValues(alpha: isDark ? 0.16 : 0.22),
            ),
          ),
          Positioned(
            left: -120,
            bottom: -80,
            child: _AmbientBlob(
              size: 300,
              color: primary.withValues(alpha: isDark ? 0.13 : 0.18),
            ),
          ),
          CustomPaint(
            painter: _AuthFlowPainter(
              color: isDark ? Colors.white : const Color(0xFF315A66),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFlowPainter extends CustomPainter {
  final Color color;

  const _AuthFlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final topPath = Path()
      ..moveTo(-size.width * 0.12, size.height * 0.20)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.04,
        size.width * 0.28,
        size.height * 0.34,
        size.width * 0.55,
        size.height * 0.16,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.02,
        size.width * 0.86,
        size.height * 0.22,
        size.width * 1.12,
        size.height * 0.08,
      );
    canvas.drawPath(topPath, linePaint);

    final lowerPath = Path()
      ..moveTo(-size.width * 0.10, size.height * 0.76)
      ..cubicTo(
        size.width * 0.17,
        size.height * 0.61,
        size.width * 0.33,
        size.height * 0.91,
        size.width * 0.58,
        size.height * 0.74,
      )
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.60,
        size.width * 0.89,
        size.height * 0.88,
        size.width * 1.12,
        size.height * 0.72,
      );
    canvas.drawPath(lowerPath, linePaint);

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.48),
      size.width * 0.14,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.45),
      size.width * 0.20,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthFlowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _AmbientBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _BackgroundHealthMotif extends StatefulWidget {
  final String illustrationAsset;
  final String? topOverlayAsset;
  final List<String>? bottomOverlayAssets;
  final AuthBackdropStyle style;

  const _BackgroundHealthMotif({
    required this.illustrationAsset,
    required this.topOverlayAsset,
    required this.bottomOverlayAssets,
    required this.style,
  });

  @override
  State<_BackgroundHealthMotif> createState() => _BackgroundHealthMotifState();
}

class _BackgroundHealthMotifState extends State<_BackgroundHealthMotif>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: reduceMotion ? kAlwaysCompleteAnimation : _animation,
        builder: (context, _) {
          final value = reduceMotion ? 0.5 : _animation.value;
          final lift = lerpDouble(-8, 8, value)!;

          return switch (widget.style) {
            AuthBackdropStyle.welcome => _buildWelcomeComposition(lift),
            AuthBackdropStyle.login => _buildLoginComposition(lift),
            AuthBackdropStyle.signUp => _buildSignUpComposition(lift),
          };
        },
      ),
    );
  }

  Widget _buildWelcomeComposition(double lift) {
    final assets = widget.bottomOverlayAssets ?? const <String>[];
    final lowerAsset = assets.isEmpty ? widget.illustrationAsset : assets.first;
    final secondAsset = assets.length > 1 ? assets[1] : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 22 + (lift * 0.30),
          right: -48,
          child: _BackdropSvgAccent(
            asset: widget.topOverlayAsset ?? widget.illustrationAsset,
            width: 190,
            opacity: 0.42,
            angle: 0.05,
          ),
        ),
        Positioned(
          left: -72,
          bottom: 8 + (lift * 0.45),
          child: _BackdropSvgAccent(
            asset: lowerAsset,
            width: 250,
            opacity: 0.36,
            angle: -0.045,
          ),
        ),
        if (secondAsset != null)
          Positioned(
            right: -62,
            bottom: 42 - (lift * 0.24),
            child: _BackdropSvgAccent(
              asset: secondAsset,
              width: 180,
              opacity: 0.28,
              angle: 0.06,
            ),
          ),
        Positioned(
          top: 118 - (lift * 0.25),
          left: 18,
          child: const _FloatingHealthIcon(
            icon: Icons.favorite_rounded,
            color: Color(0xFFEC6A8D),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginComposition(double lift) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 42 + (lift * 0.42),
          right: -72,
          child: _BackdropSvgAccent(
            asset: widget.illustrationAsset,
            width: 250,
            opacity: 0.52,
            angle: 0.045,
          ),
        ),
        if (widget.topOverlayAsset != null)
          Positioned(
            left: -58,
            bottom: 20 - (lift * 0.36),
            child: _BackdropSvgAccent(
              asset: widget.topOverlayAsset!,
              width: 188,
              opacity: 0.34,
              angle: -0.055,
            ),
          ),
        Positioned(
          left: 24,
          top: 98 - (lift * 0.25),
          child: const _FloatingHealthIcon(
            icon: Icons.nights_stay_rounded,
            color: Color(0xFF5B7FE8),
          ),
        ),
        Positioned(
          right: 22,
          bottom: 72 + (lift * 0.22),
          child: _FloatingHealthIcon(
            icon: Icons.spa_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpComposition(double lift) {
    final assets = widget.bottomOverlayAssets ?? const <String>[];
    final lowerAsset =
        widget.topOverlayAsset ??
        (assets.isEmpty ? widget.illustrationAsset : assets.first);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 26 + (lift * 0.36),
          right: -70,
          child: _BackdropSvgAccent(
            asset: widget.illustrationAsset,
            width: 238,
            opacity: 0.48,
            angle: 0.05,
          ),
        ),
        Positioned(
          left: -70,
          bottom: 28 - (lift * 0.32),
          child: _BackdropSvgAccent(
            asset: lowerAsset,
            width: 205,
            opacity: 0.32,
            angle: -0.06,
          ),
        ),
        Positioned(
          left: 22,
          top: 116 - (lift * 0.24),
          child: const _FloatingHealthIcon(
            icon: Icons.favorite_rounded,
            color: Color(0xFFEC6A8D),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 92 + (lift * 0.20),
          child: _FloatingHealthIcon(
            icon: Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _BackdropSvgAccent extends StatelessWidget {
  final String asset;
  final double width;
  final double opacity;
  final double angle;

  const _BackdropSvgAccent({
    required this.asset,
    required this.width,
    required this.opacity,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: isDark ? opacity * 0.72 : opacity,
        child: Container(
          width: width,
          height: width * 0.76,
          padding: EdgeInsets.all(width * 0.08),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.12),
                      primary.withValues(alpha: 0.08),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.82),
                      Colors.white.withValues(alpha: 0.36),
                    ],
            ),
            borderRadius: BorderRadius.circular(width * 0.20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.58),
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.14),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _FloatingHealthIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingHealthIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: isDark ? 0.09 : 0.66),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.60),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class AuthGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A2B42).withValues(alpha: 0.88),
                      const Color(0xFF101D30).withValues(alpha: 0.78),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.92),
                      const Color(0xFFF7FCFA).withValues(alpha: 0.76),
                    ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.13)
                  : Colors.white.withValues(alpha: 0.78),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.30)
                    : const Color(0xFF2B7D6B).withValues(alpha: 0.14),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.28),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double logoSize;

  const AuthBrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logoSize = 76,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: logoSize),
        const SizedBox(height: 8),
        Text(
          'VitalySync',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: pagePrimaryTextColor(context),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            height: 1.16,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: pagePrimaryTextColor(context),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              height: 1.45,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: pageSecondaryTextColor(context),
            ),
          ),
        ],
      ],
    );
  }
}

class AuthHeroIllustration extends StatefulWidget {
  final String asset;
  final String semanticsLabel;
  final double height;

  const AuthHeroIllustration({
    super.key,
    required this.asset,
    required this.semanticsLabel,
    this.height = 190,
  });

  @override
  State<AuthHeroIllustration> createState() => _AuthHeroIllustrationState();
}

class _AuthHeroIllustrationState extends State<AuthHeroIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: reduceMotion ? kAlwaysCompleteAnimation : _animation,
      builder: (context, child) {
        final dy = reduceMotion ? 0.0 : lerpDouble(-5, 5, _animation.value)!;

        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: SizedBox(
        height: widget.height,
        child: SvgPicture.asset(
          widget.asset,
          fit: BoxFit.contain,
          semanticsLabel: widget.semanticsLabel,
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool primary;

  const AuthButton.primary({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  }) : primary = true;

  const AuthButton.secondary({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  }) : primary = false;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: primary
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final style = primary
        ? ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.46),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.78),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: pagePrimaryTextColor(context),
            side: BorderSide(color: pageBorderColor(context)),
            backgroundColor: Colors.white.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.04
                  : 0.30,
            ),
          );

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: primary
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: style.copyWith(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                elevation: WidgetStateProperty.all(0),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: style.copyWith(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: child,
            ),
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffixIcon,
  String? hintText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: Icon(icon, color: primary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.76),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: TextStyle(color: pageSecondaryTextColor(context)),
    hintStyle: TextStyle(color: pageSecondaryTextColor(context)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: pageBorderColor(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: pageBorderColor(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5484D)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.4),
    ),
  );
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(color: pagePrimaryTextColor(context)),
      decoration: authInputDecoration(
        context,
        label: label,
        icon: icon,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AuthFinePrint extends StatelessWidget {
  final String text;
  final IconData icon;

  const AuthFinePrint({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF4FBF8).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                height: 1.42,
                fontSize: 12.5,
                color: pageSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
