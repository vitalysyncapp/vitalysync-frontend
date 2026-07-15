import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_page_style.dart';

class AppSkeleton extends StatelessWidget {
  final bool enabled;
  final Widget child;
  final bool ignorePointers;
  final bool ignoreContainers;
  final bool excludeSemantics;
  final Duration shimmerDuration;

  const AppSkeleton({
    super.key,
    required this.enabled,
    required this.child,
    this.ignorePointers = true,
    this.ignoreContainers = false,
    this.excludeSemantics = true,
    this.shimmerDuration = const Duration(milliseconds: 850),
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final baseColor = isDark
        ? const Color(0xFF16283C)
        : const Color(0xFFD9ECE6);
    final softTint = isDark ? const Color(0xFF24516C) : const Color(0xFFE7F8F3);
    final highlightColor = isDark
        ? const Color(0xFF4A6F8F)
        : const Color(0xFFFFFFFF);
    final accentSweep = isDark
        ? const Color(0xFF2B806E)
        : const Color(0xFFBFF3E5);

    final skeleton = Skeletonizer(
      enabled: true,
      ignorePointers: ignorePointers,
      ignoreContainers: ignoreContainers,
      enableSwitchAnimation: true,
      containersColor: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : const Color(0xFFE8F4F0).withValues(alpha: 0.88),
      effect: reduceMotion
          ? SolidColorEffect(color: baseColor)
          : ShimmerEffect.raw(
              colors: [
                baseColor,
                softTint,
                highlightColor,
                accentSweep,
                baseColor,
              ],
              stops: const [0.0, 0.24, 0.42, 0.55, 1.0],
              begin: const AlignmentDirectional(-1.8, -0.55),
              end: const AlignmentDirectional(1.8, 0.55),
              duration: shimmerDuration,
            ),
      child: child,
    );

    return excludeSemantics ? ExcludeSemantics(child: skeleton) : skeleton;
  }
}

class AppSkeletonLine extends StatelessWidget {
  final double? width;
  final double widthFactor;
  final double height;
  final double radius;

  const AppSkeletonLine({
    super.key,
    this.width,
    this.widthFactor = 1,
    this.height = 14,
    this.radius = 999,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      ignorePointers: false,
      child: _SkeletonBox(
        width: width,
        widthFactor: width == null ? widthFactor : 1,
        height: height,
        radius: radius,
      ),
    );
  }
}

class AppSkeletonRows extends StatelessWidget {
  final int count;
  final double spacing;
  final double lineHeight;
  final bool showLeading;

  const AppSkeletonRows({
    super.key,
    this.count = 3,
    this.spacing = 12,
    this.lineHeight = 13,
    this.showLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      ignorePointers: false,
      child: Column(
        children: List.generate(count, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : spacing),
            child: Row(
              children: [
                if (showLeading) ...[
                  const _SkeletonBox(width: 34, height: 34, radius: 12),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(
                        height: lineHeight,
                        widthFactor: index.isEven ? 0.82 : 0.66,
                      ),
                      const SizedBox(height: 7),
                      _SkeletonBox(
                        height: lineHeight - 2,
                        widthFactor: index.isEven ? 0.58 : 0.76,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class AppSkeletonChart extends StatelessWidget {
  final double height;
  final int barCount;

  const AppSkeletonChart({super.key, this.height = 180, this.barCount = 7});

  @override
  Widget build(BuildContext context) {
    const heights = [0.48, 0.72, 0.56, 0.84, 0.64, 0.76, 0.52];

    return AppSkeleton(
      enabled: true,
      ignorePointers: false,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(barCount, (index) {
            final factor = heights[index % heights.length];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _SkeletonBox(height: height * factor, radius: 10),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  final double? height;
  final int lineCount;
  final bool showLeading;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AppSkeletonCard({
    super.key,
    this.height,
    this.lineCount = 3,
    this.showLeading = true,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      ignorePointers: false,
      child: Container(
        width: double.infinity,
        constraints: height == null ? null : BoxConstraints(minHeight: height!),
        padding: padding,
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: pageBorderColor(context)),
          boxShadow: pageCardShadow(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showLeading) ...[
                  const _SkeletonBox(width: 42, height: 42, radius: 14),
                  const SizedBox(width: 12),
                ],
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(height: 16, widthFactor: 0.74),
                      SizedBox(height: 8),
                      _SkeletonBox(height: 12, widthFactor: 0.48),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSkeletonRows(count: lineCount, spacing: 10, lineHeight: 12),
          ],
        ),
      ),
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final List<double> cardHeights;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AppSkeletonList({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.cardHeights = const [124, 92, 92, 92],
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemCount: cardHeights.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return AppSkeletonCard(
          height: cardHeights[index],
          lineCount: index == 0 ? 2 : 1,
          showLeading: index != 0,
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double widthFactor;
  final double height;
  final double radius;

  const _SkeletonBox({
    this.width,
    this.widthFactor = 1,
    required this.height,
    this.radius = 999,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    if (width != null) {
      child = SizedBox(width: width, child: child);
    } else if (widthFactor < 1) {
      child = FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: child,
      );
    }

    return child;
  }
}
