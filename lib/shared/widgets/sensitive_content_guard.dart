import 'dart:ui';

import 'package:flutter/material.dart';

import '../preferences/app_preferences.dart';
import '../theme/app_page_style.dart';
import 'package:vitalysync/l10n/localized_text.dart';

/// Wraps [child] and obscures it when the "Hide sensitive content" preference
/// is active. The card shell stays visible; only the inner data area receives a
/// frosted‐glass mask with an animated eye icon.
///
/// Tap the masked area to reveal the content. Tap again to re‐hide it.
class SensitiveContentGuard extends StatefulWidget {
  final Widget child;
  final bool allowPeek;

  const SensitiveContentGuard({
    super.key,
    required this.child,
    this.allowPeek = true,
  });

  @override
  State<SensitiveContentGuard> createState() => _SensitiveContentGuardState();
}

class _SensitiveContentGuardState extends State<SensitiveContentGuard>
    with SingleTickerProviderStateMixin {
  bool _isRevealed = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleReveal() {
    if (!widget.allowPeek) return;

    setState(() => _isRevealed = !_isRevealed);

    if (_isRevealed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: AppPreferencesController.instance.notifier,
      builder: (context, prefs, _) {
        if (!prefs.hideSensitiveContent) {
          return widget.child;
        }

        if (_isRevealed) {
          return _buildRevealedContent(context);
        }

        return _buildMaskedContent(context);
      },
    );
  }

  Widget _buildRevealedContent(BuildContext context) {
    return GestureDetector(
      onTap: _toggleReveal,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            children: [
              widget.child,
              Positioned(
                right: 8,
                top: 8,
                child: _RevealedBadge(onTap: _toggleReveal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaskedContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: widget.allowPeek ? _toggleReveal : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Keep the child in the tree so it retains its size for layout.
            Opacity(opacity: 0.0, child: widget.child),

            // Frosted overlay.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.visibility_off_rounded,
                          size: 22,
                          color: accent.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LocalizedText(
                        'Content hidden',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                      if (widget.allowPeek) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 14,
                                color: accent.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              LocalizedText(
                                'Tap to view',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accent.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

/// Small pill badge shown in the top-right corner when content is revealed,
/// giving the user a clear "tap to hide" affordance.
class _RevealedBadge extends StatelessWidget {
  final VoidCallback onTap;

  const _RevealedBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_rounded,
              size: 14,
              color: accent,
            ),
            const SizedBox(width: 4),
            LocalizedText(
              'Tap to hide',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
