import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = isDark
        ? const [
            Color(0xFF07111F),
            Color(0xFF10213A),
            Color(0xFF1A2F4D),
            Color(0xFF0A1630),
          ]
        : const [
            Color(0xFF52F9FF),
            Color(0xFFD9B5FF),
            Color(0xFF7FD6FF),
            Color(0xFFFFC7E4),
          ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final shift = (_animation.value * 2) - 1;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment(-1.0 + (shift * 0.35), -1.0),
              end: Alignment(1.0, 1.0 - (shift * 0.35)),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -120 + (shift * 40),
                left: -80 + (shift * 30),
                child: _GlowOrb(
                  size: 260,
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.22),
                ),
              ),
              Positioned(
                right: -100 - (shift * 35),
                bottom: -120 + (shift * 45),
                child: _GlowOrb(
                  size: 300,
                  color: colors[1].withValues(alpha: isDark ? 0.18 : 0.28),
                ),
              ),
              Positioned(
                top: 140 - (shift * 28),
                right: -60 + (shift * 24),
                child: _GlowOrb(
                  size: 180,
                  color: colors[2].withValues(alpha: isDark ? 0.14 : 0.22),
                ),
              ),
              if (widget.padding != null)
                Padding(padding: widget.padding!, child: widget.child)
              else
                widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
