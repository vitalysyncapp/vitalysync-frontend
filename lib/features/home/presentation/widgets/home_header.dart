import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/log/data/log_api.dart';
import '../../../../features/notifications/presentation/pages/notification_page.dart';
import '../../../../features/profile/presentation/widgets/profile_avatar_image.dart';
import '../../../../features/streaks/presentation/pages/personal_streak_page.dart';
import '../../../../shared/notifications/notification_feed_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleClockTick();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _scheduleClockTick() {
    _clockTimer?.cancel();
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );

    _clockTimer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleClockTick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final now = _now;
    final today = DateFormat('EEEE, MMMM d', localeCode).format(now);

    return ValueListenableBuilder<int>(
      valueListenable: streakRefreshNotifier,
      builder: (context, _, child) {
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            final prefs = snapshot.data;
            final username = prefs?.getString('username')?.trim();
            final displayName = username == null || username.isEmpty
                ? 'there'
                : username;
            final userId = prefs?.getInt('user_id');
            final gender = prefs?.getString('gender');
            final userType = prefs?.getString('user_type');
            final currentStreak = prefs?.getInt('log_streak') ?? 0;
            final lastLogDate = LogApi.normalizeDateString(
              prefs?.getString('last_log_date'),
            );
            final loggedToday =
                currentStreak > 0 && lastLogDate == _dateKey(now);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 350;

                return Padding(
                  key: const ValueKey('home-header'),
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        key: const ValueKey('home-header-logo'),
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                  TextSpan(text: today),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: pageSecondaryTextColor(context),
                                    fontSize: isCompact ? 11.5 : 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.08,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _NotificationButton(),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Open profile',
                            child: Semantics(
                              key: const ValueKey('home-header-avatar'),
                              image: true,
                              button: widget.onProfileTap != null,
                              label: 'Open profile',
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: widget.onProfileTap,
                                  customBorder: const CircleBorder(),
                                  child: Ink(
                                    width: 40,
                                    height: 40,
                                    padding: const EdgeInsets.all(4),
                                    decoration: _avatarDecoration(context),
                                    child: CurrentUserAvatar(
                                      userId: userId,
                                      gender: gender,
                                      userType: userType,
                                      size: 32,
                                      semanticLabel: 'User avatar',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 8 : 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _greeting(localeCode, now.hour),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: pageSecondaryTextColor(
                                                context,
                                              ),
                                              fontSize: isCompact ? 12.5 : 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    _TimeIndicator(now: now),
                                  ],
                                ),
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: pagePrimaryTextColor(context),
                                        fontSize: isCompact ? 22 : 26,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.55,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StreakChip(
                            currentStreak: currentStreak,
                            loggedToday: loggedToday,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _greeting(String localeCode, int hour) {
    if (localeCode == 'fil') {
      if (hour < 12) return 'Magandang umaga,';
      if (hour < 18) return 'Magandang hapon,';
      return 'Magandang gabi,';
    }

    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.currentStreak, required this.loggedToday});

  final int currentStreak;
  final bool loggedToday;

  @override
  Widget build(BuildContext context) {
    final flameColor = loggedToday
        ? const Color(0xFFF59E4B)
        : pageSecondaryTextColor(context).withValues(alpha: 0.72);
    final streakLabel = '$currentStreak day${currentStreak == 1 ? '' : 's'}';

    return Semantics(
      button: true,
      label: '$streakLabel streak. Open my streak.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('home-header-streak'),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const PersonalStreakPage()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: _glassDecoration(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 19,
                  color: flameColor,
                ),
                const SizedBox(width: 6),
                Text(
                  streakLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: pagePrimaryTextColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<int>(
      valueListenable: notificationFeedRefreshNotifier,
      builder: (context, _, child) {
        return FutureBuilder<int>(
          future: NotificationFeedService.instance.unreadCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;

            return Semantics(
              button: true,
              label: unreadCount == 0
                  ? 'Notifications'
                  : '$unreadCount unread notifications',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: _notificationDecoration(context),
                    child: IconButton(
                      key: const ValueKey('home-header-notifications'),
                      tooltip: 'Notifications',
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const NotificationPage(),
                          ),
                        );
                        if (context.mounted) {
                          await refreshNotificationFeed();
                        }
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          unreadCount > 0
                              ? Icons.notifications_rounded
                              : Icons.notifications_none_rounded,
                          key: ValueKey(unreadCount > 0),
                          size: 21,
                          color: unreadCount > 0
                              ? (isDark
                                    ? const Color(0xFF8ED9FF)
                                    : const Color(0xFF176B8C))
                              : pagePrimaryTextColor(context),
                        ),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFFFF927F), Color(0xFFFF607B)]
                                : const [Color(0xFFFF786E), Color(0xFFEA4263)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF102235)
                                : Colors.white,
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFEA4263,
                              ).withValues(alpha: 0.24),
                              blurRadius: 7,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TimeIndicator extends StatelessWidget {
  const _TimeIndicator({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final isDaytime = now.hour >= 5 && now.hour < 18;
    final label = isDaytime
        ? now.hour < 12
              ? 'Morning sun'
              : 'Afternoon sun'
        : 'Evening moon';
    final glowColor = isDaytime
        ? const Color(0xFFFFC247)
        : const Color(0xFF8296FF);

    final indicator = Container(
      key: ValueKey(isDaytime ? 'sun' : 'moon'),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: isDaytime
              ? (isDarkTheme
                    ? const [Color(0xFFFFE49A), Color(0xFFB86D12)]
                    : const [Color(0xFFFFF7C7), Color(0xFFFFD064)])
              : (isDarkTheme
                    ? const [Color(0xFFA8B5FF), Color(0xFF4A538F)]
                    : const [Color(0xFFE8EDFF), Color(0xFF8B9BE6)]),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDarkTheme ? 0.2 : 0.78),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        isDaytime ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
        size: 15,
        color: isDaytime ? const Color(0xFFE69513) : const Color(0xFFFFF3C4),
      ),
    );

    final animatedIndicator = MediaQuery.disableAnimationsOf(context)
        ? indicator
        : indicator
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .custom(
                duration: 1800.ms,
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(
                            alpha: 0.11 + (value * 0.17),
                          ),
                          blurRadius: 7 + (value * 8),
                          spreadRadius: value * 0.8,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
              )
              .scaleXY(
                begin: 0.97,
                end: 1.035,
                duration: 1800.ms,
                curve: Curves.easeInOut,
              )
              .shimmer(
                duration: 1800.ms,
                color: Colors.white.withValues(alpha: 0.5),
              );

    return Semantics(
      key: const ValueKey('home-header-time-indicator'),
      image: true,
      label: label,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: animatedIndicator,
      ),
    );
  }
}

BoxDecoration _notificationDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: isDark
          ? const [Color(0xFF213C52), Color(0xFF14283D)]
          : const [Color(0xFFFFFFFF), Color(0xFFEAF6FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(
      color: isDark
          ? const Color(0xFF83CAEB).withValues(alpha: 0.16)
          : const Color(0xFFB7DCEB).withValues(alpha: 0.72),
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF3B8FB0).withValues(alpha: isDark ? 0.12 : 0.14),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

BoxDecoration _avatarDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: isDark
          ? const [Color(0xFF2BB89A), Color(0xFF4C83C5), Color(0xFF8B63C7)]
          : const [Color(0xFF68D5B8), Color(0xFF76ACE8), Color(0xFFB18ADD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(
      color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.86),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF6F9ACB).withValues(alpha: isDark ? 0.15 : 0.2),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

BoxDecoration _glassDecoration(
  BuildContext context, {
  BoxShape shape = BoxShape.rectangle,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    color: isDark
        ? Colors.white.withValues(alpha: 0.075)
        : Colors.white.withValues(alpha: 0.68),
    shape: shape,
    borderRadius: shape == BoxShape.rectangle
        ? BorderRadius.circular(24)
        : null,
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.11)
          : Colors.white.withValues(alpha: 0.9),
    ),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.16)
            : const Color(0xFF4A8C86).withValues(alpha: 0.09),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ],
  );
}
