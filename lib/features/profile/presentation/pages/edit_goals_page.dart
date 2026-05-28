import 'package:flutter/material.dart';

import '../../../../shared/goals/user_goals.dart';
import '../../../../shared/theme/app_page_style.dart';

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
  late final TextEditingController _wellnessController;
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
    _wellnessController = TextEditingController(text: goals.wellnessGoal);
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
    _wellnessController.dispose();
    _sleepController.dispose();
    _hydrationController.dispose();
    _activityController.dispose();
    _stepsController.dispose();
    _nutritionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final goals = UserGoalsSnapshot.defaults(
      wellnessGoal: _wellnessController.text.trim(),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Goals updated.')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update goals.')),
        );
      }
    } finally {
      if (mounted) {
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
            'Edit Goals',
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
                _buildTextField(
                  controller: _wellnessController,
                  label: 'Wellness Goal',
                  icon: Icons.flag_outlined,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    return text.isEmpty ? 'Enter a wellness goal' : null;
                  },
                ),
                _buildNumberField(
                  controller: _sleepController,
                  label: 'Sleep Goal',
                  icon: Icons.bedtime_outlined,
                  suffix: 'hours',
                  min: 1,
                  max: 24,
                ),
                _buildNumberField(
                  controller: _hydrationController,
                  label: 'Hydration Goal',
                  icon: Icons.water_drop_outlined,
                  suffix: 'L',
                  min: 0.25,
                  max: 20,
                ),
                _buildNumberField(
                  controller: _activityController,
                  label: 'Activity Goal',
                  icon: Icons.fitness_center_outlined,
                  suffix: 'days/week',
                  min: 0,
                  max: 7,
                  wholeNumber: true,
                ),
                _buildNumberField(
                  controller: _stepsController,
                  label: 'Daily Steps',
                  icon: Icons.directions_walk_rounded,
                  suffix: 'steps',
                  min: 1000,
                  max: 50000,
                  wholeNumber: true,
                ),
                _buildNumberField(
                  controller: _nutritionController,
                  label: 'Nutrition Goal',
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
                    label: Text(_isSubmitting ? 'Saving...' : 'Save Goals'),
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
                      'My Goals',
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
