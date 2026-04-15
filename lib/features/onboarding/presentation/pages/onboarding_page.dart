import 'package:flutter/material.dart';

import '../../../../app/main_navigation.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../data/onboarding_api.dart';

class OnboardingPage extends StatefulWidget {
  final int userId;
  final bool canSkip;

  const OnboardingPage({
    super.key,
    required this.userId,
    this.canSkip = true,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isSaving = false;

  final _roleController = TextEditingController();
  final _workHoursController = TextEditingController(text: '8');
  final _sleepHoursController = TextEditingController(text: '7.5');
  final _exerciseDaysController = TextEditingController(text: '3');

  final _preferredLogTimeController = TextEditingController(text: '20:30');
  final _wakeTimeController = TextEditingController(text: '06:30');
  final _sleepTimeController = TextEditingController(text: '22:30');
  final _workStartController = TextEditingController(text: '09:00');
  final _workEndController = TextEditingController(text: '18:00');
  final _reminderTimeController = TextEditingController(text: '20:00');

  String _activityLevel = 'Balanced';
  String _mealRegularness = 'Mostly Regular';
  String _preferredNudgeStyle = 'Gentle';
  String _primaryGoal = 'Reduce stress';

  double _stressLevel = 3;
  double _mentalDrainLevel = 3;
  double _focusDifficultyLevel = 3;
  double _overwhelmLevel = 3;
  double _recoveryLevel = 3;
  double _motivationLevel = 3;

  bool _prefersDailyReminder = true;
  bool _prefersHydrationReminder = true;
  bool _prefersExerciseReminder = true;
  bool _prefersSleepReminder = true;

  final Set<int> _busyDays = {1, 3, 5};

  @override
  void dispose() {
    _pageController.dispose();
    _roleController.dispose();
    _workHoursController.dispose();
    _sleepHoursController.dispose();
    _exerciseDaysController.dispose();
    _preferredLogTimeController.dispose();
    _wakeTimeController.dispose();
    _sleepTimeController.dispose();
    _workStartController.dispose();
    _workEndController.dispose();
    _reminderTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveAndFinish({required bool skipped}) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final onboardingPayload = <String, dynamic>{
        'role_type': _normalizedOrDefault(
          _roleController.text,
          skipped ? 'Skipped' : 'Student',
        ),
        'work_hours_per_day': int.tryParse(_workHoursController.text.trim()) ?? 8,
        'sleep_hours': double.tryParse(_sleepHoursController.text.trim()) ?? 7.5,
        'activity_level': _activityLevel,
        'exercise_days_per_week':
            int.tryParse(_exerciseDaysController.text.trim()) ?? 3,
        'meal_regularness': _mealRegularness,
        'stress_level': _stressLevel.round(),
        'mental_drain_level': _mentalDrainLevel.round(),
        'focus_difficulty_level': _focusDifficultyLevel.round(),
        'overwhelm_level': _overwhelmLevel.round(),
        'recovery_level': _recoveryLevel.round(),
        'motivation_level': _motivationLevel.round(),
        'skipped': skipped,
      };

      final preferencesPayload = <String, dynamic>{
        'preferred_log_time': _preferredLogTimeController.text.trim(),
        'default_wake_time': _wakeTimeController.text.trim(),
        'default_sleep_time': _sleepTimeController.text.trim(),
        'default_work_start': _workStartController.text.trim(),
        'default_work_end': _workEndController.text.trim(),
        'prefers_daily_reminder': _prefersDailyReminder,
        'reminder_time': _reminderTimeController.text.trim(),
        'prefers_hydration_reminder': _prefersHydrationReminder,
        'prefers_exercise_reminder': _prefersExerciseReminder,
        'prefers_sleep_reminder': _prefersSleepReminder,
        'preferred_nudge_style': _preferredNudgeStyle,
        'primary_goal': _primaryGoal,
        'busy_days': _busyDays.toList()..sort(),
      };

      await OnboardingApi.upsertOnboarding(
        userId: widget.userId,
        onboarding: onboardingPayload,
      );
      await OnboardingApi.upsertPreferences(
        userId: widget.userId,
        preferences: preferencesPayload,
      );

      await UserSessionController.instance.updateOnboardingCompleted(true);
      await UserSessionController.instance.saveSupplementalProfile(
        userType: onboardingPayload['role_type'] as String?,
      );
      await AppPreferencesController.instance.syncNotificationPreferences(
        notificationsEnabled: _prefersDailyReminder,
        bedtimeReminderEnabled: _prefersSleepReminder,
        hydrationReminderEnabled: _prefersHydrationReminder,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            skipped
                ? 'Onboarding skipped for now. You can update preferences later.'
                : 'Onboarding saved successfully.',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save onboarding: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _normalizedOrDefault(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: pagePrimaryTextColor(context),
          automaticallyImplyLeading: false,
          title: Text(
            'Welcome to VitalySync',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
          actions: [
            if (widget.canSkip)
              TextButton(
                onPressed: _isSaving ? null : () => _saveAndFinish(skipped: true),
                child: const Text('Skip'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: List.generate(3, (index) {
                    final selected = index == _currentStep;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 8,
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : pageBorderColor(context),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildQuestionnaireStep(context),
                    _buildWellnessStep(context),
                    _buildPreferencesStep(context),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _goToStep(_currentStep - 1),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : _currentStep == 2
                                ? () => _saveAndFinish(skipped: false)
                                : () => _goToStep(_currentStep + 1),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_currentStep == 2 ? 'Finish Setup' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionnaireStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      children: [
        _buildIntroCard(
          context,
          title: 'Tell us about your routine',
          subtitle:
              'We will use this first-time setup to personalize reminders, defaults, and later wellness guidance.',
        ),
        const SizedBox(height: 16),
        _buildSurfaceCard(
          context,
          child: Column(
            children: [
              _buildTextField(
                context,
                controller: _roleController,
                label: 'Current Role',
                hint: 'Student, Working Professional, Freelancer...',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _workHoursController,
                label: 'Work Hours Per Day',
                hint: '8',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _sleepHoursController,
                label: 'Average Sleep Hours',
                hint: '7.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),
              _buildChoiceChips(
                context,
                label: 'Activity Level',
                selectedValue: _activityLevel,
                options: const ['Sedentary', 'Balanced', 'Active'],
                onSelected: (value) {
                  setState(() {
                    _activityLevel = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _exerciseDaysController,
                label: 'Exercise Days Per Week',
                hint: '3',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _buildChoiceChips(
                context,
                label: 'Meal Regularness',
                selectedValue: _mealRegularness,
                options: const [
                  'Very Irregular',
                  'Irregular',
                  'Mostly Regular',
                  'Very Regular',
                ],
                onSelected: (value) {
                  setState(() {
                    _mealRegularness = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      children: [
        _buildIntroCard(
          context,
          title: 'Check in on how things feel',
          subtitle:
              'These answers help establish your baseline so the app can start with better defaults.',
        ),
        const SizedBox(height: 16),
        _buildSurfaceCard(
          context,
          child: Column(
            children: [
              _buildSliderTile(
                context,
                label: 'Stress Level',
                value: _stressLevel,
                onChanged: (value) => setState(() => _stressLevel = value),
              ),
              _buildSliderTile(
                context,
                label: 'Mental Drain Level',
                value: _mentalDrainLevel,
                onChanged: (value) => setState(() => _mentalDrainLevel = value),
              ),
              _buildSliderTile(
                context,
                label: 'Focus Difficulty',
                value: _focusDifficultyLevel,
                onChanged: (value) =>
                    setState(() => _focusDifficultyLevel = value),
              ),
              _buildSliderTile(
                context,
                label: 'Overwhelm Level',
                value: _overwhelmLevel,
                onChanged: (value) => setState(() => _overwhelmLevel = value),
              ),
              _buildSliderTile(
                context,
                label: 'Recovery Level',
                value: _recoveryLevel,
                onChanged: (value) => setState(() => _recoveryLevel = value),
              ),
              _buildSliderTile(
                context,
                label: 'Motivation Level',
                value: _motivationLevel,
                onChanged: (value) => setState(() => _motivationLevel = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      children: [
        _buildIntroCard(
          context,
          title: 'Set your preferences',
          subtitle:
              'These can be updated later, but this gets your first reminders and default values ready.',
        ),
        const SizedBox(height: 16),
        _buildSurfaceCard(
          context,
          child: Column(
            children: [
              _buildTextField(
                context,
                controller: _preferredLogTimeController,
                label: 'Preferred Log Time',
                hint: '20:30',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _wakeTimeController,
                label: 'Default Wake Time',
                hint: '06:30',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _sleepTimeController,
                label: 'Default Sleep Time',
                hint: '22:30',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _workStartController,
                label: 'Default Work Start',
                hint: '09:00',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _workEndController,
                label: 'Default Work End',
                hint: '18:00',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                context,
                controller: _reminderTimeController,
                label: 'Reminder Time',
                hint: '20:00',
              ),
              const SizedBox(height: 14),
              _buildSwitchTile(
                context,
                title: 'Daily Reminder',
                value: _prefersDailyReminder,
                onChanged: (value) =>
                    setState(() => _prefersDailyReminder = value),
              ),
              _buildSwitchTile(
                context,
                title: 'Hydration Reminder',
                value: _prefersHydrationReminder,
                onChanged: (value) =>
                    setState(() => _prefersHydrationReminder = value),
              ),
              _buildSwitchTile(
                context,
                title: 'Exercise Reminder',
                value: _prefersExerciseReminder,
                onChanged: (value) =>
                    setState(() => _prefersExerciseReminder = value),
              ),
              _buildSwitchTile(
                context,
                title: 'Sleep Reminder',
                value: _prefersSleepReminder,
                onChanged: (value) =>
                    setState(() => _prefersSleepReminder = value),
              ),
              const SizedBox(height: 14),
              _buildChoiceChips(
                context,
                label: 'Preferred Nudge Style',
                selectedValue: _preferredNudgeStyle,
                options: const ['Gentle', 'Direct', 'Motivational', 'Data-Driven'],
                onSelected: (value) {
                  setState(() {
                    _preferredNudgeStyle = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _buildChoiceChips(
                context,
                label: 'Primary Goal',
                selectedValue: _primaryGoal,
                options: const [
                  'Reduce stress',
                  'Improve sleep',
                  'Build consistency',
                  'Eat better',
                  'Move more',
                ],
                onSelected: (value) {
                  setState(() {
                    _primaryGoal = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _buildBusyDaysPicker(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return _buildSurfaceCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              height: 1.5,
              color: pageSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildChoiceChips(
    BuildContext context, {
    required String label,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: pagePrimaryTextColor(context),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option),
              selected: selectedValue == option,
              onSelected: (_) => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.round()}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: pagePrimaryTextColor(context),
            ),
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: pagePrimaryTextColor(context),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildBusyDaysPicker(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Busy Days',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: pagePrimaryTextColor(context),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(labels.length, (index) {
            final selected = _busyDays.contains(index);
            return FilterChip(
              label: Text(labels[index]),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _busyDays.add(index);
                  } else {
                    _busyDays.remove(index);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }
}
