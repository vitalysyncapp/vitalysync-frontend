import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/nutrition_api.dart';

class TodaysMealsCard extends StatefulWidget {
  final VoidCallback onAddTap;
  final ValueChanged<String> onMealTypeAddTap;
  final List<NutritionMealLog> meals;
  final bool revealOnScroll;
  final ScrollController? verticalScrollController;

  const TodaysMealsCard({
    super.key,
    required this.onAddTap,
    required this.onMealTypeAddTap,
    required this.meals,
    this.revealOnScroll = true,
    this.verticalScrollController,
  });

  @override
  State<TodaysMealsCard> createState() => _TodaysMealsCardState();
}

class _TodaysMealsCardState extends State<TodaysMealsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  ScrollPosition? _scrollPosition;
  bool _hasRevealed = false;
  bool _visibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    widget.verticalScrollController?.addListener(_handleScroll);
    if (!widget.revealOnScroll) {
      _completeReveal();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || !widget.revealOnScroll) {
      _completeReveal();
      return;
    }

    final nextPosition = widget.verticalScrollController == null
        ? Scrollable.maybeOf(context)?.position
        : null;
    if (!identical(nextPosition, _scrollPosition)) {
      _scrollPosition?.removeListener(_handleScroll);
      _scrollPosition = nextPosition;
      _scrollPosition?.addListener(_handleScroll);
    }
    _scheduleVisibilityCheck();
  }

  @override
  void didUpdateWidget(covariant TodaysMealsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.verticalScrollController,
      widget.verticalScrollController,
    )) {
      oldWidget.verticalScrollController?.removeListener(_handleScroll);
      widget.verticalScrollController?.addListener(_handleScroll);
    }
    if (!widget.revealOnScroll) {
      _completeReveal();
    } else if (!oldWidget.revealOnScroll && !_hasRevealed) {
      _scheduleVisibilityCheck();
    }
  }

  void _completeReveal() {
    _hasRevealed = true;
    _revealController.value = 1;
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled || _hasRevealed) {
      return;
    }
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      _checkVisibility();
    });
  }

  void _handleScroll() {
    _scheduleVisibilityCheck();
  }

  void _checkVisibility() {
    if (!mounted || _hasRevealed) {
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return;
    }

    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final mediaQuery = MediaQuery.maybeOf(context);
    final viewportHeight = mediaQuery?.size.height ?? 0;
    final viewportTop = mediaQuery?.padding.top ?? 0;
    final triggerLine = viewportHeight * 0.92;

    if (top <= triggerLine && bottom >= viewportTop) {
      _hasRevealed = true;
      _revealController.forward();
    }
  }

  @override
  void dispose() {
    widget.verticalScrollController?.removeListener(_handleScroll);
    _scrollPosition?.removeListener(_handleScroll);
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final mealsByType = <String, NutritionMealLog>{
      for (final meal in widget.meals) meal.mealType: meal,
    };
    final sectionAnimation = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0, 0.58, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      key: const ValueKey('todays-meals-scroll-reveal'),
      opacity: sectionAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(sectionAnimation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's meals",
                    style: TextStyle(
                      fontSize: isCompact ? 15.5 : 16.5,
                      fontWeight: FontWeight.w800,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('manual-log-meals-header'),
                  onPressed: widget.onAddTap,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF79A9FF)
                        : const Color(0xFF3347A8),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 7 : 9,
                      vertical: 5,
                    ),
                  ),
                  label: Text(
                    'Manual log',
                    style: TextStyle(
                      fontSize: isCompact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    size: isCompact ? 16 : 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 7 : 9),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth =
                    (constraints.maxWidth * (isCompact ? 0.43 : 0.4))
                        .clamp(132.0, 156.0)
                        .toDouble();

                return SizedBox(
                  height: isCompact ? 198 : 210,
                  child: ListView.separated(
                    key: const ValueKey('todays-meals-carousel'),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(1, 2, isCompact ? 8 : 12, 9),
                    itemCount: _mealSlots.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: isCompact ? 9 : 11),
                    itemBuilder: (context, index) {
                      final slot = _mealSlots[index];
                      return _MealCardReveal(
                        animation: _revealController,
                        index: index,
                        child: SizedBox(
                          width: cardWidth,
                          child: _MealSlotCard(
                            slot: slot,
                            meal: mealsByType[slot.value],
                            isCompact: isCompact,
                            onAddTap: () => widget.onMealTypeAddTap(slot.value),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TodaysMealsSkeleton extends StatelessWidget {
  const TodaysMealsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      ignorePointers: false,
      child: TodaysMealsCard(
        onAddTap: _noop,
        onMealTypeAddTap: _noopMealType,
        meals: const [],
        revealOnScroll: false,
      ),
    );
  }
}

class _MealCardReveal extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;

  const _MealCardReveal({
    required this.animation,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final start = 0.12 + (index * 0.09);
        final end = (0.7 + (index * 0.08)).clamp(0.0, 1.0);
        final rawProgress = ((animation.value - start) / (end - start)).clamp(
          0.0,
          1.0,
        );
        final progress = Curves.easeOutCubic.transform(rawProgress);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(24 * (1 - progress), 0),
            child: child,
          ),
        );
      },
    );
  }
}

void _noop() {}

void _noopMealType(String _) {}

