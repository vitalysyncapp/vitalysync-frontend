import 'package:flutter/material.dart';

typedef AnalyticsChartBuilder =
    Widget Function(BuildContext context, double progress);

/// Smoothly exchanges an analytics skeleton for its loaded content.
class AnalyticsContentSwitcher extends StatelessWidget {
  final bool isLoading;
  final Widget loading;
  final Widget child;
  final Object? contentKey;
  final Duration duration;

  const AnalyticsContentSwitcher({
    super.key,
    required this.isLoading,
    required this.loading,
    required this.child,
    this.contentKey,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : duration,
      reverseDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.985, end: 1).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: Alignment.topCenter,
            scale: scale,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object?>(
          isLoading ? const _AnalyticsLoadingKey() : contentKey ?? false,
        ),
        child: isLoading ? loading : child,
      ),
    );
  }
}

class _AnalyticsLoadingKey {
  const _AnalyticsLoadingKey();
}

/// Supplies a 0-1 value for chart drawing and adds a subtle content lift.
class AnalyticsChartReveal extends StatelessWidget {
  final AnalyticsChartBuilder builder;
  final Duration duration;
  final Curve curve;

  const AnalyticsChartReveal({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 760),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return builder(context, 1);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, progress, _) {
        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - progress)),
            child: builder(context, progress),
          ),
        );
      },
    );
  }
}

/// Animates a horizontal analytics value from empty to its target.
class AnimatedAnalyticsProgress extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color backgroundColor;
  final Color color;
  final Duration duration;
  final Curve curve;

  const AnimatedAnalyticsProgress({
    super.key,
    required this.value,
    required this.backgroundColor,
    required this.color,
    this.minHeight = 8,
    this.duration = const Duration(milliseconds: 680),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    if (MediaQuery.of(context).disableAnimations) {
      return _indicator(target);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: duration,
      curve: curve,
      builder: (context, progress, _) => _indicator(progress),
    );
  }

  Widget _indicator(double progress) {
    return LinearProgressIndicator(
      value: progress,
      minHeight: minHeight,
      backgroundColor: backgroundColor,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    );
  }
}
