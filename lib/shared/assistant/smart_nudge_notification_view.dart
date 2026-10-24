part of 'floating_smart_nudge_assistant.dart';

/// Opens the notification's saved nudge, even when the current suggestion changed.
class SmartNudgeNotificationView extends StatefulWidget {
  final String payload;
  const SmartNudgeNotificationView({super.key, required this.payload});
  @override
  State<SmartNudgeNotificationView> createState() =>
      _SmartNudgeNotificationViewState();
}

class _SmartNudgeNotificationViewState
    extends State<SmartNudgeNotificationView> {
  final _alternatives = NudgeAlternativeController();
  AdaptiveNudgeRecommendation? _item;
  bool _loading = true;
  bool _saving = false;
  String? _response;

  @override
  void initState() {
    super.initState();
    _alternatives.addListener(_changed);
    _load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final data = await SmartNudgeDeliveryService.instance.readNotification(
      widget.payload,
    );
    final item = data == null
        ? null
        : AdaptiveNudgeRecommendation.fromJson(data);
    final response = item == null
        ? null
        : await AdaptiveNudgeApi.readNudgeFeedbackStatus(item);
    if (!mounted) return;
    setState(() {
      _item = item;
      _response = response;
      _loading = false;
    });
  }

  Future<void> _respond(String value) async {
    final item = _item;
    if (item == null || _saving) return;
    setState(() => _saving = true);
    try {
      if (value == 'another_idea' || value == 'review_ideas') {
        await _alternatives.request<AdaptiveNudgeRecommendation>(
          metadata: item.metadata,
          reviewEarlier: value == 'review_ideas',
          save: () => AdaptiveNudgeApi.saveNudgeFeedback(
            recommendation: item,
            status: 'another_idea',
          ),
          fetch: (excluded, mode) => AdaptiveNudgeApi.anotherIdea(
            excludeActionIds: excluded,
            selectionMode: mode,
          ),
          replace: (next) {
            if (mounted) {
              setState(() {
                _item = next;
                _response = null;
              });
            }
          },
        );
      } else {
        await AdaptiveNudgeApi.saveNudgeFeedback(
          recommendation: item,
          status: value,
        );
        if (mounted && identical(item, _item)) {
          setState(() => _response = value);
        }
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
  void dispose() {
    _alternatives.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Smart nudge')),
    body: Container(
      decoration: buildPageDecoration(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loading)
            const AppSkeletonRows(count: 3, showLeading: true)
          else if (_item == null)
            const LocalizedText('This nudge is no longer available.')
          else
            WellnessContentExposure(
              content: _item!.toJson(),
              child: _SmartNudgeInsightCard(
                alternatives: _alternatives,
                emoji: '✨',
                fallbackMessage: '',
                primary: _item,
                firstWeekLearning: const FirstWeekLearningState.hidden(),
                isLoading: false,
                feedbackStatus: _response,
                isUpdatingFeedback: _saving,
                onLiked: null,
                onDisliked: null,
                onResponse: _respond,
              ),
            ),
        ],
      ),
    ),
  );
}
