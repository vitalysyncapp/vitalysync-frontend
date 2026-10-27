import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/localized_text.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../data/quick_check_in_preset.dart';

class QuickCheckInAvatarPicker extends StatefulWidget {
  const QuickCheckInAvatarPicker({
    super.key,
    required this.selectedId,
    required this.accent,
    required this.onSelected,
  });

  final String selectedId;
  final Color accent;
  final ValueChanged<String> onSelected;

  @override
  State<QuickCheckInAvatarPicker> createState() =>
      _QuickCheckInAvatarPickerState();
}

class _QuickCheckInAvatarPickerState extends State<QuickCheckInAvatarPicker> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAvatar = QuickCheckInAvatarCatalog.find(widget.selectedId);
    final accent = pageAccentColor(context, widget.accent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SvgPicture.asset(selectedAvatar.assetPath, width: 42, height: 42),
            const SizedBox(width: 10),
            Expanded(
              child: LocalizedText(
                selectedAvatar.semanticLabel,
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.check_circle_rounded, color: accent, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: GridView.builder(
              key: const ValueKey('quick-check-in-avatar-grid'),
              controller: _scrollController,
              padding: const EdgeInsets.only(right: 12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 96,
                mainAxisExtent: 62 + MediaQuery.textScalerOf(context).scale(28),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: QuickCheckInAvatarCatalog.entries.length,
              itemBuilder: (context, index) {
                final avatar = QuickCheckInAvatarCatalog.entries[index];
                final selected = avatar.id == widget.selectedId;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: avatar.semanticLabel.localizedCopy(context),
                  child: Tooltip(
                    message: avatar.semanticLabel.localizedCopy(context),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('quick-avatar-${avatar.id}'),
                        onTap: () => widget.onSelected(avatar.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: selected
                                ? accent.withValues(alpha: 0.13)
                                : pageSubtleSurfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? accent
                                  : pageBorderColor(context),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: ExcludeSemantics(
                            child: Column(
                              children: [
                                SvgPicture.asset(avatar.assetPath, height: 44),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Center(
                                    child: LocalizedText(
                                      avatar.semanticLabel,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: pagePrimaryTextColor(context),
                                        fontSize: 10,
                                        height: 1.15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
