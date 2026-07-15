import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/navigation/main_tab.dart';
import '../../../../shared/theme/app_page_style.dart';

enum CoreTutorialTarget {
  navigation,
  home,
  log,
  nutrition,
  dashboard,
  profile,
  assistant,
  settingsAssistantTile,
  assistantOverlaySwitch,
  none,
}

enum CoreTutorialRoute { main, settings, assistantSettings }

enum _TutorialAssistantDock { topLeft, topRight, bottomLeft, bottomRight }

class CoreTutorialOverlay extends StatefulWidget {
  final MainTab currentTab;
  final ValueChanged<MainTab> onTabSelected;
  final Map<CoreTutorialTarget, GlobalKey> targetKeys;
  final Future<void> Function(CoreTutorialRoute route) onRouteRequested;
  final Future<void> Function() onFinished;

  const CoreTutorialOverlay({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.targetKeys,
    required this.onRouteRequested,
    required this.onFinished,
  });

  @override
  State<CoreTutorialOverlay> createState() => _CoreTutorialOverlayState();
}

class _CoreTutorialOverlayState extends State<CoreTutorialOverlay>
    with SingleTickerProviderStateMixin {
  static const _transitionDuration = Duration(milliseconds: 260);
  static const _tabSwitchDelay = Duration(milliseconds: 430);
  static const _assistantAnimationPath = 'assets/animations/Assistant.json';

  int _currentStep = 0;
  int _measureToken = 0;
  Rect? _targetRect;
  bool _isFinishing = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncStepSideEffects();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CoreTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab != widget.currentTab) {
      _queueTargetUpdate();
    }
  }

  void _goToStep(int nextStep) {
    if (nextStep < 0 || nextStep >= _coreTutorialSteps.length) {
      return;
    }

    setState(() {
      _currentStep = nextStep;
      _targetRect = null;
    });
    _syncStepSideEffects();
  }

  void _syncStepSideEffects() {
    final step = _coreTutorialSteps[_currentStep];
    final tab = step.tab;
    final willSwitchTab = tab != null && tab != widget.currentTab;
    final settleDelay = _longerDelay(
      willSwitchTab ? _tabSwitchDelay : Duration.zero,
      step.settleDelay,
    );

    if (willSwitchTab) {
      widget.onTabSelected(tab);
    }

    unawaited(widget.onRouteRequested(step.route));
    _queueTargetUpdate(delay: settleDelay);
  }

  void _queueTargetUpdate({Duration delay = Duration.zero}) {
    final token = ++_measureToken;

    Future<void>.delayed(delay, () {
      if (!mounted || token != _measureToken) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && token == _measureToken) {
          _updateTargetRect();
        }
      });
    });
  }

  void _updateTargetRect() {
    final step = _coreTutorialSteps[_currentStep];
    if (step.target == CoreTutorialTarget.none) {
      if (_targetRect != null) {
        setState(() => _targetRect = null);
      }
      return;
    }

    final targetContext = widget.targetKeys[step.target]?.currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (targetContext == null ||
        renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      if (_targetRect != null) {
        setState(() => _targetRect = null);
      }
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final offset = renderObject.localToGlobal(Offset.zero);
    final rect = offset & renderObject.size;
    final clamped = _clampRect(rect.inflate(8), size);

    if (clamped != _targetRect) {
      setState(() => _targetRect = clamped);
    }
  }

  Rect? _clampRect(Rect rect, Size size) {
    final left = rect.left.clamp(8.0, size.width - 8.0).toDouble();
    final top = rect.top.clamp(8.0, size.height - 8.0).toDouble();
    final right = rect.right.clamp(8.0, size.width - 8.0).toDouble();
    final bottom = rect.bottom.clamp(8.0, size.height - 8.0).toDouble();

    if (right - left < 12 || bottom - top < 12) {
      return null;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Duration _longerDelay(Duration first, Duration second) {
    return first.compareTo(second) >= 0 ? first : second;
  }

  Future<void> _finishTutorial() async {
    if (_isFinishing) {
      return;
    }

    setState(() => _isFinishing = true);
    await widget.onFinished();
    if (mounted) {
      setState(() => _isFinishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _coreTutorialSteps[_currentStep];

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulseValue = _pulseController.value;

        return Semantics(
          namesRoute: true,
          label: 'VitalySync tutorial',
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: CustomPaint(
                  painter: _TutorialSpotlightPainter(
                    targetRect: _targetRect,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              const ModalBarrier(dismissible: false, color: Colors.transparent),
              if (_targetRect != null)
                AnimatedPositioned(
                  duration: _transitionDuration,
                  curve: Curves.easeOutCubic,
                  left: _targetRect!.left,
                  top: _targetRect!.top,
                  width: _targetRect!.width,
                  height: _targetRect!.height,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TutorialFocusFramePainter(
                        pulseValue: pulseValue,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                ),
              _TutorialPanel(
                step: step,
                stepNumber: _currentStep + 1,
                totalSteps: _coreTutorialSteps.length,
                targetRect: _targetRect,
                pulseValue: pulseValue,
                isFirstStep: _currentStep == 0,
                isLastStep: _currentStep == _coreTutorialSteps.length - 1,
                isFinishing: _isFinishing,
                onBack: () => _goToStep(_currentStep - 1),
                onNext: () {
                  if (_currentStep == _coreTutorialSteps.length - 1) {
                    unawaited(_finishTutorial());
                  } else {
                    _goToStep(_currentStep + 1);
                  }
                },
                onSkip: () => unawaited(_finishTutorial()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TutorialPanel extends StatelessWidget {
  final _TutorialStepData step;
  final int stepNumber;
  final int totalSteps;
  final Rect? targetRect;
  final double pulseValue;
  final bool isFirstStep;
  final bool isLastStep;
  final bool isFinishing;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TutorialPanel({
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.targetRect,
    required this.pulseValue,
    required this.isFirstStep,
    required this.isLastStep,
    required this.isFinishing,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final padding = mediaQuery.padding;
    final dock = step.assistantDock;
    final alignRight =
        dock == _TutorialAssistantDock.topRight ||
        dock == _TutorialAssistantDock.bottomRight;
    final placeAtTop =
        dock == _TutorialAssistantDock.topLeft ||
        dock == _TutorialAssistantDock.topRight;
    final panelWidth = math.min(size.width - 28, 560.0);
    final availableHeight = math.max(
      190.0,
      size.height - padding.top - padding.bottom - 44,
    );
    final assistantSize = size.width < 380 ? 54.0 : 62.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: alignRight ? null : 14,
      right: alignRight ? 14 : null,
      top: placeAtTop ? padding.top + 14 : null,
      bottom: placeAtTop ? null : padding.bottom + 18,
      width: panelWidth,
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          crossAxisAlignment: placeAtTop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
          children: [
            _TutorialAssistantAvatar(
              animationPath: _CoreTutorialOverlayState._assistantAnimationPath,
              size: assistantSize,
              pulseValue: pulseValue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AssistantSpeechBubble(
                tailOnRight: alignRight,
                tailNearTop: placeAtTop,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: availableHeight),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _TutorialBubbleContent(
                        key: ValueKey(step.title),
                        step: step,
                        stepNumber: stepNumber,
                        totalSteps: totalSteps,
                        isFirstStep: isFirstStep,
                        isLastStep: isLastStep,
                        isFinishing: isFinishing,
                        onBack: onBack,
                        onNext: onNext,
                        onSkip: onSkip,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialBubbleContent extends StatelessWidget {
  final _TutorialStepData step;
  final int stepNumber;
  final int totalSteps;
  final bool isFirstStep;
  final bool isLastStep;
  final bool isFinishing;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TutorialBubbleContent({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isFirstStep,
    required this.isLastStep,
    required this.isFinishing,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;

    final backButton = OutlinedButton.icon(
      key: const ValueKey('core-tutorial-back-button'),
      onPressed: isFirstStep || isFinishing ? null : onBack,
      icon: const Icon(Icons.arrow_back_rounded),
      label: const Text('Back'),
    );
    final nextButton = ElevatedButton.icon(
      key: const ValueKey('core-tutorial-next-button'),
      onPressed: isFinishing ? null : onNext,
      icon: isFinishing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Icon(
              isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
            ),
      label: Text(isLastStep ? 'Finish' : 'Next'),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D8CA8), Color(0xFF5BDEC1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(step.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $stepNumber of $totalSteps',
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: stepNumber / totalSteps,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFD6EEE7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('core-tutorial-skip-button'),
              tooltip: 'Skip tutorial',
              onPressed: isFinishing ? null : onSkip,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          step.title,
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: 21,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          step.body,
          style: TextStyle(
            color: pageSecondaryTextColor(context),
            fontSize: 14.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 18),
        if (isNarrow) ...[
          SizedBox(width: double.infinity, child: nextButton),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: backButton),
        ] else
          Row(
            children: [
              Expanded(child: backButton),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: nextButton),
            ],
          ),
      ],
    );
  }
}

class _AssistantSpeechBubble extends StatelessWidget {
  final bool tailOnRight;
  final bool tailNearTop;
  final Widget child;

  const _AssistantSpeechBubble({
    required this.tailOnRight,
    required this.tailNearTop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tailColor = isDark
        ? const Color(0xFF132438).withValues(alpha: 0.98)
        : Colors.white.withValues(alpha: 0.98);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: tailOnRight ? null : -5,
          right: tailOnRight ? -5 : null,
          top: tailNearTop ? 22 : null,
          bottom: tailNearTop ? null : 22,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: tailColor,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF132438).withValues(alpha: 0.98),
                      const Color(0xFF0C1828).withValues(alpha: 0.98),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.98),
                      const Color(0xFFF1FBF7).withValues(alpha: 0.98),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.2),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: const Color(0xFF5BDEC1).withValues(alpha: 0.16),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _TutorialAssistantAvatar extends StatelessWidget {
  final String animationPath;
  final double size;
  final double pulseValue;

  const _TutorialAssistantAvatar({
    required this.animationPath,
    required this.size,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wave = math.sin(pulseValue * math.pi * 2);
    final ringScale = 1 + (pulseValue * 0.16);

    return Transform.translate(
      offset: Offset(0, wave * 3),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: ringScale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(
                    0xFF5BDEC1,
                  ).withValues(alpha: (1 - pulseValue) * 0.34),
                  width: 2,
                ),
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF123655), Color(0xFF1FB489)]
                    : const [Color(0xFFFFFFFF), Color(0xFFE8FAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.92),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.15),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: const Color(
                    0xFF40B8D6,
                  ).withValues(alpha: isDark ? 0.22 : 0.28),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Lottie.asset(
              animationPath,
              width: size * 0.78,
              height: size * 0.78,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.auto_awesome_rounded,
                color: isDark ? Colors.white : const Color(0xFF1D8CA8),
                size: size * 0.42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final bool isDark;

  const _TutorialSpotlightPainter({
    required this.targetRect,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());

    canvas.drawRect(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: isDark ? 0.68 : 0.58),
    );

    final target = targetRect;
    if (target != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(target, const Radius.circular(26)),
        Paint()..blendMode = BlendMode.clear,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) {
    return targetRect != oldDelegate.targetRect || isDark != oldDelegate.isDark;
  }
}

class _TutorialFocusFramePainter extends CustomPainter {
  final double pulseValue;
  final bool isDark;

  const _TutorialFocusFramePainter({
    required this.pulseValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(math.min(26, size.shortestSide / 2));
    final rrect = RRect.fromRectAndRadius(rect.deflate(1), radius);
    final pulse = math.sin(pulseValue * math.pi);
    final glowRect = rect.inflate(3 + pulse * 4);
    final glowRRect = RRect.fromRectAndRadius(
      glowRect,
      Radius.circular(math.min(32, size.shortestSide / 2 + 6)),
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + pulse * 3
      ..color = const Color(
        0xFF5BDEC1,
      ).withValues(alpha: isDark ? 0.24 + pulse * 0.16 : 0.3 + pulse * 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(glowRRect, glowPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.white.withValues(alpha: 0.94);
    canvas.drawRRect(rrect, borderPaint);

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5BDEC1).withValues(alpha: 0.95);
    const cornerLength = 22.0;
    const inset = 6.0;

    void drawCorner(Offset start, Offset horizontalEnd, Offset verticalEnd) {
      canvas.drawLine(start, horizontalEnd, accentPaint);
      canvas.drawLine(start, verticalEnd, accentPaint);
    }

    drawCorner(
      const Offset(inset, inset),
      const Offset(inset + cornerLength, inset),
      const Offset(inset, inset + cornerLength),
    );
    drawCorner(
      Offset(size.width - inset, inset),
      Offset(size.width - inset - cornerLength, inset),
      Offset(size.width - inset, inset + cornerLength),
    );
    drawCorner(
      Offset(inset, size.height - inset),
      Offset(inset + cornerLength, size.height - inset),
      Offset(inset, size.height - inset - cornerLength),
    );
    drawCorner(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - cornerLength, size.height - inset),
      Offset(size.width - inset, size.height - inset - cornerLength),
    );
  }

  @override
  bool shouldRepaint(covariant _TutorialFocusFramePainter oldDelegate) {
    return pulseValue != oldDelegate.pulseValue || isDark != oldDelegate.isDark;
  }
}

class _TutorialStepData {
  final CoreTutorialTarget target;
  final MainTab? tab;
  final CoreTutorialRoute route;
  final IconData icon;
  final String title;
  final String body;
  final _TutorialAssistantDock assistantDock;
  final Duration settleDelay;

  const _TutorialStepData({
    required this.target,
    required this.tab,
    this.route = CoreTutorialRoute.main,
    required this.icon,
    required this.title,
    required this.body,
    this.assistantDock = _TutorialAssistantDock.bottomRight,
    this.settleDelay = Duration.zero,
  });
}

const _coreTutorialSteps = [
  _TutorialStepData(
    target: CoreTutorialTarget.navigation,
    tab: null,
    icon: Icons.explore_rounded,
    title: 'Welcome to your VitalySync tour',
    body:
        'I will move around the app with you and point out the parts that matter most. VitalySync supports wellness awareness and lifestyle habits, not medical advice.',
    assistantDock: _TutorialAssistantDock.topLeft,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.home,
    tab: MainTab.home,
    icon: Icons.home_rounded,
    title: 'Home is your daily snapshot',
    body:
        'Start here for burnout risk, sleep and hydration summaries, quick actions, environment context, and the first signals from your daily rhythm.',
    assistantDock: _TutorialAssistantDock.bottomRight,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.nutrition,
    tab: MainTab.nutrition,
    icon: Icons.camera_alt_rounded,
    title: 'Nutrition keeps meals in context',
    body:
        'Use camera or manual meal logging, review nutrition analysis, confirm meals, and watch calories and macros alongside your wellness data.',
    assistantDock: _TutorialAssistantDock.topLeft,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.log,
    tab: MainTab.log,
    icon: Icons.monitor_heart_rounded,
    title: 'Log is your daily check-in',
    body:
        'Record sleep, mood, energy, hydration, workload, stress, symptoms, exercise, and recovery habits so your insights stay grounded in real days.',
    assistantDock: _TutorialAssistantDock.topRight,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.dashboard,
    tab: MainTab.dashboard,
    icon: Icons.analytics_rounded,
    title: 'Dashboard shows the bigger pattern',
    body:
        'Review burnout trends, sleep patterns, nutrition analytics, symptom frequency, mood volatility, and progress toward your goals.',
    assistantDock: _TutorialAssistantDock.bottomLeft,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.profile,
    tab: MainTab.profile,
    icon: Icons.person_rounded,
    title: 'Profile keeps your wellness setup together',
    body:
        'Review personal details, wellness baselines, goals, settings, and account actions from your profile tab.',
    assistantDock: _TutorialAssistantDock.topLeft,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.none,
    tab: MainTab.home,
    icon: Icons.leaderboard_rounded,
    title: 'Streaks now have a leaderboard',
    body:
        'Tap your streak chip in the home header to open my streak. The leaderboard compares global, local, role, and goal cohorts using privacy-safe profile details.',
    assistantDock: _TutorialAssistantDock.topRight,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.assistant,
    tab: MainTab.dashboard,
    icon: Icons.auto_awesome_rounded,
    title: 'The assistant adapts to your day',
    body:
        'Open the floating assistant for smart nudges, quick hydration or meal support, exercise suggestions, and your weekly pulse.',
    assistantDock: _TutorialAssistantDock.topRight,
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.settingsAssistantTile,
    tab: null,
    route: CoreTutorialRoute.settings,
    icon: Icons.settings_rounded,
    title: 'Settings keeps assistant access in one place',
    body:
        'I opened settings for you. The assistant section controls whether the assistant can keep helping after you leave the app.',
    assistantDock: _TutorialAssistantDock.bottomLeft,
    settleDelay: Duration(milliseconds: 680),
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.assistantOverlaySwitch,
    tab: null,
    route: CoreTutorialRoute.assistantSettings,
    icon: Icons.bubble_chart_rounded,
    title: 'Overlay mode is optional',
    body:
        'Turn this on only when you want the assistant to appear as a small chat-head above other Android apps. Android may ask for display-over-apps permission first.',
    assistantDock: _TutorialAssistantDock.bottomRight,
    settleDelay: Duration(milliseconds: 680),
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.none,
    tab: null,
    route: CoreTutorialRoute.main,
    icon: Icons.check_circle_rounded,
    title: 'You are ready to begin',
    body:
        'Keep logging consistently and I will keep the experience personal, practical, and focused on your wellness patterns.',
    assistantDock: _TutorialAssistantDock.bottomLeft,
    settleDelay: Duration(milliseconds: 420),
  ),
];
