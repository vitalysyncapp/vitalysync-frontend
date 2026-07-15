import 'package:flutter/material.dart';

import '../../../../shared/goals/user_goals.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';

typedef EditGoalsSaveCallback = Future<bool> Function(UserGoalsSnapshot goals);

class EditGoalsPage extends StatefulWidget {
  const EditGoalsPage({
    super.key,
    required this.initialGoals,
    required this.onSave,
  });

  final UserGoalsSnapshot initialGoals;
  final EditGoalsSaveCallback onSave;

  @override
  State<EditGoalsPage> createState() => _EditGoalsPageState();
}

class _EditGoalsPageState extends State<EditGoalsPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<String> _wellnessGoals;
  late final TextEditingController _sleepController;
  late final TextEditingController _hydrationController;
  late final TextEditingController _activityController;
  late final TextEditingController _stepsController;
  late final TextEditingController _nutritionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final goals = widget.initialGoals;
    _wellnessGoals = List<String>.from(goals.wellnessGoals);
    _sleepController = TextEditingController(
      text: _formatNumber(goals.sleepHours),
    );
    _hydrationController = TextEditingController(
      text: _formatNumber(goals.hydrationLiters),
    );
    _activityController = TextEditingController(
      text: goals.activityDaysPerWeek.toString(),
    );
    _stepsController = TextEditingController(text: goals.dailySteps.toString());
    _nutritionController = TextEditingController(
      text: goals.nutritionCalories.toString(),
    );
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _hydrationController.dispose();
    _activityController.dispose();
    _stepsController.dispose();
    _nutritionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_wellnessGoals.isEmpty) {
      await ValidationDialog.show(
        context,
        title: 'Check your goals',
        message: 'Choose at least one wellness goal before saving.',
        type: ValidationDialogType.error,
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      await ValidationDialog.show(
        context,
        title: 'Check your goals',
        message: 'Fix the highlighted fields before saving changes.',
        type: ValidationDialogType.error,
      );
      return;
    }

    final goals = UserGoalsSnapshot.defaults(
      wellnessGoals: _wellnessGoals,
      sleepHours: double.parse(_sleepController.text.trim()),
      hydrationLiters: double.parse(_hydrationController.text.trim()),
      activityDaysPerWeek: int.parse(_activityController.text.trim()),
      dailySteps: int.parse(_stepsController.text.trim()),
      nutritionCalories: int.parse(_nutritionController.text.trim()),
    );

    setState(() => _isSubmitting = true);
    try {
      final didSave = await widget.onSave(goals);
      if (!mounted) return;

      if (didSave) {
        setState(() => _isSubmitting = false);
        await ValidationDialog.show(
          context,
          title: 'Goals updated',
          message: 'Your wellness goals were saved successfully.',
          type: ValidationDialogType.success,
        );
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else {
        await ValidationDialog.show(
          context,
          title: 'Unable to save',
          message: 'Please check your goals and try again.',
          type: ValidationDialogType.error,
        );
      }
    } finally {
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
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
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: pagePrimaryTextColor(context),
            ),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
          title: Text(
            'Edit goals',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            pageBottomContentPadding(context),
          ),
          child: Form(
            key: _formKey,
            child: _GoalsEditorCard(
              children: [
                _buildWellnessGoalPicker(),
                _buildNumberField(
                  controller: _sleepController,
                  label: 'Sleep goal',
                  icon: Icons.bedtime_outlined,
                  suffix: 'hours',
                  min: 1,
                  max: 24,
                ),
                _buildNumberField(
                  controller: _hydrationController,
                  label: 'Hydration goal',
                  icon: Icons.water_drop_outlined,
                  suffix: 'L',
                  min: 0.25,
                  max: 20,
                ),
                _buildNumberField(
                  controller: _activityController,
                  label: 'Activity goal',
                  icon: Icons.fitness_center_outlined,
                  suffix: 'days/week',
                  min: 0,
                  max: 7,
                  wholeNumber: true,
                ),
                _buildNumberField(
                  controller: _stepsController,
                  label: 'Daily steps',
                  icon: Icons.directions_walk_rounded,
                  suffix: 'steps',
                  min: 1000,
                  max: 50000,
                  wholeNumber: true,
                ),
                _buildNumberField(
                  controller: _nutritionController,
                  label: 'Nutrition goal',
                  icon: Icons.local_dining_outlined,
                  suffix: 'kcal',
                  min: 800,
                  max: 6000,
                  wholeNumber: true,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSave,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save goals'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(
          color: pagePrimaryTextColor(context),
          fontWeight: FontWeight.w600,
        ),
        decoration: _fieldDecoration(label: label, icon: icon),
      ),
    );
  }

  Widget _buildWellnessGoalPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          for (final goal in kWellnessGoalOptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GoalChoiceTile(
                label: goal,
                icon: _iconForWellnessGoal(goal),
                selected: _wellnessGoals.contains(goal),
                onTap: () => _toggleWellnessGoal(goal),
              ),
            ),
        ],
      ),
    );
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

  IconData _iconForWellnessGoal(String goal) {
    switch (goal) {
      case 'Reduce stress':
        return Icons.spa_outlined;
      case 'Improve sleep':
        return Icons.bedtime_outlined;
      case 'Be more active':
        return Icons.directions_bike_rounded;
      case 'Improve focus':
        return Icons.center_focus_strong_rounded;
      case 'Build healthier habits':
        return Icons.eco_outlined;
      case 'Manage burnout':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
    required double min,
    required double max,
    bool wholeNumber = false,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      icon: icon,
      validator: (value) {
        final text = value?.trim() ?? '';
        final parsed = double.tryParse(text);
        if (parsed == null) {
          return 'Enter a valid number';
        }
        if (wholeNumber && parsed != parsed.roundToDouble()) {
          return 'Enter a whole number';
        }
        if (parsed < min || parsed > max) {
          return 'Enter $min-$max $suffix';
        }
        return null;
      },
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF8FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: pageBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _GoalChoiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GoalChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.12)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : pageBorderColor(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? primary
                    : primary.withValues(alpha: isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: selected ? primary : pageSecondaryTextColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsEditorCard extends StatelessWidget {
  final List<Widget> children;

  const _GoalsEditorCard({required this.children});

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: themePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.track_changes_rounded, color: themePrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My goals',
                      style: TextStyle(
                        color: primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Targets shared across VitalySync',
                      style: TextStyle(fontSize: 12.5, color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }

  return value.toStringAsFixed(1);
}
