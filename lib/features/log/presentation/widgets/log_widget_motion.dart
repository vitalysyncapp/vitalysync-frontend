part of 'log_widgets.dart';

class _LogCardEntrance extends StatefulWidget {
  final int order;
  final bool reveal;
  final Widget child;

  const _LogCardEntrance({
    super.key,
    required this.order,
    required this.reveal,
    required this.child,
  });

  @override
  State<_LogCardEntrance> createState() => _LogCardEntranceState();
}

class _LogCardEntranceState extends State<_LogCardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  bool _hasRevealed = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: widget.order.clamp(0, 6).toInt() * 42);
    const motionDuration = Duration(milliseconds: 440);
    final totalDuration = delay + motionDuration;
    final start = delay.inMilliseconds / totalDuration.inMilliseconds;

    _controller = AnimationController(vsync: this, duration: totalDuration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = Tween<double>(begin: 0.985, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
      _hasRevealed = true;
    } else if (widget.reveal) {
      _reveal();
    }
  }

  @override
  void didUpdateWidget(covariant _LogCardEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.reveal && widget.reveal) {
      _reveal();
    }
  }

  void _reveal() {
    if (_hasRevealed) return;
    _hasRevealed = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class _LogPressable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _LogPressable({required this.onTap, required this.child});

  @override
  State<_LogPressable> createState() => _LogPressableState();
}

class _LogPressableState extends State<_LogPressable> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _isPressed ? 0.975 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
