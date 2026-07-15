import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../../../onboarding/data/burnout_baseline_questions.dart';
import '../../../onboarding/models/onboarding_question.dart';
import '../../../onboarding/widgets/likert_question.dart';
import '../../../onboarding/widgets/onboarding_card.dart';

typedef RetakeBaselineSaveCallback =
    Future<bool> Function(List<Map<String, dynamic>> answers);

class RetakeBaselineQuestionnairePage extends StatefulWidget {
  const RetakeBaselineQuestionnairePage({
    super.key,
    required this.initialAnswers,
    required this.onSave,
  });

  final Map<String, int> initialAnswers;
  final RetakeBaselineSaveCallback onSave;

  @override
  State<RetakeBaselineQuestionnairePage> createState() =>
      _RetakeBaselineQuestionnairePageState();
}

class _RetakeBaselineQuestionnairePageState
    extends State<RetakeBaselineQuestionnairePage> {
  final PageController _pageController = PageController();
  late final Map<String, int> _answers;
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, int>.fromEntries(
      widget.initialAnswers.entries.where(
        (entry) => entry.value >= 1 && entry.value <= 5,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _sectionComplete(BurnoutSection section) {
    return section.questions.every(
      (question) => _answers[question.questionKey] != null,
    );
  }

  bool get _allComplete {
    return kBurnoutBaselineSections.every(_sectionComplete);
  }

  void _goToStep(int step) {
    if (step < 0 || step >= kBurnoutBaselineSections.length) return;

    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep < kBurnoutBaselineSections.length - 1) {
      _goToStep(_currentStep + 1);
      return;
    }

    if (!_allComplete) {
      await ValidationDialog.show(
        context,
        title: 'Complete baseline',
        message: 'Please answer every dimension question before saving.',
        type: ValidationDialogType.warning,
      );
      return;
    }

    await _save();
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);

    try {
      final saved = await widget.onSave(_buildPayload());
      if (!mounted) return;

      if (!saved) {
        await ValidationDialog.show(
          context,
          title: 'Unable to save',
          message: 'Please check your connection and try again.',
          type: ValidationDialogType.error,
        );
        return;
      }

      await ValidationDialog.show(
        context,
        title: 'Baseline updated',
        message: 'Your dimension baseline was saved successfully.',
        type: ValidationDialogType.success,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<Map<String, dynamic>> _buildPayload() {
    final payload = <Map<String, dynamic>>[];

    for (final section in kBurnoutBaselineSections) {
      for (final question in section.questions) {
        payload.add(question.toPayload(_answers[question.questionKey]!));
      }
    }

    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final currentSection = kBurnoutBaselineSections[_currentStep];
    final progress = (_currentStep + 1) / kBurnoutBaselineSections.length;
    final canContinue = _sectionComplete(currentSection) && !_isSubmitting;
    final isLast = _currentStep == kBurnoutBaselineSections.length - 1;

    return PopScope(
      canPop: !_isSubmitting,
      child: Container(
        decoration: buildPageDecoration(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: false,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: pagePrimaryTextColor(context),
              ),
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            ),
            title: Text(
              'Retake baseline',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: _RetakeBaselineHeader(
                    section: currentSection,
                    progress: progress,
                    currentStep: _currentStep + 1,
                    totalSteps: kBurnoutBaselineSections.length,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kBurnoutBaselineSections.length,
                    itemBuilder: (context, index) {
                      return _buildSectionPage(kBurnoutBaselineSections[index]);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    pageBottomContentPadding(context, extra: 18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting || _currentStep == 0
                              ? null
                              : () => _goToStep(_currentStep - 1),
                          child: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          key: const ValueKey('retake-baseline-primary-button'),
                          onPressed: canContinue ? _handleNext : null,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isLast
                                      ? Icons.save_outlined
                                      : Icons.arrow_forward_rounded,
                                ),
                          label: Text(
                            _isSubmitting
                                ? 'Saving...'
                                : isLast
                                ? 'Save baseline'
                                : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionPage(BurnoutSection section) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use 1 for never and 5 for always.',
                style: TextStyle(
                  height: 1.35,
                  fontSize: 13.5,
                  color: pageSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 22),
              ...section.questions.map(
                (question) => Padding(
                  key: ValueKey('baseline-${question.questionKey}'),
                  padding: const EdgeInsets.only(bottom: 22),
                  child: LikertQuestion(
                    question: question.questionText,
                    value: _answers[question.questionKey],
                    options: kBurnoutBaselineScale,
                    onChanged: (value) =>
                        setState(() => _answers[question.questionKey] = value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RetakeBaselineHeader extends StatelessWidget {
  const _RetakeBaselineHeader({
    required this.section,
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  final BurnoutSection section;
  final double progress;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final primary = pagePrimaryTextColor(context);
    final secondary = pageSecondaryTextColor(context);
    final themePrimary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6BFF), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: themePrimary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(themePrimary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$currentStep of $totalSteps',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: secondary,
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
