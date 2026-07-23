import 'package:flutter/material.dart';

import '../../../auth/data/email_validator.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../widgets/profile_avatar_image.dart';

typedef EditProfileSaveCallback =
    Future<bool> Function({
      required String username,
      required String email,
      required int? age,
      required String? gender,
      required String? userType,
    });

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.initialUsername,
    required this.initialEmail,
    required this.initialAge,
    required this.initialGender,
    required this.initialUserType,
    required this.onSave,
    this.userId,
    this.onEditAvatar,
  });

  final String initialUsername;
  final String initialEmail;
  final int? initialAge;
  final String? initialGender;
  final String? initialUserType;
  final EditProfileSaveCallback onSave;
  final int? userId;
  final VoidCallback? onEditAvatar;

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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;

  late String? _selectedGender;
  late String? _selectedUserType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
    _ageController = TextEditingController(
      text: widget.initialAge?.toString() ?? '',
    );
    _selectedGender = widget.initialGender;
    _selectedUserType = widget.initialUserType;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<bool> _validateSelections() async {
    if (_selectedGender == null || _selectedUserType == null) {
      await ValidationDialog.show(
        context,
        title: 'Missing profile details',
        message: 'Please select both gender and current role before saving.',
        type: ValidationDialogType.warning,
      );
      return false;
    }

    return true;
  }

  Future<void> _handleSave() async {
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid) {
      await ValidationDialog.show(
        context,
        title: 'Check your entries',
        message: 'Fix the highlighted fields before saving changes.',
        type: ValidationDialogType.error,
      );
      return;
    }

    if (!await _validateSelections()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final emailChanged =
          EmailValidator.normalize(widget.initialEmail) !=
          EmailValidator.normalize(_emailController.text);
      final didSave = await widget.onSave(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        userType: _selectedUserType,
      );

      if (!mounted) return;

      if (didSave) {
        setState(() => _isSubmitting = false);
        await ValidationDialog.show(
          context,
          title: 'Profile updated',
          message: emailChanged
              ? 'Your profile was updated. We sent a verification link to your new email. Open the email and tap the link to verify it.'
              : 'Your changes were saved successfully.',
          type: ValidationDialogType.success,
          duration: emailChanged
              ? const Duration(milliseconds: 3200)
              : const Duration(milliseconds: 1500),
        );
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else {
        await ValidationDialog.show(
          context,
          title: 'Unable to save',
          message: 'Please check your details and try again.',
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
            'Edit profile',
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
                if (widget.userId != null && widget.onEditAvatar != null) ...[
                  _SectionCard(
                    emoji: '\u{1F4F7}',
                    icon: Icons.account_circle_outlined,
                    title: 'Profile avatar',
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CurrentUserAvatar(
                              userId: widget.userId,
                              gender: _selectedGender,
                              userType: _selectedUserType,
                              size: 104,
                              semanticLabel: 'Current profile avatar',
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              key: const ValueKey('edit-profile-change-avatar'),
                              onPressed: _isSubmitting
                                  ? null
                                  : widget.onEditAvatar,
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text(
                                'Change avatar',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                _SectionCard(
                  emoji: '\u{1F464}',
                  icon: Icons.person_outline,
                  title: 'Account details',
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
                      validator: (value) => EmailValidator.validate(
                        value,
                        emptyMessage: 'Enter an email',
                      ),
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
                      label: 'Current role',
                      icon: Icons.work_outline_rounded,
                      value: _selectedUserType,
                      items: _roleOptions,
                      onChanged: (value) =>
                          setState(() => _selectedUserType = value),
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
                      _isSubmitting ? 'Saving...' : 'Save changes',
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}

String _sentenceCaseOption(String value) {
  final text = value.trim();
  if (text.length < 2) return text;
  return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
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
