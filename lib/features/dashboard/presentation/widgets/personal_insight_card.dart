import 'package:flutter/material.dart';
import '../../../adaptive/data/adaptive_nudge_api.dart';
import '../../../adaptive/data/wellness_content_api.dart';
import '../../../../shared/learning/first_week_learning_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/first_week_learning_pill.dart';
import '../../../../shared/widgets/wellness_content_widgets.dart';
import '../../../../l10n/localized_text.dart';

class PersonalInsightCard extends StatefulWidget {
  final AdaptiveNudgeRecommendation? recommendation;
  final bool isLoading;
  final FirstWeekLearningState? learningState;

  const PersonalInsightCard({
    super.key,
    required this.recommendation,
    required this.isLoading,
    required this.learningState,
  });

  @override
  State<PersonalInsightCard> createState() => _PersonalInsightCardState();
}

class _PersonalInsightCardState extends State<PersonalInsightCard> {
  bool _saving = false;
  String? _pendingAction;
  String? _feedback;
  bool _isEvidenceExpanded = false;

  bool get _evidenceExpanded => _isEvidenceExpanded == true;

  @override
  void initState() {
    super.initState();
    _isEvidenceExpanded = false;
    _saving = false;
    _loadFeedback();
  }

  @override
  void didUpdateWidget(covariant PersonalInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendation?.metadata['content_id'] !=
        widget.recommendation?.metadata['content_id']) {
      _feedback = null;
      _loadFeedback();
    }
  }

  Future<void> _loadFeedback() async {
    final item = widget.recommendation;
    if (item == null) return;
    final value = await AdaptiveNudgeApi.readNudgeFeedbackStatus(item);
    if (mounted && identical(item, widget.recommendation)) {
      setState(() => _feedback = value);
    }
  }

  Future<void> _respond(String value) async {
    if (_saving || widget.recommendation == null) return;
    setState(() {
      _saving = true;
      _pendingAction = value;
    });
    try {
      await WellnessContentApi.respond(widget.recommendation!.toJson(), value);
      if (mounted) {
        setState(() => _feedback = value == 'like' ? 'accepted' : 'dismissed');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(
              'Unable to save your response. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _pendingAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.recommendation;
    final evidence = item?.metadata['evidence']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const purple = Color(0xFF8B5CF6);

    return WellnessContentExposure(
      content: item?.toJson(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1B33).withValues(alpha: 0.92),
                    pageSurfaceColor(context),
                  ]
                : [
                    const Color(0xFFFAF7FF),
                    pageSurfaceColor(context),
                  ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? purple.withValues(alpha: 0.28)
                : purple.withValues(alpha: 0.20),
            width: 1.2,
          ),
          boxShadow: [
            ...pageCardShadow(context),
            BoxShadow(
              color: purple.withValues(alpha: isDark ? 0.16 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.isLoading && item == null
            ? const AppSkeletonRows(count: 2, showLeading: true)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge and title
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: purple.withValues(alpha: isDark ? 0.24 : 0.12),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: purple.withValues(
                              alpha: isDark ? 0.38 : 0.24,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: purple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LocalizedText(
                          'Personal insight',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                            color: pagePrimaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.learningState?.isVisible == true) ...[
                    const SizedBox(height: 10),
                    FirstWeekLearningPill(
                      state: widget.learningState!,
                      message: widget.learningState!.aiInsightNote,
                      maxLines: null,
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Headline
                  LocalizedText(
                    item?.title ?? 'Your picture is still taking shape',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                      letterSpacing: -0.3,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Body narrative
                  LocalizedText(
                    item?.message ??
                        'A few check-ins will help us notice your personal patterns.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.48,
                      fontWeight: FontWeight.w500,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),

                  // Modern collapsible evidence section
                  if (evidence.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _CollapsibleEvidenceTile(
                      evidence: evidence,
                      isExpanded: _evidenceExpanded,
                      accentColor: purple,
                      onToggle: () {
                        setState(() {
                          _isEvidenceExpanded = !_evidenceExpanded;
                        });
                      },
                    ),
                  ],

                  if (item != null) ...[
                    ContentFreshnessNote(metadata: item.metadata),
                    const SizedBox(height: 16),

                    // Modern feedback bar
                    Row(
                      children: [
                        _ModernFeedbackButton(
                          tooltip: 'Helpful',
                          icon: Icons.thumb_up_outlined,
                          selectedIcon: Icons.thumb_up,
                          isSelected: _feedback == 'accepted',
                          isBusy: _saving && _pendingAction == 'like',
                          activeColor: const Color(0xFF10B981),
                          onTap: _saving || _feedback == 'accepted'
                              ? null
                              : () => _respond('like'),
                        ),
                        const SizedBox(width: 8),
                        _ModernFeedbackButton(
                          tooltip: 'Not helpful',
                          icon: Icons.thumb_down_outlined,
                          selectedIcon: Icons.thumb_down,
                          isSelected: _feedback == 'dismissed',
                          isBusy: _saving && _pendingAction == 'dislike',
                          activeColor: const Color(0xFFEF4444),
                          onTap: _saving || _feedback == 'dismissed'
                              ? null
                              : () => _respond('dislike'),
                        ),
                        if (_feedback != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 220),
                              opacity: 1.0,
                              child: LocalizedText(
                                _feedback == 'accepted'
                                    ? 'Glad this helps!'
                                    : 'Feedback noted.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: pageSecondaryTextColor(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CollapsibleEvidenceTile extends StatelessWidget {
  final String evidence;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color accentColor;

  const _CollapsibleEvidenceTile({
    required this.evidence,
    this.isExpanded = false,
    required this.onToggle,
    this.accentColor = const Color(0xFF8B5CF6),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expanded = isExpanded == true;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.08)
            : const Color(0xFFF9F7FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? accentColor.withValues(alpha: 0.20)
              : accentColor.withValues(alpha: 0.14),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: accentColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: const LocalizedText(
                        'What this is based on',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: LocalizedText(
                            evidence,
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernFeedbackButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final bool isBusy;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ModernFeedbackButton({
    required this.tooltip,
    required this.icon,
    required this.selectedIcon,
    this.isSelected = false,
    this.isBusy = false,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = isSelected == true;
    final busy = isBusy == true;
    final enabled = onTap != null && !busy;

    final foreground = selected
        ? activeColor
        : (isDark
            ? Colors.white.withValues(alpha: 0.75)
            : const Color(0xFF5E7286));

    final background = selected
        ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F8));

    final border = selected
        ? activeColor.withValues(alpha: isDark ? 0.50 : 0.35)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2EAF0));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 36,
      width: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Center(
        child: IconButton(
          tooltip: tooltip.localizedCopy(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: enabled ? onTap : null,
          icon: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: activeColor,
                  ),
                )
              : Icon(
                  selected ? selectedIcon : icon,
                  size: 17,
                  color: foreground,
                ),
        ),
      ),
    );
  }
}
