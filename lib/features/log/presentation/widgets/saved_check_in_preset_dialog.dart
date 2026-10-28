import 'package:flutter/material.dart';

import '../../../../l10n/localized_text.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../data/check_in_models.dart';
import '../../data/quick_check_in_preset.dart';
import 'quick_check_in_avatar_picker.dart';

Future<QuickCheckInPreset?> showSavedCheckInPresetDialog({
  required BuildContext context,
  required CheckInMode mode,
  required CheckInDraft draft,
  required Map<String, int> weeklyAnswers,
}) {
  return showDialog<QuickCheckInPreset>(
    context: context,
    builder: (_) => _SavedCheckInPresetDialog(
      mode: mode,
      draft: draft,
      weeklyAnswers: weeklyAnswers,
    ),
  );
}

class _SavedCheckInPresetDialog extends StatefulWidget {
  const _SavedCheckInPresetDialog({
    required this.mode,
    required this.draft,
    required this.weeklyAnswers,
  });

  final CheckInMode mode;
  final CheckInDraft draft;
  final Map<String, int> weeklyAnswers;

  @override
  State<_SavedCheckInPresetDialog> createState() =>
      _SavedCheckInPresetDialogState();
}

class _SavedCheckInPresetDialogState extends State<_SavedCheckInPresetDialog> {
  final _nameController = TextEditingController();
  String _avatarId = 'happy';
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 40) {
      setState(() => _nameError = 'Enter a name between 1 and 40 characters.');
      return;
    }

    Navigator.of(context).pop(
      QuickCheckInPreset(
        presetId: 0,
        name: name,
        mode: widget.mode,
        avatarId: _avatarId,
        draft: widget.draft,
        weeklyAnswers: Map.unmodifiable(widget.weeklyAnswers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.mode == CheckInMode.weekly
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF1FB489);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: buildPageDecoration(context).copyWith(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.16),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LocalizedText(
                  'Save as quick check-in',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                LocalizedText(
                  'Your saved answers will be reused for this quick check-in.',
                  style: TextStyle(color: pageSecondaryTextColor(context)),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const ValueKey('saved-check-in-preset-name'),
                  controller: _nameController,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Quick check-in name'.localizedCopy(context),
                    errorText: _nameError?.localizedCopy(context),
                    filled: true,
                    fillColor: pageSubtleSurfaceColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LocalizedText(
                  'Choose an emoji',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                QuickCheckInAvatarPicker(
                  selectedId: _avatarId,
                  accent: accent,
                  onSelected: (id) => setState(() => _avatarId = id),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const LocalizedText('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('confirm-saved-check-in-preset'),
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const LocalizedText('Save quick check-in'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
