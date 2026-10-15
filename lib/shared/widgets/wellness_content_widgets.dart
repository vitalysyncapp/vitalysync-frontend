import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class NudgeResponseActions extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onResponse;
  const NudgeResponseActions({
    super.key,
    required this.enabled,
    required this.onResponse,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      for (final item in const [
        ('done', 'Done', Icons.check_rounded),
        ('another_idea', 'Another idea', Icons.refresh_rounded),
        ('not_now', 'Not now', Icons.snooze_rounded),
      ])
        TextButton.icon(
          onPressed: enabled ? () => onResponse(item.$1) : null,
          icon: Icon(item.$3, size: 17),
          label: LocalizedText(item.$2),
        ),
    ],
  );
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
