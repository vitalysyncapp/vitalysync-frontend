part of 'floating_smart_nudge_assistant.dart';

class _AssistantLoadingCard extends StatelessWidget {
  const _AssistantLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _AssistantLottieIcon extends StatelessWidget {
  final String emoji;
  final double size;
  final double fallbackFontSize;

  const _AssistantLottieIcon({
    required this.emoji,
    required this.size,
    required this.fallbackFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      _assistantAnimationPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          emoji,
          style: TextStyle(fontSize: fallbackFontSize, height: 1),
        );
      },
    );
  }
}

class _FloatingHeartButton extends StatelessWidget {
  final String emoji;
  final double size;
  final bool isActive;
  final bool isDragging;
  final bool? hasPendingWeeklyPulse;
  final VoidCallback onTap;

  const _FloatingHeartButton({
    required this.emoji,
    required this.size,
    required this.isActive,
    required this.isDragging,
    required this.hasPendingWeeklyPulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Wellness assistant',
      child: Semantics(
        button: true,
        label: 'Open wellness assistant',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: isDragging
                  ? 1.08
                  : isActive
                  ? 1.04
                  : 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
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
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.92),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.32 : 0.14,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF40B8D6,
                          ).withValues(alpha: isDark ? 0.2 : 0.26),
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _AssistantLottieIcon(
                      emoji: emoji,
                      size: 44,
                      fallbackFontSize: 26,
                    ),
                  ),
                  if (hasPendingWeeklyPulse == true)
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF123655)
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFEAB308,
                              ).withValues(alpha: 0.38),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
