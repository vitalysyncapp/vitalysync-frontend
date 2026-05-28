import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/animated_gradient_background.dart';
import '../../../../shared/theme/app_page_style.dart';

const authHealthyLifestyleAsset = 'assets/images/auth_healthy_lifestyle.svg';
const authWorkoutAsset = 'assets/images/auth_workout.svg';
const authWorkStressAsset = 'assets/images/auth_work_stress.svg';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final String illustrationAsset;
  final List<String>? bottomOverlayAssets;
  final EdgeInsetsGeometry padding;
  final bool centerContent;

  const AuthScaffold({
    super.key,
    required this.child,
    required this.illustrationAsset,
    this.bottomOverlayAssets,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedGradientBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BackgroundHealthMotif(
              illustrationAsset: illustrationAsset,
              bottomOverlayAssets: bottomOverlayAssets,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
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

class _BackgroundHealthMotif extends StatefulWidget {
  final String illustrationAsset;
  final List<String>? bottomOverlayAssets;

  const _BackgroundHealthMotif({
    required this.illustrationAsset,
    required this.bottomOverlayAssets,
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
      duration: const Duration(seconds: 7),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bottomAssets = widget.bottomOverlayAssets;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: reduceMotion ? kAlwaysCompleteAnimation : _animation,
        builder: (context, _) {
          final value = reduceMotion ? 1.0 : _animation.value;
          final lift = lerpDouble(-10, 10, value)!;

          if (bottomAssets != null && bottomAssets.isNotEmpty) {
            return _BottomSvgOverlay(
              assets: bottomAssets,
              lift: lift,
              opacity: isDark ? 0.20 : 0.34,
              primaryColor: primary,
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -32,
                top: 52 + lift,
                child: Opacity(
                  opacity: isDark ? 0.15 : 0.26,
                  child: SvgPicture.asset(
                    widget.illustrationAsset,
                    width: 260,
                    semanticsLabel: 'Wellness illustration',
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 112 - (lift * 0.35),
                child: _FloatingHealthIcon(
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFFF6B8A),
                  background: Colors.white.withValues(
                    alpha: isDark ? 0.10 : 0.42,
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: 126 + (lift * 0.4),
                child: _FloatingHealthIcon(
                  icon: Icons.spa_rounded,
                  color: primary,
                  background: Colors.white.withValues(
                    alpha: isDark ? 0.10 : 0.46,
                  ),
                ),
              ),
              Positioned(
                left: 30,
                bottom: 58 - (lift * 0.5),
                child: _FloatingHealthIcon(
                  icon: Icons.nights_stay_rounded,
                  color: const Color(0xFF5B8DEF),
                  background: Colors.white.withValues(
                    alpha: isDark ? 0.10 : 0.42,
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

class _BottomSvgOverlay extends StatelessWidget {
  final List<String> assets;
  final double lift;
  final double opacity;
  final Color primaryColor;

  const _BottomSvgOverlay({
    required this.assets,
    required this.lift,
    required this.opacity,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final primaryAsset = assets.first;
    final secondaryAsset = assets.length > 1 ? assets[1] : assets.first;
    final primaryWidth = screenWidth < 380 ? 255.0 : 330.0;
    final secondaryWidth = screenWidth < 380 ? 205.0 : 265.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: -68,
          bottom: -34 + (lift * 0.35),
          child: Opacity(
            opacity: opacity,
            child: SvgPicture.asset(
              primaryAsset,
              width: primaryWidth,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
        Positioned(
          right: -54,
          bottom: 6 - (lift * 0.28),
          child: Opacity(
            opacity: opacity * 0.86,
            child: SvgPicture.asset(
              secondaryAsset,
              width: secondaryWidth,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
        Positioned(
          left: 28,
          bottom: 188 - (lift * 0.4),
          child: _FloatingHealthIcon(
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFF6B8A),
            background: Colors.white.withValues(alpha: 0.26),
          ),
        ),
        Positioned(
          right: 34,
          bottom: 212 + (lift * 0.32),
          child: _FloatingHealthIcon(
            icon: Icons.spa_rounded,
            color: primaryColor,
            background: Colors.white.withValues(alpha: 0.30),
          ),
        ),
      ],
    );
  }
}

class _FloatingHealthIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _FloatingHealthIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
      ),
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
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF142237).withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.68),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.24)
                    : const Color(0xFF58BFA6).withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 16),
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
            style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
