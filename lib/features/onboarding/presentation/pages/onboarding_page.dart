import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/main_navigation.dart';
import '../../../../shared/goals/user_goals.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/animated_gradient_background.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../tutorial/services/core_tutorial_service.dart';
import '../../data/burnout_baseline_questions.dart';
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
  static const _aboutAnimationPath =
      'assets/animations/onboarding_profile.json';
  static const _routineAnimationPath =
      'assets/animations/onboarding_yoga_carpet.json';
  static const _burnoutAnimationPath =
      'assets/animations/onboarding_heart.json';

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
  static const _lifestyleDescriptions = {
    'Sedentary': 'Mostly sitting with little planned physical activity.',
    'Lightly Active': 'Light walking or movement during the day.',
    'Moderately Active':
        'Regular exercise or active routines a few days weekly.',
    'Active': 'Frequent exercise or physically active work most days.',
    'Very Active':
        'Intense exercise, sports, or heavy activity nearly every day.',
  };
  static const _exerciseGoalOptions = [
    '0 days',
    '1-2 days',
    '3-4 days',
    '5+ days',
  ];
  static const _workloadScale = [
    LikertOption(value: 1, label: 'Very light'),
    LikertOption(value: 2, label: 'Light'),
    LikertOption(value: 3, label: 'Moderate'),
    LikertOption(value: 4, label: 'Heavy'),
    LikertOption(value: 5, label: 'Very heavy'),
  ];
  static const _extraResponsibilityScale = [
    LikertOption(value: 1, label: 'Not demanding'),
    LikertOption(value: 2, label: 'Slightly demanding'),
    LikertOption(value: 3, label: 'Moderately demanding'),
    LikertOption(value: 4, label: 'Very demanding'),
    LikertOption(value: 5, label: 'Extremely demanding'),
  ];
  static const _burnoutScale = kBurnoutBaselineScale;
  static const _burnoutSections = kBurnoutBaselineSections;
  static const double _heightMinCm = 100;
  static const double _heightMaxCm = 250;
  static const double _weightMinKg = 20;
  static const double _weightMaxKg = 500;

  final PageController _pageController = PageController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final Map<String, int> _burnoutAnswers = {};

  int _currentStep = 0;
  bool _isSaving = false;

  String? _role;
  String? _lifestyleType;
  final List<String> _wellnessGoals = [];
  TimeOfDay? _usualSleepTime;
  TimeOfDay? _usualWakeTime;
  String? _exerciseGoalDays;
  int? _workloadLevel;
  bool? _hasExtraResponsibilities;
  int? _extraResponsibilityLevel;

  List<_OnboardingStep> get _steps {
    return [
      _OnboardingStep(
        sectionTitle: '\u{1F464} About you',
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
        sectionTitle: '\u{1F464} About you',
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
          descriptionForOption: (option) => _lifestyleDescriptions[option],
        ),
      ),
      _OnboardingStep(
        sectionTitle: '\u{1F464} About you',
        title: 'Which wellness goals matter most to you?',
        isComplete: () => _wellnessGoals.isNotEmpty,
        builder: (context) => _buildMultiChoicePage(
          context,
          question: const OnboardingQuestion(
            title: 'Which wellness goals matter most to you?',
            field: 'wellness_goal',
            options: kWellnessGoalOptions,
          ),
          values: _wellnessGoals,
          onChanged: _toggleWellnessGoal,
        ),
      ),
      _OnboardingStep(
        sectionTitle: '\u{1F464} About you',
        title: 'What are your height and weight?',
        isComplete: _bodyMetricsComplete,
        builder: (context) => _buildBodyMetricsPage(context),
      ),
      _OnboardingStep(
        sectionTitle: '\u{1F319} Routine defaults',
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
        sectionTitle: '\u{1F319} Routine defaults',
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
        sectionTitle: '\u{1F319} Routine defaults',
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
        sectionTitle: '\u{1F319} Routine defaults',
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
        sectionTitle: '\u{1F319} Routine defaults',
        title: 'Do you usually have extra responsibilities?',
        isComplete: () => _hasExtraResponsibilities != null,
        builder: (context) => _buildYesNoPage(context),
      ),
      if (_hasExtraResponsibilities == true)
        _OnboardingStep(
          sectionTitle: '\u{1F319} Routine defaults',
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
          sectionTitle: '\u{1F525} Burnout baseline',
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
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSaving = true);

    final profile = {
      'role': _role,
      'lifestyle_type': _lifestyleType,
      'wellness_goal': _wellnessGoals.join(', '),
      'wellness_goals': _wellnessGoals,
      'height_cm': _heightCm,
      'weight_kg': _weightKg,
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
      await CoreTutorialService.instance.markPendingForUser(widget.userId);
      await _refreshGoalsAfterOnboarding();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your VitalySync baseline is ready \u{1F499}'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigation(
            tutorialUserId: widget.userId,
            showTutorialOnStart: true,
          ),
        ),
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

  Future<void> _refreshGoalsAfterOnboarding() async {
    await UserGoalsService.fetch(userId: widget.userId);
    UserGoalsService.refreshSignal.value++;
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
    if (step < 0 || step >= _steps.length) return;

    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 420),
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

  void _toggleWellnessGoal(String goal) {
    setState(() {
      if (_wellnessGoals.contains(goal)) {
        _wellnessGoals.remove(goal);
      } else {
        _wellnessGoals.add(goal);
      }
      _wellnessGoals.sort(
        (a, b) => kWellnessGoalOptions
            .indexOf(a)
            .compareTo(kWellnessGoalOptions.indexOf(b)),
      );
    });
  }

  String _formatTimeForApi(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _iconForCurrentStep(_OnboardingStep step) {
    if (step.sectionTitle.contains('About')) {
      return Icons.person_rounded;
    }
    if (step.sectionTitle.contains('Routine')) {
      return Icons.nights_stay_rounded;
    }
    return Icons.local_fire_department_rounded;
  }

  String _animationForCurrentStep(_OnboardingStep step) {
    if (step.sectionTitle.contains('About')) {
      return _aboutAnimationPath;
    }
    if (step.sectionTitle.contains('Routine')) {
      return _routineAnimationPath;
    }
    return _burnoutAnimationPath;
  }

  IconData _iconForQuestion(String field) {
    switch (field) {
      case 'role':
        return Icons.badge_rounded;
      case 'lifestyle_type':
        return Icons.directions_walk_rounded;
      case 'wellness_goal':
        return Icons.favorite_rounded;
      case 'body_metrics':
        return Icons.monitor_weight_rounded;
      case 'exercise_goal_days':
        return Icons.fitness_center_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  IconData _iconForOption(String option) {
    switch (option) {
      case 'Student':
        return Icons.school_rounded;
      case 'Working Professional':
        return Icons.work_rounded;
      case 'Freelancer':
        return Icons.laptop_mac_rounded;
      case 'Unemployed':
        return Icons.home_rounded;
      case 'Other':
        return Icons.more_horiz_rounded;
      case 'Sedentary':
        return Icons.chair_rounded;
      case 'Lightly Active':
        return Icons.directions_walk_rounded;
      case 'Moderately Active':
        return Icons.directions_run_rounded;
      case 'Active':
        return Icons.bolt_rounded;
      case 'Very Active':
        return Icons.rocket_launch_rounded;
      case 'Reduce stress':
        return Icons.spa_rounded;
      case 'Improve sleep':
        return Icons.bedtime_rounded;
      case 'Be more active':
        return Icons.directions_bike_rounded;
      case 'Improve focus':
        return Icons.center_focus_strong_rounded;
      case 'Build healthier habits':
        return Icons.eco_rounded;
      case 'Manage burnout':
        return Icons.local_fire_department_rounded;
      case '0 days':
        return Icons.event_busy_rounded;
      case '5+ days':
        return Icons.star_rounded;
      default:
        if (option.startsWith('1')) return Icons.looks_one_rounded;
        if (option.startsWith('3')) return Icons.filter_3_rounded;
        return Icons.check_circle_outline_rounded;
    }
  }

  String _sectionSubtitle(_OnboardingStep step) {
    if (step.sectionTitle.contains('About')) {
      return 'Personalize your wellness baseline.';
    }
    if (step.sectionTitle.contains('Routine')) {
      return 'Set defaults that make daily logs faster.';
    }
    return 'Answer honestly so insights start from your real rhythm.';
  }

  double? get _heightCm => _parseMetric(_heightController.text);

  double? get _weightKg => _parseMetric(_weightController.text);

  bool _bodyMetricsComplete() {
    return _metricInRange(_heightCm, _heightMinCm, _heightMaxCm) &&
        _metricInRange(_weightKg, _weightMinKg, _weightMaxKg);
  }

  double? _parseMetric(String value) {
    return double.tryParse(value.trim());
  }

  bool _metricInRange(double? value, double min, double max) {
    return value != null && value >= min && value <= max;
  }

  String? _metricError({
    required String? rawValue,
    required String label,
    required String unit,
    required double min,
    required double max,
  }) {
    final trimmed = rawValue?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your ${label.toLowerCase()}';
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Enter a valid ${label.toLowerCase()}';
    }

    if (!_metricInRange(parsed, min, max)) {
      return '$label must be between ${min.round()} and ${max.round()} $unit';
    }

    return null;
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
      child: AnimatedGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: _OnboardingHeader(
                    step: currentStep,
                    icon: _iconForCurrentStep(currentStep),
                    subtitle: _sectionSubtitle(currentStep),
                    animationPath: _animationForCurrentStep(currentStep),
                    progress: progress,
                    currentStep: safeStepIndex + 1,
                    totalSteps: steps.length,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      return _StepEntrance(
                        key: ValueKey('${steps[index].title}-$index'),
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
                      // Frosted glass Back button.
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: (_isSaving || _currentStep == 0)
                                    ? Colors.grey.withValues(alpha: 0.08)
                                    : pageSurfaceColor(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: pageBorderColor(context),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _isSaving || _currentStep == 0
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          _goToStep(_currentStep - 1);
                                        },
                                  child: SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        color: (_isSaving || _currentStep == 0)
                                            ? pageSecondaryTextColor(
                                                context,
                                              ).withValues(alpha: 0.4)
                                            : pagePrimaryTextColor(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Gradient Next / Finish button.
                      Expanded(
                        flex: 2,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          scale: canContinue ? 1.0 : 0.97,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: canContinue ? 1.0 : 0.55,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: canContinue
                                      ? () {
                                          HapticFeedback.mediumImpact();
                                          _handleNext(steps);
                                        }
                                      : null,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          const Color(0xFF56CCF2),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: canContinue
                                          ? [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: SizedBox(
                                      height: 52,
                                      child: Center(
                                        child: _isSaving
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                child: Row(
                                                  key: ValueKey(
                                                    _currentStep ==
                                                        steps.length - 1,
                                                  ),
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _currentStep ==
                                                              steps.length - 1
                                                          ? 'Finish setup'
                                                          : 'Next',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      _currentStep ==
                                                              steps.length - 1
                                                          ? Icons.check_rounded
                                                          : Icons
                                                              .arrow_forward_rounded,
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
    String? Function(String option)? descriptionForOption,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PromptBadge(
                icon: _iconForQuestion(question.field),
                label: question.field.replaceAll('_', ' '),
              ),
              const SizedBox(height: 14),
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
                    description: descriptionForOption?.call(option),
                    icon: _iconForOption(option),
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

  Widget _buildMultiChoicePage(
    BuildContext context, {
    required OnboardingQuestion question,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PromptBadge(
                icon: _iconForQuestion(question.field),
                label: question.field.replaceAll('_', ' '),
              ),
              const SizedBox(height: 14),
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
                    icon: _iconForOption(option),
                    selected: values.contains(option),
                    multiSelect: true,
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

  Widget _buildBodyMetricsPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        OnboardingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PromptBadge(
                icon: _iconForQuestion('body_metrics'),
                label: 'body metrics',
              ),
              const SizedBox(height: 14),
              const _QuestionTitle('What are your height and weight?'),
              const SizedBox(height: 8),
              const _HelperText('Approximate values are okay.'),
              const SizedBox(height: 22),
              _MetricInput(
                key: const ValueKey('onboarding-height-field'),
                controller: _heightController,
                label: 'Height',
                suffix: 'cm',
                icon: Icons.height_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) => _metricError(
                  rawValue: value,
                  label: 'Height',
                  unit: 'cm',
                  min: _heightMinCm,
                  max: _heightMaxCm,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 14),
              _MetricInput(
                key: const ValueKey('onboarding-weight-field'),
                controller: _weightController,
                label: 'Weight',
                suffix: 'kg',
                icon: Icons.monitor_weight_rounded,
                textInputAction: TextInputAction.done,
                validator: (value) => _metricError(
                  rawValue: value,
                  label: 'Weight',
                  unit: 'kg',
                  min: _weightMinKg,
                  max: _weightMaxKg,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
              const _PromptBadge(
                icon: Icons.schedule_rounded,
                label: 'routine time',
              ),
              const SizedBox(height: 14),
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
                      _AnimatedIconBadge(
                        Icons.schedule_rounded,
                        selected: value != null,
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
              const _PromptBadge(
                icon: Icons.tune_rounded,
                label: 'baseline scale',
              ),
              const SizedBox(height: 14),
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
              const _PromptBadge(
                icon: Icons.task_alt_rounded,
                label: 'responsibilities',
              ),
              const SizedBox(height: 14),
              const _QuestionTitle(
                'Do you usually have extra responsibilities outside your main role?',
              ),
              const SizedBox(height: 22),
              _OptionTile(
                label: 'Yes',
                icon: Icons.check_rounded,
                selected: _hasExtraResponsibilities == true,
                onTap: () => setState(() => _hasExtraResponsibilities = true),
              ),
              const SizedBox(height: 12),
              _OptionTile(
                label: 'No',
                icon: Icons.close_rounded,
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
              const _PromptBadge(
                icon: Icons.local_fire_department_rounded,
                label: 'burnout baseline',
              ),
              const SizedBox(height: 14),
              _QuestionTitle(section.title),
              const SizedBox(height: 8),
              const _HelperText('Use 1 for never and 5 for always.'),
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
