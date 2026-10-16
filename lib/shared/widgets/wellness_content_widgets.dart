import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/adaptive/data/wellness_content_api.dart';
import '../../l10n/localized_text.dart';

final Set<VoidCallback> _visibilityChecks = {};
bool _hasVisibilityFrameCallback = false;

/// Records a card only after it intersects the viewport, including on scroll.
class WellnessContentExposure extends StatefulWidget {
  final Map<String, dynamic>? content;
  final Widget child;
  const WellnessContentExposure({
    super.key,
    required this.content,
    required this.child,
  });
  @override
  State<WellnessContentExposure> createState() =>
      _WellnessContentExposureState();
}

class _WellnessContentExposureState extends State<WellnessContentExposure>
    with WidgetsBindingObserver {
  ScrollPosition? _position;
  String? _recorded;
  DateTime? _retryAfter;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visibilityChecks.add(_schedule);
    if (!_hasVisibilityFrameCallback) {
      _hasVisibilityFrameCallback = true;
      WidgetsBinding.instance.addPersistentFrameCallback((_) {
        for (final check in List<VoidCallback>.of(_visibilityChecks)) {
          check();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_schedule);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_schedule);
    _schedule();
  }

  @override
  void didUpdateWidget(covariant WellnessContentExposure oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  void _schedule() {
    if (!mounted ||
        _saving ||
        widget.content == null ||
        WellnessContentApi.metadata(widget.content!)['content_id'] ==
            _recorded) {
      return;
    }
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_record()));
  }

  Future<void> _record() async {
    if (!mounted || _saving || widget.content == null) return;
    final content = widget.content!;
    final id = WellnessContentApi.metadata(content)['content_id']?.toString();
    if (id == null || id == _recorded) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    RenderObject child = box;
    for (
      var parent = child.parent;
      parent is RenderObject;
      parent = child.parent
    ) {
      if (parent is RenderOffstage && parent.offstage) return;
      if (parent is RenderOpacity && parent.opacity == 0) return;
      if (parent is RenderIndexedStack) {
        if (parent.index == null) return;
        RenderBox? visible = parent.firstChild;
        for (var index = 0; index < parent.index! && visible != null; index++) {
          visible = parent.childAfter(visible);
        }
        if (!identical(visible, child)) return;
      }
      child = parent;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.overlaps(Offset.zero & MediaQuery.sizeOf(context))) return;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (viewport is RenderBox &&
        viewport.hasSize &&
        !rect.overlaps(viewport.localToGlobal(Offset.zero) & viewport.size)) {
      return;
    }
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _saving = true;
    try {
      await WellnessContentApi.respond(content, 'shown');
      _recorded = id;
    } catch (_) {
      _retryAfter = DateTime.now().add(const Duration(minutes: 1));
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _visibilityChecks.remove(_schedule);
    _position?.removeListener(_schedule);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Done / Another idea / Not now actions for a nudge card.
///
/// When [response] is `done` or `not_now`, the actions are replaced by a short
/// friendly acknowledgment. `another_idea` keeps the regular actions because
/// the parent swaps in a new suggestion.
class NudgeResponseActions extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onResponse;
  final String? response;
  final Color? accentColor;
  const NudgeResponseActions({
    super.key,
    required this.enabled,
    required this.onResponse,
    this.response,
    this.accentColor,
  });

  @override
  State<NudgeResponseActions> createState() => _NudgeResponseActionsState();
}

class _NudgeResponseActionsState extends State<NudgeResponseActions> {
  static const _doneReplies = [
    ('Great job', '🎉', 'That small step really counts.'),
    ('Nice one', '🌟', 'You made a little room for yourself.'),
    ('Well done', '💪', 'Keep that gentle momentum going.'),
  ];
  static const _notNowReplies = [
    ('Okay, got it', '👌', 'We’ll give this one some space.'),
    ('No worries', '🌿', 'We’ll find a better moment later.'),
  ];

  String? _name;
  final int _variant = DateTime.now().microsecond;

  @override
  void initState() {
    super.initState();
    unawaited(_loadName());
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('username')?.trim() ?? '';
    if (!mounted || raw.isEmpty) return;
    setState(() => _name = raw.split(RegExp(r'\s+')).first);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final response = widget.response;
    final showAck = response == 'done' || response == 'not_now';

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: showAck
            ? _buildAcknowledgment(context, response!, accent)
            : _buildActions(context, accent),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color accent) {
    return Wrap(
      key: const ValueKey('nudge-actions'),
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (index, item) in const [
          ('done', 'Done', Icons.check_rounded),
          ('another_idea', 'Another idea', Icons.autorenew_rounded),
          ('not_now', 'Not now', Icons.snooze_rounded),
        ].indexed)
          _NudgeActionTile(
            id: 'nudge-action-${item.$1}',
            label: item.$2,
            icon: item.$3,
            accent: accent,
            primary: index == 0,
            onTap: widget.enabled ? () => widget.onResponse(item.$1) : null,
          ),
      ],
    );
  }

  Widget _buildAcknowledgment(
    BuildContext context,
    String response,
    Color accent,
  ) {
    final isDone = response == 'done';
    final replies = isDone ? _doneReplies : _notNowReplies;
    final reply = replies[_variant % replies.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final title = reply.$1.localizedCopy(context);
    final headline = _name == null ? '$title!' : '$title, $_name!';

    return Container(
      key: ValueKey('nudge-ack-$response'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.20 : 0.14),
            accent.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Text(reply.$2, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                LocalizedText(
                  reply.$3,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.68),
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NudgeActionTile extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final Color accent;
  final bool primary;
  final VoidCallback? onTap;

  const _NudgeActionTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onTap != null;
    final foreground = primary
        ? (isDark ? Colors.black.withValues(alpha: 0.85) : Colors.white)
        : accent;
    final background = primary
        ? accent
        : accent.withValues(alpha: isDark ? 0.12 : 0.08);
    final border = primary ? accent : accent.withValues(alpha: 0.24);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: Material(
        key: ValueKey(id),
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 5),
                Flexible(
                  child: LocalizedText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContentFreshnessNote extends StatelessWidget {
  final Map<String, dynamic> metadata;
  const ContentFreshnessNote({super.key, required this.metadata});
  @override
  Widget build(BuildContext context) {
    if (metadata['offline_cached'] != true) return const SizedBox.shrink();
    final at = DateTime.tryParse(
      '${metadata['cached_at'] ?? metadata['generated_at']}',
    )?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        children: [
          const LocalizedText('Saved offline', style: TextStyle(fontSize: 11)),
          if (at != null)
            Text(
              '${at.month}/${at.day} ${TimeOfDay.fromDateTime(at).format(context)}',
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }
}
