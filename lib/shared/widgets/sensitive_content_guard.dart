import 'dart:ui';

import 'package:flutter/material.dart';

import '../preferences/app_preferences.dart';
import '../theme/app_page_style.dart';

/// Wraps [child] and obscures it when the "Hide sensitive content" preference
/// is active. The card shell stays visible; only the inner data area receives a
/// frosted‐glass mask with a gentle "Content hidden" label.
///
/// Hold the area to temporarily peek at the content (optional, gated by
/// [allowPeek]).
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

class _SensitiveContentGuardState extends State<SensitiveContentGuard> {
  bool _isPeeking = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: AppPreferencesController.instance.notifier,
      builder: (context, prefs, _) {
        if (!prefs.hideSensitiveContent || _isPeeking) {
          return widget.child;
        }

        return _buildMaskedContent(context);
      },
    );
  }

  Widget _buildMaskedContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPressStart: widget.allowPeek
          ? (_) => setState(() => _isPeeking = true)
          : null,
      onLongPressEnd: widget.allowPeek
          ? (_) => setState(() => _isPeeking = false)
          : null,
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
                child: Container(
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
                      Icon(
                        Icons.visibility_off_outlined,
                        size: 26,
                        color: pageSecondaryTextColor(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Content hidden',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                      if (widget.allowPeek) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Hold to peek',
                          style: TextStyle(
                            fontSize: 11,
                            color: pageSecondaryTextColor(context)
                                .withValues(alpha: 0.6),
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
