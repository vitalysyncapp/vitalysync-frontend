import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/log/data/log_api.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../preferences/user_session.dart';

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
      if (hour < 12) return "Magandang Umaga";
      if (hour < 18) return "Magandang Hapon";
      return "Magandang Gabi";
    }
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await UserSessionController.instance.clearSession();
    await LogApi.clearLocalDemoData();
    await prefs.remove('log_streak');
    await prefs.remove('longest_log_streak');
    await prefs.remove('last_log_date');
    await refreshAppBarStreak();

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  //logout confirmation dialog
  Future<void> showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Confirm Logout",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to log out?",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      logout();
    }
  }

  String getAvatarImage(String? gender, String? userType) {
    if (gender == null || userType == null) return "assets/images/user.png";

    if (gender.toLowerCase() == 'male') {
      if (userType == 'Student') return "assets/images/male Student.png";
      return "assets/images/business-man.png";
    } else if (gender.toLowerCase() == 'female') {
      if (userType == 'Student') return "assets/images/female Student.png";
      return "assets/images/businesswoman.png";
    } else {
      return "assets/images/user.png";
    }
  }

  String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  return AppBar(
    toolbarHeight: 80,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1F1F2E), Color(0xFF151521)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color.fromARGB(255, 127, 116, 209), Color(0xFF8E44AD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
    ),
    title: FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final username =
            snapshot.hasData ? snapshot.data!.getString('username') ?? 'User' : 'User';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${greeting()},\n$username',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              today,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        );
      },
    ),
    actions: [
      ValueListenableBuilder<int>(
        valueListenable: streakRefreshNotifier,
        builder: (context, _, __) {
          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              final prefs = snapshot.data;
             // final username = prefs?.getString('username') ?? 'User';
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
                  Container(
                    margin: const EdgeInsets.only(right: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "$currentStreak",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: loggedToday
                              ? const Color(0xFFFF6B35)
                              : Colors.white54,
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationPage()),
                          );
                        },
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          height: 17,
                          width: 17,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "3",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Text(
                  //   username,
                  //   style: const TextStyle(
                  //     color: Colors.white,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                  //const SizedBox(width: 0),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: PopupMenuButton<int>(
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: isDark ? Colors.grey[900] : Colors.white,
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage(avatarImage),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 0:
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfilePage()),
                            );
                            break;
                          case 1:
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsPage()),
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
                              const Text("Profile"),
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
                              const Text("Settings"),
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
                                "Logout",
                                style: TextStyle(
                                  color: isDark ? Colors.red[300] : Colors.redAccent,
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
