import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/pages/auth_start_page.dart';
import '../../features/log/data/log_api.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/streaks/presentation/pages/personal_streak_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../notifications/notification_feed_service.dart';
import '../preferences/session_reset_service.dart';
import '../theme/app_page_style.dart';

final ValueNotifier<int> streakRefreshNotifier = ValueNotifier<int>(0);

Future<void> refreshAppBarStreak() async {
  streakRefreshNotifier.value++;
}

PreferredSizeWidget buildAppBar(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final localeCode = Localizations.localeOf(context).languageCode;
  final today = DateFormat('EEEE, MMMM d', localeCode).format(DateTime.now());

  String greeting() {
    final hour = DateTime.now().hour;
    if (localeCode == 'fil') {
      if (hour < 12) return 'Magandang Umaga';
      if (hour < 18) return 'Magandang Hapon';
      return 'Magandang Gabi';
    }
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> logout() async {
    await SessionResetService.instance.resetForLogout();
    await refreshAppBarStreak();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthStartPage()),
      (route) => false,
    );
  }

  Future<void> showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.48 : 0.32),
      builder: (context) => const _LogoutConfirmationDialog(),
    );

    if (shouldLogout == true) {
      await logout();
    }
  }

  String getAvatarImage(String? gender, String? userType) {
    if (gender == null || userType == null) return 'assets/images/user.png';

    if (gender.toLowerCase() == 'male') {
      if (userType == 'Student') return 'assets/images/male Student.png';
      return 'assets/images/business-man.png';
    } else if (gender.toLowerCase() == 'female') {
      if (userType == 'Student') return 'assets/images/female Student.png';
      return 'assets/images/businesswoman.png';
    } else {
      return 'assets/images/user.png';
    }
  }

  String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  BoxDecoration actionChipDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.16),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    );
  }

  return AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 76,
    elevation: 0,
    titleSpacing: 14,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF133449), Color(0xFF0C2135)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 29, 140, 168),
                      Color(0xFF5DB8F0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
        ),
      ],
    ),
    title: FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final username = snapshot.hasData
            ? snapshot.data!.getString('username') ?? 'User'
            : 'User';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              greeting(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              today,
              style: const TextStyle(fontSize: 11.5, color: Colors.white70),
            ),
          ],
        );
      },
    ),
    actions: [
      ValueListenableBuilder<int>(
        valueListenable: streakRefreshNotifier,
        builder: (context, refreshValue, child) {
          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              final prefs = snapshot.data;
              final gender = prefs?.getString('gender');
              final userType = prefs?.getString('user_type');
              final avatarImage = getAvatarImage(gender, userType);

              final currentStreak = prefs?.getInt('log_streak') ?? 0;
              final lastLogDate = LogApi.normalizeDateString(
                prefs?.getString('last_log_date'),
              );
              final loggedToday =
                  currentStreak > 0 && lastLogDate == todayKey();

              return Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalStreakPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: actionChipDecoration(),
                          child: Row(
                            children: [
                              Text(
                                '$currentStreak',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 16,
                                color: loggedToday
                                    ? const Color(0xFFFFB15A)
                                    : Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: notificationFeedRefreshNotifier,
                    builder: (context, feedRefreshValue, child) {
                      return FutureBuilder<int>(
                        future: NotificationFeedService.instance.unreadCount(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            decoration: actionChipDecoration(),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationPage(),
                                      ),
                                    );
                                    if (context.mounted) {
                                      await refreshNotificationFeed();
                                    }
                                  },
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 16,
                                        minWidth: 16,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF6B6B),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        unreadCount > 9
                                            ? '9+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PopupMenuButton<int>(
                      offset: const Offset(0, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: isDark ? const Color(0xFF18263B) : Colors.white,
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                            width: 1.2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundImage: AssetImage(avatarImage),
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 0:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            );
                            break;
                          case 1:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            );
                            break;
                          case 2:
                            showLogoutConfirmation();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 0,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 20,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              const SizedBox(width: 10),
                              const Text('Profile'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 1,
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings_outlined,
                                size: 20,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              const SizedBox(width: 10),
                              const Text('Settings'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.red[300]
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ],
  );
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final isNarrow = screenWidth < 340;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFFF8585) : const Color(0xFFE5484D);

    final stayButton = OutlinedButton.icon(
      onPressed: () => Navigator.pop(context, false),
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Stay'),
      style: OutlinedButton.styleFrom(
        foregroundColor: pagePrimaryTextColor(context),
        side: BorderSide(color: pageBorderColor(context)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    final logoutButton = ElevatedButton.icon(
      onPressed: () => Navigator.pop(context, true),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Log out'),
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 18 : 22),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF132235).withValues(alpha: 0.98)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCompact ? 54 : 60,
                height: isCompact ? 54 : 60,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: accent,
                  size: isCompact ? 28 : 32,
                ),
              ),
              SizedBox(height: isCompact ? 14 : 16),
              Text(
                'Log out of VitalySync?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: pagePrimaryTextColor(context),
                  fontSize: isCompact ? 20 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will return to the welcome screen and can sign back in anytime.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: pageSecondaryTextColor(context),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.1 : 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.14),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Assistant access pauses until you sign in again.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: pageSecondaryTextColor(context),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isCompact ? 18 : 20),
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    logoutButton,
                    const SizedBox(height: 10),
                    stayButton,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: stayButton),
                    const SizedBox(width: 12),
                    Expanded(child: logoutButton),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
