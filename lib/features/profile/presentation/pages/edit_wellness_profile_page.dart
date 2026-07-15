import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';

typedef EditWellnessProfileSaveCallback =
    Future<bool> Function({
      required String role,
      required String lifestyleType,
      required String workIntensity,
      required String sleepSchedule,
    });

class EditWellnessProfilePage extends StatefulWidget {
  const EditWellnessProfilePage({
    super.key,
    required this.initialRole,
    required this.initialLifestyle,
    required this.initialWorkIntensity,
    required this.initialSleepSchedule,
    required this.onSave,
  });

  final String? initialRole;
  final String initialLifestyle;
  final String initialWorkIntensity;
  final String initialSleepSchedule;
  final EditWellnessProfileSaveCallback onSave;

  @override
  State<EditWellnessProfilePage> createState() =>
      _EditWellnessProfilePageState();
}

class _EditWellnessProfilePageState extends State<EditWellnessProfilePage> {
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
  late final TextEditingController _sleepController;
  late String? _selectedRole;
  late String _selectedLifestyle;
  late String _selectedIntensity;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _sleepController = TextEditingController(text: widget.initialSleepSchedule);
    _selectedRole = widget.initialRole;
    _selectedLifestyle = widget.initialLifestyle;
    _selectedIntensity = widget.initialWorkIntensity;
  }

  @override
  void dispose() {
    _sleepController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) {
      await ValidationDialog.show(
        context,
        title: 'Check wellness details',
        message: 'Fix the highlighted fields before saving changes.',
        type: ValidationDialogType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final didSave = await widget.onSave(
        role: _selectedRole!,
        lifestyleType: _selectedLifestyle,
        workIntensity: _selectedIntensity,
        sleepSchedule: _sleepController.text.trim(),
      );

      if (!mounted) return;

      if (didSave) {
        setState(() => _isSubmitting = false);
        await ValidationDialog.show(
          context,
          title: 'Wellness updated',
          message: 'Your wellness profile was saved successfully.',
          type: ValidationDialogType.success,
        );
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else {
        await ValidationDialog.show(
          context,
          title: 'Unable to save',
          message: 'Please check your wellness details and try again.',
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
            'Edit wellness',
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
            child: _EditWellnessCard(
              children: [
                _buildDropdownField(
                  label: 'Current role',
                  icon: Icons.work_outline_rounded,
                  value: _selectedRole,
                  items: _roleOptions,
                  onChanged: (value) => setState(() => _selectedRole = value),
                ),
                _buildDropdownField(
                  label: 'Lifestyle type',
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
                  label: 'Work intensity',
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
                  label: 'Sleep schedule',
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
                    label: Text(_isSubmitting ? 'Saving...' : 'Save changes'),
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
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(_sentenceCaseOption(item)),
              ),
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
    );
  }
}

String _sentenceCaseOption(String value) {
  final text = value.trim();
  if (text.length < 2) return text;
  return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
}

class _EditWellnessCard extends StatelessWidget {
  final List<Widget> children;

  const _EditWellnessCard({required this.children});

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
                child: Icon(Icons.spa_outlined, color: themePrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wellness profile',
                      style: TextStyle(
                        color: primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Update your baseline context',
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
