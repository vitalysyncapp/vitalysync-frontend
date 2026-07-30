import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationCodeField extends StatelessWidget {
  const VerificationCodeField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('verification-code-field'),
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 9,
      ),
      decoration: const InputDecoration(
        labelText: 'Verification code',
        hintText: '000000',
        counterText: '',
        prefixIcon: Icon(Icons.password_rounded),
      ),
      validator: (value) {
        final code = value?.trim() ?? '';
        if (!RegExp(r'^\d{6}$').hasMatch(code)) {
          return 'Enter the six-digit code';
        }
        return null;
      },
    );
  }
}
