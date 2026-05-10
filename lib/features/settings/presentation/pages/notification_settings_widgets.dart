part of 'notification_settings_page.dart';

class _SettingsBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final Future<void> Function(bool) onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? pagePrimaryTextColor(context)
        : pageSecondaryTextColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.4,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  const _TimeTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? pagePrimaryTextColor(context)
        : pageSecondaryTextColor(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      height: 1.4,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _displayTime(context, value),
              style: TextStyle(fontWeight: FontWeight.w800, color: titleColor),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.schedule_rounded,
              size: 18,
              color: pageSecondaryTextColor(context),
            ),
          ],
        ),
      ),
    );
  }

  String _displayTime(BuildContext context, String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final time = TimeOfDay(
      hour: (hour ?? 0).clamp(0, 23).toInt(),
      minute: (minute ?? 0).clamp(0, 59).toInt(),
    );
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }
}

class _SelectTile<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final List<T> options;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const _SelectTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? pagePrimaryTextColor(context)
        : pageSecondaryTextColor(context);
    final menuOptions = options.contains(value)
        ? options
        : <T>[value, ...options];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.4,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            items: menuOptions
                .map(
                  (option) => DropdownMenuItem<T>(
                    value: option,
                    child: Text(labelFor(option)),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (nextValue) {
                    if (nextValue != null) {
                      onChanged(nextValue);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
