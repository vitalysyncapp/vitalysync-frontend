import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../adaptive/data/adaptive_nudge_api.dart';
import '../../../adaptive/data/wellness_content_api.dart';
import '../../../../shared/learning/first_week_learning_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';
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

  @override
  void initState() {
    super.initState();
    _saving = false;
    _loadFeedback();
  }

  @override
  void didUpdateWidget(covariant PersonalInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendation?.metadata['content_id'] !=
        widget.recommendation?.metadata['content_id']) {
      _feedback = null;
      _saving = false;
      _pendingAction = null;
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
    final item = widget.recommendation!;
    setState(() {
      _saving = true;
      _pendingAction = value;
    });
    try {
      await WellnessContentApi.respond(item.toJson(), value);
      if (mounted && identical(item, widget.recommendation)) {
        setState(() => _feedback = value == 'like' ? 'accepted' : 'dismissed');
      }
    } catch (_) {
      if (mounted && identical(item, widget.recommendation)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(
              'Unable to save your response. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && identical(item, widget.recommendation)) {
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
    final period = item?.metadata['period'] as Map?;
    final start = DateTime.tryParse('${period?['start_date']}');
    final end = DateTime.tryParse('${period?['end_date']}');
    final highlights = item?.metadata['highlights'];
    final mainFactor =
        highlights is List && highlights.isNotEmpty && highlights.first is Map
        ? '${(highlights.first as Map)['label'] ?? ''}'.trim()
        : '';
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
                : [const Color(0xFFFAF7FF), pageSurfaceColor(context)],
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
                          'Personal insights',
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
                  if (start != null && end != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(start)} – ${DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(end)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Body narrative
                  LocalizedText(
                    item?.message ??
                        'Log sleep, mood, movement or a meal to start building your wellness picture.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.48,
                      fontWeight: FontWeight.w500,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),
                  if (mainFactor.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    MainFactorLegend(factor: mainFactor, color: purple),
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
