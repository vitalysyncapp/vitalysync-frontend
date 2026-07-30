import 'package:flutter/material.dart';

class NewPasswordFields extends StatefulWidget {
  const NewPasswordFields({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    this.enabled = true,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool enabled;

  @override
  State<NewPasswordFields> createState() => _NewPasswordFieldsState();
}

class _NewPasswordFieldsState extends State<NewPasswordFields> {
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: const ValueKey('new-password-field'),
          controller: widget.passwordController,
          enabled: widget.enabled,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: widget.enabled
                  ? () => setState(() => _obscurePassword = !_obscurePassword)
                  : null,
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          validator: (value) {
            final password = value?.trim() ?? '';
            if (password.isEmpty) return 'Enter a new password';
            if (password.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('confirm-password-field'),
          controller: widget.confirmPasswordController,
          enabled: widget.enabled,
          obscureText: _obscureConfirmation,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_reset_rounded),
            suffixIcon: IconButton(
              onPressed: widget.enabled
                  ? () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    )
                  : null,
              icon: Icon(
                _obscureConfirmation
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          validator: (value) {
            if ((value?.trim() ?? '') !=
                widget.passwordController.text.trim()) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}
