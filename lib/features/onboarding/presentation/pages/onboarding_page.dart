import 'package:flutter/material.dart';

import '../../../../app/main_navigation.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../data/onboarding_api.dart';
import '../../models/onboarding_question.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/likert_question.dart';
import '../../widgets/onboarding_card.dart';

part 'onboarding_page_widgets.dart';

class OnboardingPage extends StatefulWidget {
  final int userId;

  const OnboardingPage({super.key, required this.userId});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _roles = [
    'Student',
    'Working Professional',
    'Freelancer',
    'Unemployed',
    'Other',
  ];
  static const _lifestyles = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Active',
    'Very Active',
  ];
  static const _wellnessGoals = [
    'Reduce stress',
    'Improve sleep',
    'Be more active',
    'Improve focus',
    'Build healthier habits',
    'Manage burnout',
  ];
  static const _exerciseGoalOptions = [
    '0 days',
    '1–2 days',
    '3–4 days',
    '5+ days',
  ];
  static const _workloadScale = [
    LikertOption(value: 1, label: 'Very Light'),
    LikertOption(value: 2, label: 'Light'),
    LikertOption(value: 3, label: 'Moderate'),
    LikertOption(value: 4, label: 'Heavy'),
    LikertOption(value: 5, label: 'Very Heavy'),
  ];
  static const _extraResponsibilityScale = [
    LikertOption(value: 1, label: 'Not demanding'),
    LikertOption(value: 2, label: 'Slightly demanding'),
    LikertOption(value: 3, label: 'Moderately demanding'),
    LikertOption(value: 4, label: 'Very demanding'),
    LikertOption(value: 5, label: 'Extremely demanding'),
  ];
  static const _burnoutScale = [
    LikertOption(value: 1, label: 'Never'),
    LikertOption(value: 2, label: 'Rarely'),
    LikertOption(value: 3, label: 'Sometimes'),
    LikertOption(value: 4, label: 'Often'),
    LikertOption(value: 5, label: 'Always'),
  ];
  static const _burnoutSections = [
    BurnoutSection(
      title: '😵 Emotional Exhaustion',
      category: 'emotional_exhaustion',
      questions: [
        BurnoutQuestion(
          questionKey: 'ee_01',
          questionText:
              'I feel emotionally drained by my daily responsibilities.',
          category: 'emotional_exhaustion',
        ),
        BurnoutQuestion(
          questionKey: 'ee_02',
          questionText: 'I feel tired even before starting my day.',
          category: 'emotional_exhaustion',
        ),
        BurnoutQuestion(
          questionKey: 'ee_03',
          questionText: 'I feel overwhelmed by my tasks.',
          category: 'emotional_exhaustion',
        ),
        BurnoutQuestion(
          questionKey: 'ee_04',
          questionText: 'I feel fatigued most of the time.',
          category: 'emotional_exhaustion',
        ),
        BurnoutQuestion(
          questionKey: 'ee_05',
          questionText: 'I feel I have no energy left at the end of the day.',
          category: 'emotional_exhaustion',
        ),
      ],
    ),
    BurnoutSection(
      title: '🧊 Detachment',
      category: 'depersonalization',
      questions: [
        BurnoutQuestion(
          questionKey: 'dp_01',
          questionText: 'I feel detached from my responsibilities.',
          category: 'depersonalization',
        ),
        BurnoutQuestion(
          questionKey: 'dp_02',
          questionText:
              'I have become less interested in things I used to enjoy.',
          category: 'depersonalization',
        ),
        BurnoutQuestion(
          questionKey: 'dp_03',
          questionText: 'I feel indifferent toward my tasks.',
          category: 'depersonalization',
        ),
        BurnoutQuestion(
          questionKey: 'dp_04',
          questionText: 'I feel less emotionally connected to others.',
          category: 'depersonalization',
        ),
        BurnoutQuestion(
          questionKey: 'dp_05',
          questionText:
              'I sometimes feel like I’m just going through the motions.',
          category: 'depersonalization',
        ),
      ],
    ),
    BurnoutSection(
      title: '🏆 Personal Accomplishment',
      category: 'personal_accomplishment',
      questions: [
        BurnoutQuestion(
          questionKey: 'pa_01',
          questionText: 'I feel productive in my daily life.',
          category: 'personal_accomplishment',
          isReverseScored: true,
        ),
        BurnoutQuestion(
          questionKey: 'pa_02',
          questionText: 'I feel I am achieving meaningful results.',
          category: 'personal_accomplishment',
          isReverseScored: true,
        ),
        BurnoutQuestion(
          questionKey: 'pa_03',
          questionText: 'I feel confident handling my responsibilities.',
          category: 'personal_accomplishment',
          isReverseScored: true,
        ),
        BurnoutQuestion(
          questionKey: 'pa_04',
          questionText: 'I feel motivated to accomplish my goals.',
          category: 'personal_accomplishment',
          isReverseScored: true,
        ),
        BurnoutQuestion(
          questionKey: 'pa_05',
          questionText: 'I feel satisfied with what I achieve each day.',
          category: 'personal_accomplishment',
          isReverseScored: true,
        ),
      ],
    ),
  ];

  final PageController _pageController = PageController();
  final Map<String, int> _burnoutAnswers = {};

  int _currentStep = 0;
  bool _isSaving = false;

  String? _role;
  String? _lifestyleType;
  String? _wellnessGoal;
  TimeOfDay? _usualSleepTime;
  TimeOfDay? _usualWakeTime;
  String? _exerciseGoalDays;
  int? _workloadLevel;
  bool? _hasExtraResponsibilities;
  int? _extraResponsibilityLevel;

  List<_OnboardingStep> get _steps {
    return [
      _OnboardingStep(
        sectionTitle: '👤 About You',
        title: 'What best describes you?',
        isComplete: () => _role != null,
        builder: (context) => _buildChoicePage(
          context,
          question: const OnboardingQuestion(
            title: 'What best describes you?',
            field: 'role',
            options: _roles,
          ),
          value: _role,
          onChanged: (value) => setState(() => _role = value),
        ),
      ),
      _OnboardingStep(
        sectionTitle: '👤 About You',
        title: 'How would you describe your lifestyle?',
        isComplete: () => _lifestyleType != null,
        builder: (context) => _buildChoicePage(
          context,
          question: const OnboardingQuestion(
            title: 'How would you describe your lifestyle?',
            field: 'lifestyle_type',
            options: _lifestyles,
          ),
          value: _lifestyleType,
          onChanged: (value) => setState(() => _lifestyleType = value),
        ),
      ),
      _OnboardingStep(
        sectionTitle: '👤 About You',
        title: 'What is your main wellness goal?',
        isComplete: () => _wellnessGoal != null,
        builder: (context) => _buildChoicePage(
          context,
          question: const OnboardingQuestion(
            title: 'What is your main wellness goal?',
            field: 'wellness_goal',
            options: _wellnessGoals,
          ),
          value: _wellnessGoal,
          onChanged: (value) => setState(() => _wellnessGoal = value),
        ),
      ),
      _OnboardingStep(
        sectionTitle: '🌙 Routine Defaults',
        title: 'What time do you usually sleep?',
        isComplete: () => _usualSleepTime != null,
        builder: (context) => _buildTimePage(
          context,
          title: 'What time do you usually sleep?',
          value: _usualSleepTime,
          fallback: const TimeOfDay(hour: 22, minute: 30),
          onChanged: (value) => setState(() => _usualSleepTime = value),
        ),
      ),
      _OnboardingStep(
        sectionTitle: '🌙 Routine Defaults',
        title: 'What time do you usually wake up?',
        isComplete: () => _usualWakeTime != null,
        builder: (context) => _buildTimePage(
          context,
          title: 'What time do you usually wake up?',
          value: _usualWakeTime,
          fallback: const TimeOfDay(hour: 6, minute: 30),
          onChanged: (value) => setState(() => _usualWakeTime = value),
        ),
      ),
      _OnboardingStep(
        sectionTitle: '🌙 Routine Defaults',
        title: 'How many days per week do you want to exercise?',
        isComplete: () => _exerciseGoalDays != null,
        builder: (context) => _buildChoicePage(
          context,
          question: const OnboardingQuestion(
            title: 'How many days per week do you want to exercise?',
            field: 'exercise_goal_days',
            options: _exerciseGoalOptions,
          ),
          value: _exerciseGoalDays,
          onChanged: (value) => setState(() => _exerciseGoalDays = value),
        ),
      ),
      _OnboardingStep(
        sectionTitle: '🌙 Routine Defaults',
        title: 'How heavy is your usual workload?',
        isComplete: () => _workloadLevel != null,
        builder: (context) => _buildLikertPage(
          context,
          title: 'How heavy is your usual workload?',
          helperText: _workloadHelperText,
          value: _workloadLevel,
          options: _workloadScale,
          onChanged: (value) => setState(() => _workloadLevel = value),
        ),
      ),
      _OnboardingStep(
        sectionTitle: '🌙 Routine Defaults',
        title: 'Do you usually have extra responsibilities?',
        isComplete: () => _hasExtraResponsibilities != null,
        builder: (context) => _buildYesNoPage(context),
      ),
      if (_hasExtraResponsibilities == true)
        _OnboardingStep(
          sectionTitle: '🌙 Routine Defaults',
          title: 'How demanding are those extra responsibilities?',
          isComplete: () => _extraResponsibilityLevel != null,
          builder: (context) => _buildLikertPage(
            context,
            title: 'How demanding are those extra responsibilities?',
            value: _extraResponsibilityLevel,
            options: _extraResponsibilityScale,
            onChanged: (value) =>
                setState(() => _extraResponsibilityLevel = value),
          ),
        ),
      ..._burnoutSections.map(
        (section) => _OnboardingStep(
          sectionTitle: '🔥 Burnout Baseline',
          title: section.title,
          isComplete: () => section.questions.every(
            (question) => _burnoutAnswers[question.questionKey] != null,
          ),
          builder: (context) => _buildBurnoutSectionPage(context, section),
        ),
      ),
    ];
  }

  String get _workloadHelperText {
    switch (_role) {
      case 'Student':
        return 'Include classes, assignments, projects, reviews, and school responsibilities.';
      case 'Working Professional':
        return 'Include job tasks, overtime, meetings, deadlines, and work pressure.';
      case 'Freelancer':
        return 'Include client work, inconsistent schedules, deadlines, and multitasking.';
      default:
        return 'Include household tasks, personal responsibilities, job searching, or other daily demands.';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSaving = true);

    final profile = {
      'role': _role,
      'lifestyle_type': _lifestyleType,
      'wellness_goal': _wellnessGoal,
      'usual_sleep_time': _formatTimeForApi(_usualSleepTime!),
      'usual_wake_time': _formatTimeForApi(_usualWakeTime!),
      'exercise_goal_days': _exerciseGoalDays,
      'workload_level': _workloadLevel,
      'has_extra_responsibilities': _hasExtraResponsibilities,
      'extra_responsibility_level': _hasExtraResponsibilities == true
          ? _extraResponsibilityLevel
          : null,
    };

    try {
      final response = await OnboardingApi.submitRequiredOnboarding(
        userId: widget.userId,
        profile: profile,
        burnoutAnswers: _buildBurnoutAnswerPayload(),
      );

      final savedProfile = Map<String, dynamic>.from(
        response['profile'] as Map? ?? profile,
      );
      final session = await UserSessionController.instance.load();
      await OnboardingService.saveDefaultsFromProfile(savedProfile);
      await UserSessionController.instance.updateOnboardingCompleted(true);
      await UserSessionController.instance.saveSupplementalProfile(
        gender: session.gender,
        userType: _role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your VitalySync baseline is ready 💙')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<Map<String, dynamic>> _buildBurnoutAnswerPayload() {
    final answers = <Map<String, dynamic>>[];

    for (final section in _burnoutSections) {
      for (final question in section.questions) {
        answers.add(question.toPayload(_burnoutAnswers[question.questionKey]!));
      }
    }

    return answers;
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleNext(List<_OnboardingStep> steps) {
    if (_currentStep == steps.length - 1) {
      _submitOnboarding();
      return;
    }

    _goToStep(_currentStep + 1);
  }

  String _formatTimeForApi(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final safeStepIndex = _currentStep.clamp(0, steps.length - 1).toInt();
    final currentStep = steps[safeStepIndex];
    final canContinue = currentStep.isComplete() && !_isSaving;
    final progress = (safeStepIndex + 1) / steps.length;

    return PopScope(
      canPop: false,
      child: Container(
        decoration: buildPageDecoration(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStep.sectionTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 9,
                                backgroundColor: pageBorderColor(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Step ${safeStepIndex + 1} of ${steps.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: steps[index].builder(context),
                      );
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
                          onPressed: _isSaving || _currentStep == 0
                              ? null
                              : () => _goToStep(_currentStep - 1),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: canContinue
                              ? () => _handleNext(steps)
                              : null,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentStep == steps.length - 1
                                      ? 'Finish Setup'
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

  Widget _buildChoicePage(
    BuildContext context, {
    required OnboardingQuestion question,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuestionTitle(question.title),
              if (question.helperText != null) ...[
                const SizedBox(height: 8),
                _HelperText(question.helperText!),
              ],
              const SizedBox(height: 22),
              ...question.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionTile(
                    label: option,
                    selected: value == option,
                    onTap: () => onChanged(option),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePage(
    BuildContext context, {
    required String title,
    required TimeOfDay? value,
    required TimeOfDay fallback,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuestionTitle(title),
              const SizedBox(height: 24),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: value ?? fallback,
                  );

                  if (picked != null) {
                    onChanged(picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF5FBF9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pageBorderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          value == null ? 'Choose time' : value.format(context),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: pagePrimaryTextColor(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: pageSecondaryTextColor(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLikertPage(
    BuildContext context, {
    required String title,
    String? helperText,
    required int? value,
    required List<LikertOption> options,
    required ValueChanged<int> onChanged,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LikertQuestion(
                question: title,
                value: value,
                options: options,
                onChanged: onChanged,
              ),
              if (helperText != null) ...[
                const SizedBox(height: 14),
                _HelperText(helperText),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _QuestionTitle(
                'Do you usually have extra responsibilities outside your main role?',
              ),
              const SizedBox(height: 22),
              _OptionTile(
                label: 'Yes',
                selected: _hasExtraResponsibilities == true,
                onTap: () => setState(() => _hasExtraResponsibilities = true),
              ),
              const SizedBox(height: 12),
              _OptionTile(
                label: 'No',
                selected: _hasExtraResponsibilities == false,
                onTap: () => setState(() {
                  _hasExtraResponsibilities = false;
                  _extraResponsibilityLevel = null;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBurnoutSectionPage(
    BuildContext context,
    BurnoutSection section,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuestionTitle(section.title),
              const SizedBox(height: 8),
              const _HelperText('Use 1 for Never and 5 for Always.'),
              const SizedBox(height: 22),
              ...section.questions.map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: LikertQuestion(
                    question: question.questionText,
                    value: _burnoutAnswers[question.questionKey],
                    options: _burnoutScale,
                    onChanged: (value) => setState(
                      () => _burnoutAnswers[question.questionKey] = value,
                    ),
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
