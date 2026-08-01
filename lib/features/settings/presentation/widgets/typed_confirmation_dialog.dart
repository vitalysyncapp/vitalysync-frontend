import 'package:flutter/material.dart';
import 'package:vitalysync/l10n/localized_text.dart';

Future<bool> showTypedConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
  required Key confirmationFieldKey,
  required Key actionButtonKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TypedConfirmationDialog(
      title: title,
      message: message,
      actionLabel: actionLabel,
      confirmationFieldKey: confirmationFieldKey,
      actionButtonKey: actionButtonKey,
    ),
  );

  return confirmed ?? false;
}

class _TypedConfirmationDialog extends StatefulWidget {
  const _TypedConfirmationDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.confirmationFieldKey,
    required this.actionButtonKey,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Key confirmationFieldKey;
  final Key actionButtonKey;

  @override
  State<_TypedConfirmationDialog> createState() =>
      _TypedConfirmationDialogState();
}

class _TypedConfirmationDialogState extends State<_TypedConfirmationDialog> {
  final TextEditingController _confirmationController = TextEditingController();

  bool get _isConfirmed => _confirmationController.text == 'CONFIRM';

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_isConfirmed) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: LocalizedText(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(widget.message),
            const SizedBox(height: 20),
            const LocalizedText('Type CONFIRM below to continue.'),
            const SizedBox(height: 8),
            TextField(
              key: widget.confirmationFieldKey,
              controller: _confirmationController,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _confirm(),
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Type CONFIRM'.localizedCopy(context),
                helperText: 'Confirmation is case-sensitive.'.localizedCopy(
                  context,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const LocalizedText('Cancel'),
        ),
        TextButton(
          key: widget.actionButtonKey,
          onPressed: _isConfirmed ? _confirm : null,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD14343)),
          child: LocalizedText(widget.actionLabel),
        ),
      ],
    );
  }
}
