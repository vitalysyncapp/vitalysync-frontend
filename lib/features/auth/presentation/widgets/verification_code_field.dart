import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vitalysync/l10n/localized_text.dart';

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
      decoration: InputDecoration(
        labelText: 'Verification code'.localizedCopy(context),
        hintText: '000000'.localizedCopy(context),
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
