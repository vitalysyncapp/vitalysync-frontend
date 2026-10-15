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
  String? _feedback;
  @override
  void initState() {
    super.initState();
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
    setState(() => _saving = true);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.recommendation;
    final evidence = item?.metadata['evidence']?.toString() ?? '';
    return WellnessContentExposure(
      content: item?.toJson(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pageBorderColor(context)),
        ),
        child: widget.isLoading && item == null
            ? const AppSkeletonRows(count: 2, showLeading: true)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LocalizedText(
                          'Personal insight',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: pagePrimaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.learningState?.isVisible == true) ...[
                    const SizedBox(height: 8),
                    FirstWeekLearningPill(
                      state: widget.learningState!,
                      message: widget.learningState!.aiInsightNote,
                      maxLines: null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  LocalizedText(
                    item?.title ?? 'Your picture is still taking shape',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  LocalizedText(
                    item?.message ??
                        'A few check-ins will help us notice your personal patterns.',
                    style: TextStyle(
                      height: 1.4,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),
                  if (evidence.isNotEmpty)
                    Material(
                      type: MaterialType.transparency,
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: const LocalizedText(
                          'What this is based on',
                          style: TextStyle(fontSize: 12),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: LocalizedText(
                              evidence,
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item != null) ...[
                    ContentFreshnessNote(metadata: item.metadata),
                    Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Helpful',
                          onPressed: _saving ? null : () => _respond('like'),
                          icon: Icon(
                            _feedback == 'accepted'
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Not helpful',
                          onPressed: _saving ? null : () => _respond('dislike'),
                          icon: Icon(
                            _feedback == 'dismissed'
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                          ),
                        ),
                        if (_saving)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
