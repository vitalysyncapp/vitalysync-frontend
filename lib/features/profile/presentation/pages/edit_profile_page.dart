import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

typedef EditProfileSaveCallback =
    Future<bool> Function({
      required String username,
      required String email,
      required int? age,
      required String? gender,
      required String? userType,
      required String lifestyleType,
      required String workIntensity,
      required String sleepSchedule,
      required String waterGoal,
      required String exerciseTarget,
    });

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.initialUsername,
    required this.initialEmail,
    required this.initialAge,
    required this.initialGender,
    required this.initialUserType,
    required this.initialLifestyle,
    required this.initialWorkIntensity,
    required this.initialSleepSchedule,
    required this.initialWaterGoal,
    required this.initialExerciseTarget,
    required this.onSave,
  });

  final String initialUsername;
  final String initialEmail;
  final int? initialAge;
  final String? initialGender;
  final String? initialUserType;
  final String initialLifestyle;
  final String initialWorkIntensity;
  final String initialSleepSchedule;
  final String initialWaterGoal;
  final String initialExerciseTarget;
  final EditProfileSaveCallback onSave;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _roleOptions = [
    'Student',
    'Working Professional',
    'Freelancer',
    'Unemployed',
    'Other',
  ];
  static const List<String> _lifestyleOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Active',
    'Very Active',
  ];
  static const List<String> _workIntensityOptions = ['Low', 'Medium', 'High'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _sleepController;
  late final TextEditingController _waterGoalController;
  late final TextEditingController _exerciseTargetController;

  late String? _selectedGender;
  late String? _selectedUserType;
  late String _selectedLifestyle;
  late String _selectedIntensity;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
    _ageController = TextEditingController(
      text: widget.initialAge?.toString() ?? '',
    );
    _sleepController = TextEditingController(text: widget.initialSleepSchedule);
    _waterGoalController = TextEditingController(text: widget.initialWaterGoal);
    _exerciseTargetController = TextEditingController(
      text: widget.initialExerciseTarget,
    );
    _selectedGender = widget.initialGender;
    _selectedUserType = widget.initialUserType;
    _selectedLifestyle = widget.initialLifestyle;
    _selectedIntensity = widget.initialWorkIntensity;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _sleepController.dispose();
    _waterGoalController.dispose();
    _exerciseTargetController.dispose();
    super.dispose();
  }

  Future<void> _showCenterNotice({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: pageSurfaceColor(context).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: pageBorderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pagePrimaryTextColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.35,
                      color: pageSecondaryTextColor(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _validateSelections() {
    if (_selectedGender == null || _selectedUserType == null) {
      _showCenterNotice(
        icon: Icons.info_outline_rounded,
        title: 'Missing profile details',
        message: 'Please select both gender and current role before saving.',
        color: const Color(0xFFF59E0B),
      );
      return false;
    }

    return true;
  }

  Future<void> _handleSave() async {
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid || !_validateSelections()) {
      if (formIsValid == false) {
        await _showCenterNotice(
          icon: Icons.error_outline_rounded,
          title: 'Check your entries',
          message: 'Fix the highlighted fields before saving changes.',
          color: const Color(0xFFEF4444),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final didSave = await widget.onSave(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        userType: _selectedUserType,
        lifestyleType: _selectedLifestyle,
        workIntensity: _selectedIntensity,
        sleepSchedule: _sleepController.text.trim(),
        waterGoal: _waterGoalController.text.trim(),
        exerciseTarget: _exerciseTargetController.text.trim(),
      );

      if (!mounted) return;

      if (didSave) {
        await _showCenterNotice(
          icon: Icons.check_circle_outline_rounded,
          title: 'Profile updated',
          message: 'Your changes were saved successfully.',
          color: const Color(0xFF16A34A),
        );
        await Future<void>.delayed(const Duration(milliseconds: 850));
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else {
        await _showCenterNotice(
          icon: Icons.error_outline_rounded,
          title: 'Unable to save',
          message: 'Please check your details and try again.',
          color: const Color(0xFFEF4444),
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
            'Edit Profile',
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
            child: Column(
              children: [
                _SectionCard(
                  emoji: '\u{1F464}',
                  icon: Icons.person_outline,
                  title: 'Account Details',
                  children: [
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email_rounded,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter a username';
                        if (text.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter an email';
                        if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(text)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final age = int.tryParse(text);
                        if (age == null) return 'Enter a valid age';
                        if (age < 13 || age > 120) {
                          return 'Age must be between 13 and 120';
                        }
                        return null;
                      },
                    ),
                    _buildDropdownField(
                      label: 'Gender',
                      icon: Icons.wc_rounded,
                      value: _selectedGender,
                      items: _genderOptions,
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                    _buildDropdownField(
                      label: 'Current Role',
                      icon: Icons.work_outline_rounded,
                      value: _selectedUserType,
                      items: _roleOptions,
                      onChanged: (value) =>
                          setState(() => _selectedUserType = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  emoji: '\u{1F33F}',
                  icon: Icons.spa_outlined,
                  title: 'Wellness Baseline',
                  children: [
                    _buildDropdownField(
                      label: 'Lifestyle Type',
                      icon: Icons.directions_walk_rounded,
                      value: _selectedLifestyle,
                      items: _lifestyleOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLifestyle = value);
                        }
                      },
                    ),
                    _buildDropdownField(
                      label: 'Work Intensity',
                      icon: Icons.speed_outlined,
                      value: _selectedIntensity,
                      items: _workIntensityOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedIntensity = value);
                        }
                      },
                    ),
                    _buildTextField(
                      controller: _sleepController,
                      label: 'Sleep Schedule',
                      icon: Icons.bedtime_outlined,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter a sleep schedule';
                        if (!RegExp(
                          r'^\d{1,2}:\d{2}\s*(AM|PM)\s*-\s*\d{1,2}:\d{2}\s*(AM|PM)$',
                          caseSensitive: false,
                        ).hasMatch(text)) {
                          return 'Use format like 10:30 PM - 6:30 AM';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _waterGoalController,
                      label: 'Daily Water Goal',
                      icon: Icons.water_drop_outlined,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter a water goal';
                        if (!RegExp(
                          r'^\d+(\.\d+)?\s*(L|ml)$',
                          caseSensitive: false,
                        ).hasMatch(text)) {
                          return 'Use format like 2.5 L or 2500 ml';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _exerciseTargetController,
                      label: 'Exercise Target',
                      icon: Icons.fitness_center_outlined,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter an exercise target';
                        if (!RegExp(r'\d+').hasMatch(text)) {
                          return 'Include a target number of days';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSave,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: pagePrimaryTextColor(context),
          fontWeight: FontWeight.w600,
        ),
        decoration: _fieldDecoration(label: label, icon: icon),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Select $label' : null,
        decoration: _fieldDecoration(label: label, icon: icon),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
      ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String emoji;
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.emoji,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final primary = pagePrimaryTextColor(context);
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: themePrimary, size: 22),
                    Positioned(
                      right: 3,
                      bottom: 1,
                      child: Text(emoji, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
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
