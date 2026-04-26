import 'dart:async';

import 'package:flutter/material.dart';

class RevealOnBuild extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;
  final bool enabled;

  const RevealOnBuild({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.beginOffset = const Offset(0, 0.05),
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  @override
  State<RevealOnBuild> createState() => _RevealOnBuildState();
}

class _RevealOnBuildState extends State<RevealOnBuild>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curvedAnimation);

    if (widget.enabled) {
      _startAnimation();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant RevealOnBuild oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled && _controller.value == 0) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _delayTimer?.cancel();

    if (widget.delay > Duration.zero) {
      _delayTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
      });
      return;
    }

    if (!mounted) return;
    _controller.forward();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