class _MealSlotCard extends StatelessWidget {
  final _MealSlot slot;
  final NutritionMealLog? meal;
  final bool isCompact;
  final VoidCallback onAddTap;

  const _MealSlotCard({
    required this.slot,
    required this.meal,
    required this.isCompact,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final loggedMeal = meal;
    final isLogged = loggedMeal != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? slot.darkColors : slot.lightColors;
    final foods = loggedMeal?.items
        .map((item) => item.foodName.trim())
        .where((name) => name.isNotEmpty);
    final foodSummary = foods == null || foods.isEmpty
        ? 'Saved meal items'
        : foods.join(', ');

    return Semantics(
      container: true,
      label: isLogged
          ? '${slot.label}, ${loggedMeal.totalCalories.round()} calories, $foodSummary'
          : '${slot.label}, not logged yet',
      child: Material(
        key: ValueKey('meal-card-${slot.value}'),
        color: colors.first,
        elevation: isDark ? 5 : 4,
        shadowColor: colors.last.withValues(alpha: isDark ? 0.42 : 0.3),
        shape: _MealCardBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.36),
            width: 1.15,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 14,
              isCompact ? 12 : 14,
              isCompact ? 11 : 13,
              isCompact ? 11 : 13,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isCompact ? 42 : 46,
                      height: isCompact ? 42 : 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.93),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot.emoji,
                        style: TextStyle(
                          fontSize: isCompact ? 24 : 27,
                          height: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isLogged)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: isCompact ? 14 : 16,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isCompact ? 9 : 10),
                Text(
                  slot.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: isCompact ? 5 : 6),
                Text(
                  isLogged ? foodSummary : 'Not logged yet',
                  key: ValueKey('meal-status-${slot.value}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: isCompact ? 9.5 : 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                if (isLogged) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            '${loggedMeal.totalCalories.round()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 21 : 23,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          'kcal',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: isCompact ? 8.5 : 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 5 : 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'P ${loggedMeal.totalProteinG.round()}g  •  C ${loggedMeal.totalCarbsG.round()}g  •  F ${loggedMeal.totalFatG.round()}g',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: isCompact ? 8.3 : 9.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ready to log',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: isCompact ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Log ${slot.label} manually',
                        child: InkWell(
                          key: ValueKey('add-meal-${slot.value}'),
                          onTap: onAddTap,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: isCompact ? 31 : 34,
                            height: isCompact ? 31 : 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: colors.last,
                              size: isCompact ? 19 : 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealCardBorder extends ShapeBorder {
  final BorderSide side;

  const _MealCardBorder({this.side = BorderSide.none});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.width), textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final topLeftRadius = rect.width * 0.19;
    final topRightRadius = rect.width * 0.31;
    final bottomRadius = rect.width * 0.065;
    final bottomInset = rect.width * 0.035;

    return Path()
      ..moveTo(rect.left + topLeftRadius, rect.top)
      ..lineTo(rect.right - topRightRadius, rect.top)
      ..quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + topRightRadius,
      )
      ..lineTo(rect.right - bottomInset, rect.bottom - bottomRadius)
      ..quadraticBezierTo(
        rect.right - bottomInset,
        rect.bottom,
        rect.right - bottomInset - bottomRadius,
        rect.bottom,
      )
      ..lineTo(rect.left + bottomInset + bottomRadius, rect.bottom)
      ..quadraticBezierTo(
        rect.left + bottomInset,
        rect.bottom,
        rect.left + bottomInset,
        rect.bottom - bottomRadius,
      )
      ..lineTo(rect.left, rect.top + topLeftRadius)
      ..quadraticBezierTo(
        rect.left,
        rect.top,
        rect.left + topLeftRadius,
        rect.top,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) {
      return;
    }
    final paint = side.toPaint()..strokeJoin = StrokeJoin.round;
    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);
  }

  @override
  ShapeBorder scale(double t) => _MealCardBorder(side: side.scale(t));
}

class _MealSlot {
  final String value;
  final String label;
  final String emoji;
  final List<Color> lightColors;
  final List<Color> darkColors;

  const _MealSlot({
    required this.value,
    required this.label,
    required this.emoji,
    required this.lightColors,
    required this.darkColors,
  });
}

const _mealSlots = [
  _MealSlot(
    value: 'breakfast',
    label: 'Breakfast',
    emoji: '🍳',
    lightColors: [Color(0xFFFF9B70), Color(0xFFF26B73)],
    darkColors: [Color(0xFFB85E43), Color(0xFF8F354F)],
  ),
  _MealSlot(
    value: 'lunch',
    label: 'Lunch',
    emoji: '🥗',
    lightColors: [Color(0xFF6678EF), Color(0xFF4142C8)],
    darkColors: [Color(0xFF4654B8), Color(0xFF292A80)],
  ),
  _MealSlot(
    value: 'snack',
    label: 'Snack',
    emoji: '🍉',
    lightColors: [Color(0xFFF46591), Color(0xFFE52D72)],
    darkColors: [Color(0xFFAE466B), Color(0xFF8A1E52)],
  ),
  _MealSlot(
    value: 'dinner',
    label: 'Dinner',
    emoji: '🍲',
    lightColors: [Color(0xFF554FC6), Color(0xFF29236F)],
    darkColors: [Color(0xFF3D398F), Color(0xFF1C194C)],
  ),
];
