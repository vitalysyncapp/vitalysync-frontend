import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

enum CoreTutorialTarget {
  navigation,
  home,
  log,
  nutrition,
  dashboard,
  assistant,
  none,
}

class CoreTutorialOverlay extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Map<CoreTutorialTarget, GlobalKey> targetKeys;
  final Future<void> Function() onFinished;

  const CoreTutorialOverlay({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.targetKeys,
    required this.onFinished,
  });

  @override
  State<CoreTutorialOverlay> createState() => _CoreTutorialOverlayState();
}

class _CoreTutorialOverlayState extends State<CoreTutorialOverlay> {
  static const _transitionDuration = Duration(milliseconds: 260);
  static const _tabSwitchDelay = Duration(milliseconds: 430);

  int _currentStep = 0;
  int _measureToken = 0;
  Rect? _targetRect;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncStepSideEffects();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CoreTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
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
    final tabIndex = step.tabIndex;
    final willSwitchTab = tabIndex != null && tabIndex != widget.currentIndex;

    if (willSwitchTab) {
      widget.onTabSelected(tabIndex);
    }

    _queueTargetUpdate(delay: willSwitchTab ? _tabSwitchDelay : Duration.zero);
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5BDEC1).withValues(alpha: 0.38),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _TutorialPanel(
            step: step,
            stepNumber: _currentStep + 1,
            totalSteps: _coreTutorialSteps.length,
            targetRect: _targetRect,
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
  }
}

class _TutorialPanel extends StatelessWidget {
  final _TutorialStepData step;
  final int stepNumber;
  final int totalSteps;
  final Rect? targetRect;
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
    final target = targetRect;
    final placeAtTop = target != null && target.center.dy > size.height * 0.55;
    final maxPanelHeight = math.max(
      260.0,
      size.height - padding.top - padding.bottom - 36,
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      top: placeAtTop ? padding.top + 16 : null,
      bottom: placeAtTop ? null : padding.bottom + 20,
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 540, maxHeight: maxPanelHeight),
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TutorialIcon(icon: step.icon),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Step $stepNumber of $totalSteps',
                                  style: TextStyle(
                                    color: pageSecondaryTextColor(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 5,
                                    value: stepNumber / totalSteps,
                                    backgroundColor:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFD6EEE7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            key: const ValueKey('core-tutorial-skip-button'),
                            onPressed: isFinishing ? null : onSkip,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Skip'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Column(
                          key: ValueKey(step.title),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                color: pagePrimaryTextColor(context),
                                fontSize: 22,
                                height: 1.12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              step.body,
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                                fontSize: 14.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('core-tutorial-back-button'),
                              onPressed: isFirstStep || isFinishing
                                  ? null
                                  : onBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
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
                                      isLastStep
                                          ? Icons.check_rounded
                                          : Icons.arrow_forward_rounded,
                                    ),
                              label: Text(isLastStep ? 'Finish' : 'Next'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialIcon extends StatelessWidget {
  final IconData icon;

  const _TutorialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D8CA8), Color(0xFF5BDEC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2BB9AD).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 25),
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

class _TutorialStepData {
  final CoreTutorialTarget target;
  final int? tabIndex;
  final IconData icon;
  final String title;
  final String body;

  const _TutorialStepData({
    required this.target,
    required this.tabIndex,
    required this.icon,
    required this.title,
    required this.body,
  });
}

const _coreTutorialSteps = [
  _TutorialStepData(
    target: CoreTutorialTarget.navigation,
    tabIndex: null,
    icon: Icons.explore_rounded,
    title: 'Welcome to your VitalySync tour',
    body:
        'VitalySync helps you notice wellness patterns before burnout gets loud. It offers awareness and lifestyle support only, not medical advice.',
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.home,
    tabIndex: 0,
    icon: Icons.home_rounded,
    title: 'Home is your daily snapshot',
    body:
        'Start here for burnout risk, sleep and hydration summaries, quick actions, environment context, and the first signals from your daily rhythm.',
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.log,
    tabIndex: 1,
    icon: Icons.monitor_heart_rounded,
    title: 'Log is your daily check-in',
    body:
        'Record sleep, mood, energy, hydration, workload, stress, symptoms, exercise, and recovery habits so your insights stay grounded in real days.',
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.nutrition,
    tabIndex: 2,
    icon: Icons.camera_alt_rounded,
    title: 'Nutrition keeps meals in context',
    body:
        'Use camera or manual meal logging, review nutrition analysis, confirm meals, and watch calories and macros alongside your wellness data.',
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.dashboard,
    tabIndex: 3,
    icon: Icons.analytics_rounded,
    title: 'Dashboard shows the bigger pattern',
    body:
        'Review burnout trends, sleep patterns, nutrition analytics, symptom frequency, mood volatility, and progress toward your goals.',
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.assistant,
    tabIndex: 3,
    icon: Icons.auto_awesome_rounded,
    title: 'The assistant adapts to your day',
    body:
        'Open the floating assistant for smart nudges, quick hydration or meal support, exercise suggestions, and your weekly pulse.',
  ),
  _TutorialStepData(
    target: CoreTutorialTarget.none,
    tabIndex: null,
    icon: Icons.check_circle_rounded,
    title: 'You are ready to begin',
    body:
        'Keep logging consistently and VitalySync will keep the experience personal, practical, and focused on your wellness patterns.',
  ),
];
