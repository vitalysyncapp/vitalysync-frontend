import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import 'edit_profile_page.dart';
import 'personal_information_page.dart';
import '../widgets/wellness_profile_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _sleepScheduleKey = 'profile_sleep_schedule';
  static const _waterGoalKey = 'profile_water_goal';
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _roleOptions = [
    'Student',
    'Working Professional',
    'Freelancer',
    'Unemployed',
    'Other',
  ];
  static const List<String> _lifestyleOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Active',
    'Very Active',
  ];
  static const List<String> _workIntensityOptions = ['Low', 'Medium', 'High'];

  bool _isLoading = true, _isSaving = false, _isDemoMode = false;
  int? _userId, _age;
  String _username = 'User Name', _email = 'user@email.com';
  String? _gender, _userType;
  String _sleepSchedule = '10:30 PM - 6:30 AM',
      _lifestyleType = 'Moderately Active',
      _workIntensity = 'Medium',
      _waterGoal = '2.5 L',
      _exerciseTarget = '3–4 days',
      _wellnessGoal = 'Not set',
      _usualSleepTime = '--',
      _usualWakeTime = '--',
      _initialBurnoutLevel = 'Not set';
  int _initialBurnoutScore = 0;
  int _currentStreak = 0, _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _fallbackValue(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _workIntensityFromHours(int hours) => hours >= 10
      ? 'High'
      : hours >= 7
      ? 'Medium'
      : 'Low';
  String _workIntensityFromLevel(int? level) => level == null
      ? 'Medium'
      : level >= 4
      ? 'High'
      : level <= 2
      ? 'Low'
      : 'Medium';
  int _workHoursFromIntensity(String intensity) =>
      intensity.toLowerCase() == 'high'
      ? 10
      : intensity.toLowerCase() == 'low'
      ? 6
      : 8;
  String _waterGoalFromActivity(String activity) =>
      activity.toLowerCase().contains('active') &&
          activity.toLowerCase() != 'sedentary'
      ? '3.0 L'
      : activity.toLowerCase() == 'sedentary'
      ? '2.0 L'
      : '2.5 L';
  int _parseIntValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return double.tryParse('${value ?? ''}')?.round() ?? 0;
  }

  String? _dropdownValueOrNull(
    String? value,
    List<String> options, {
    Map<String, String> aliases = const {},
  }) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;

    for (final option in options) {
      if (option.toLowerCase() == normalized.toLowerCase()) {
        return option;
      }
    }

    final aliasMatch = aliases[normalized.toLowerCase()];
    if (aliasMatch == null) return null;

    for (final option in options) {
      if (option.toLowerCase() == aliasMatch.toLowerCase()) {
        return option;
      }
    }

    return null;
  }

  String _formatTimeForDisplay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    final hour = int.tryParse(parts[0]), minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;
    final period = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$normalizedHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _buildSleepSchedule({
    required String? sleepTime,
    required String? wakeTime,
    required String fallback,
  }) {
    if (sleepTime == null || wakeTime == null) return fallback;
    return '${_formatTimeForDisplay(sleepTime)} - ${_formatTimeForDisplay(wakeTime)}';
  }

  String? _convertDisplayTimeTo24Hour(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    ).firstMatch(value.trim().toUpperCase());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!),
        minute = int.tryParse(match.group(2)!);
    final period = match.group(3);
    if (hour == null || minute == null || period == null) return null;
    var militaryHour = hour % 12;
    if (period == 'PM') militaryHour += 12;
    return '${militaryHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Map<String, String?> _parseSleepSchedule(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return const {'sleep': null, 'wake': null};
    return {
      'sleep': _convertDisplayTimeTo24Hour(parts[0]),
      'wake': _convertDisplayTimeTo24Hour(parts[1]),
    };
  }

  int _parseExerciseDays(String value) =>
      int.tryParse(RegExp(r'(\d+)').firstMatch(value)?.group(1) ?? '') ?? 3;

  Future<void> _loadProfile() async {
    final session = await UserSessionController.instance.load();
    final prefs = await SharedPreferences.getInstance();
    var sleepSchedule =
        prefs.getString(_sleepScheduleKey) ?? '10:30 PM - 6:30 AM';
    var lifestyleType = 'Moderately Active',
        workIntensity = 'Medium',
        waterGoal = prefs.getString(_waterGoalKey) ?? '2.5 L',
        exerciseTarget = '3–4 days';
    var wellnessGoal = 'Not set',
        usualSleepTime = '--',
        usualWakeTime = '--',
        initialBurnoutLevel = 'Not set';
    var initialBurnoutScore = 0;
    var userType = _emptyToNull(session.userType);

    if (!session.isDemoMode && session.userId != null) {
      try {
        final summary = await OnboardingApi.fetchSummary(session.userId!);
        await OnboardingService.saveDefaultsFromSummary(summary);
        final rawProfile = summary['profile'] ?? summary['onboarding_profile'];
        final profile = Map<String, dynamic>.from(
          rawProfile is Map ? rawProfile : {},
        );
        final onboarding = Map<String, dynamic>.from(
          summary['onboarding'] as Map? ?? {},
        );
        final preferences = Map<String, dynamic>.from(
          summary['preferences'] as Map? ?? {},
        );
        final profileSleepTime = _emptyToNull(
          profile['usual_sleep_time']?.toString(),
        );
        final profileWakeTime = _emptyToNull(
          profile['usual_wake_time']?.toString(),
        );
        final activity =
            _emptyToNull(profile['lifestyle_type']?.toString()) ??
            _emptyToNull(onboarding['activity_level']?.toString()) ??
            'Moderately Active';
        final workloadLevel = int.tryParse(
          '${profile['workload_level'] ?? ''}',
        );
        final workHours =
            int.tryParse('${onboarding['work_hours_per_day'] ?? ''}') ?? 8;
        final exerciseDays =
            int.tryParse('${onboarding['exercise_days_per_week'] ?? ''}') ?? 3;
        lifestyleType = activity;
        workIntensity = workloadLevel == null
            ? _workIntensityFromHours(workHours)
            : _workIntensityFromLevel(workloadLevel);
        waterGoal = _waterGoalFromActivity(activity);
        exerciseTarget =
            _emptyToNull(profile['exercise_goal_days']?.toString()) ??
            '$exerciseDays days/week';
        wellnessGoal =
            _emptyToNull(profile['wellness_goal']?.toString()) ?? 'Not set';
        userType = _emptyToNull(profile['role']?.toString()) ?? userType;
        usualSleepTime = profileSleepTime == null
            ? '--'
            : _formatTimeForDisplay(profileSleepTime);
        usualWakeTime = profileWakeTime == null
            ? '--'
            : _formatTimeForDisplay(profileWakeTime);
        initialBurnoutLevel =
            _emptyToNull(profile['initial_burnout_level']?.toString()) ??
            'Not set';
        initialBurnoutScore = _parseIntValue(profile['initial_burnout_score']);
        sleepSchedule = _buildSleepSchedule(
          sleepTime:
              profileSleepTime ??
              _emptyToNull(preferences['default_sleep_time']?.toString()),
          wakeTime:
              profileWakeTime ??
              _emptyToNull(preferences['default_wake_time']?.toString()),
          fallback: sleepSchedule,
        );
        await prefs.setString(_sleepScheduleKey, sleepSchedule);
        await prefs.setString(_waterGoalKey, waterGoal);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _userId = session.userId;
      _username = session.username?.isNotEmpty == true
          ? session.username!
          : 'User Name';
      _email = session.email?.isNotEmpty == true
          ? session.email!
          : 'user@email.com';
      _age = session.age;
      _gender = _emptyToNull(session.gender);
      _userType = userType;
      _isDemoMode = session.isDemoMode;
      _sleepSchedule = sleepSchedule;
      _lifestyleType = lifestyleType;
      _workIntensity = workIntensity;
      _waterGoal = waterGoal;
      _exerciseTarget = exerciseTarget;
      _wellnessGoal = wellnessGoal;
      _usualSleepTime = usualSleepTime;
      _usualWakeTime = usualWakeTime;
      _initialBurnoutLevel = initialBurnoutLevel;
      _initialBurnoutScore = initialBurnoutScore;
      _currentStreak = prefs.getInt('log_streak') ?? 0;
      _longestStreak = prefs.getInt('longest_log_streak') ?? 0;
      _isLoading = false;
    });
  }

  String getAvatarImage(String? gender, String? userType) {
    if (gender == null || userType == null) return 'assets/images/user.png';
    if (gender.toLowerCase() == 'male')
      return userType == 'Student'
          ? 'assets/images/male Student.png'
          : 'assets/images/business-man.png';
    if (gender.toLowerCase() == 'female')
      return userType == 'Student'
          ? 'assets/images/female Student.png'
          : 'assets/images/businesswoman.png';
    return 'assets/images/user.png';
  }

  Future<bool> _saveProfileChanges({
    required String username,
    required String email,
    required int? age,
    required String? gender,
    required String? userType,
    required String lifestyleType,
    required String workIntensity,
    required String sleepSchedule,
    required String waterGoal,
    required String exerciseTarget,
  }) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile can only be edited after a session is loaded.',
          ),
        ),
      );
      return false;
    }
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final scheduleParts = _parseSleepSchedule(sleepSchedule);
      final normalizedSleep = _fallbackValue(
        sleepSchedule,
        '10:30 PM - 6:30 AM',
      );
      final normalizedWater = _fallbackValue(waterGoal, '2.5 L');
      final normalizedExercise =
          '${_parseExerciseDays(exerciseTarget)} days/week';
      await UserSessionController.instance.updateProfile(
        userId: _userId!,
        username: username,
        email: email,
        age: age,
        gender: gender,
        userType: userType,
        isDemoMode: _isDemoMode,
      );
      if (!_isDemoMode) {
        final summary = await OnboardingApi.fetchSummary(_userId!);
        final existingOnboarding = Map<String, dynamic>.from(
          summary['onboarding'] as Map? ?? {},
        );
        final existingPreferences = Map<String, dynamic>.from(
          summary['preferences'] as Map? ?? {},
        );
        await OnboardingApi.upsertOnboarding(
          userId: _userId!,
          onboarding: {
            'role_type': userType,
            'activity_level': lifestyleType,
            'work_hours_per_day': _workHoursFromIntensity(workIntensity),
            'exercise_days_per_week': _parseExerciseDays(exerciseTarget),
            'sleep_hours': existingOnboarding['sleep_hours'],
            'meal_regularness': existingOnboarding['meal_regularness'],
            'stress_level': existingOnboarding['stress_level'],
            'mental_drain_level': existingOnboarding['mental_drain_level'],
            'focus_difficulty_level':
                existingOnboarding['focus_difficulty_level'],
            'overwhelm_level': existingOnboarding['overwhelm_level'],
            'recovery_level': existingOnboarding['recovery_level'],
            'motivation_level': existingOnboarding['motivation_level'],
            'skipped': existingOnboarding['skipped'] == true,
          },
        );
        await OnboardingApi.upsertPreferences(
          userId: _userId!,
          preferences: {
            'preferred_log_time': existingPreferences['preferred_log_time'],
            'default_sleep_time': scheduleParts['sleep'],
            'default_wake_time': scheduleParts['wake'],
            'default_work_start': existingPreferences['default_work_start'],
            'default_work_end': existingPreferences['default_work_end'],
            'prefers_daily_reminder':
                existingPreferences['prefers_daily_reminder'] == true,
            'reminder_time': existingPreferences['reminder_time'],
            'prefers_hydration_reminder':
                existingPreferences['prefers_hydration_reminder'] == true,
            'prefers_exercise_reminder':
                existingPreferences['prefers_exercise_reminder'] == true,
            'prefers_sleep_reminder':
                existingPreferences['prefers_sleep_reminder'] == true,
            'preferred_nudge_style':
                existingPreferences['preferred_nudge_style'],
            'primary_goal': existingPreferences['primary_goal'],
            'busy_days': (summary['busy_days'] as List? ?? const []),
          },
        );
      }
      await prefs.setString(_sleepScheduleKey, normalizedSleep);
      await prefs.setString(_waterGoalKey, normalizedWater);
      if (!mounted) return false;
      setState(() {
        _username = username;
        _email = email;
        _age = age;
        _gender = _emptyToNull(gender);
        _userType = _emptyToNull(userType);
        _sleepSchedule = normalizedSleep;
        _lifestyleType = lifestyleType;
        _workIntensity = workIntensity;
        _waterGoal = normalizedWater;
        _exerciseTarget = normalizedExercise;
      });
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update profile: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openEditProfilePage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          initialUsername: _username,
          initialEmail: _email,
          initialAge: _age,
          initialGender: _dropdownValueOrNull(_gender, _genderOptions),
          initialUserType: _dropdownValueOrNull(
            _userType,
            _roleOptions,
            aliases: const {
              'freelance': 'Freelancer',
              'self employed': 'Freelancer',
              'working professional': 'Working Professional',
              'young professional': 'Working Professional',
              'others': 'Other',
            },
          ),
          initialLifestyle:
              _dropdownValueOrNull(_lifestyleType, _lifestyleOptions) ??
              'Moderately Active',
          initialWorkIntensity:
              _dropdownValueOrNull(_workIntensity, _workIntensityOptions) ??
              'Medium',
          initialSleepSchedule: _sleepSchedule,
          initialWaterGoal: _waterGoal,
          initialExerciseTarget: _exerciseTarget,
          onSave:
              ({
                required String username,
                required String email,
                required int? age,
                required String? gender,
                required String? userType,
                required String lifestyleType,
                required String workIntensity,
                required String sleepSchedule,
                required String waterGoal,
                required String exerciseTarget,
              }) {
                return _saveProfileChanges(
                  username: username,
                  email: email,
                  age: age,
                  gender: gender,
                  userType: userType,
                  lifestyleType: lifestyleType,
                  workIntensity: workIntensity,
                  sleepSchedule: sleepSchedule,
                  waterGoal: waterGoal,
                  exerciseTarget: exerciseTarget,
                );
              },
        ),
      ),
    );
  }

  void _openPersonalInformationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalInformationPage(
          username: _username,
          email: _email,
          age: _age,
          gender: _gender,
          role: _userType,
          lifestyleType: _lifestyleType,
          wellnessGoal: _wellnessGoal,
          usualSleepTime: _usualSleepTime,
          usualWakeTime: _usualWakeTime,
          workIntensity: _workIntensity,
          waterGoal: _waterGoal,
          exerciseTarget: _exerciseTarget,
          burnoutLevel: _initialBurnoutLevel,
          burnoutScore: _initialBurnoutScore,
          isDemoMode: _isDemoMode,
        ),
      ),
    );
  }

  Widget _infoTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: pagePrimaryTextColor(context),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: pageSecondaryTextColor(context),
          ),
        ),
      ),
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarPath = getAvatarImage(_gender, _userType);
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: pagePrimaryTextColor(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Profile',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  pageBottomContentPadding(context),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF60A5FA),
                            Color(0xFF38BDF8),
                            Color.fromARGB(255, 91, 110, 174),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Image.asset(
                                      avatarPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 42,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _username,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.92),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 190,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircleAvatar(
                                            radius: 4,
                                            backgroundColor: Color(0xFF4CFF8F),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _userType ?? 'Role not set',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Divider(
                            color: Colors.white.withOpacity(0.22),
                            thickness: 1,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  value: '$_currentStreak',
                                  label: 'Current',
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  value: '$_longestStreak',
                                  label: 'Best',
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  value: _age?.toString() ?? '--',
                                  label: 'Age',
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  value: _gender ?? '--',
                                  label: 'Gender',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: pageSurfaceColor(context),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: pageBorderColor(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 0.18
                                  : 0.06,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: pagePrimaryTextColor(context),
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: pageBorderColor(context),
                          ),
                          _infoTile(
                            context: context,
                            icon: Icons.person_outline,
                            iconBg: const Color(0xFFE8F0FF),
                            iconColor: const Color(0xFF2F6BFF),
                            title: 'Profile Details',
                            subtitle:
                                '${_gender ?? 'Gender not set'} - ${_userType ?? 'Role not set'}',
                            onTap: _openPersonalInformationPage,
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: pageBorderColor(context),
                          ),
                          _infoTile(
                            context: context,
                            icon: Icons.nightlight_round,
                            iconBg: const Color(0xFFE0F2FE),
                            iconColor: const Color(0xFF0891B2),
                            title: 'Sleep Schedule',
                            subtitle: _sleepSchedule,
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: pageBorderColor(context),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : _openEditProfilePage,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text(
                                  'Edit Profile',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  side: BorderSide(
                                    color: pageBorderColor(context),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    WellnessProfileCard(
                      lifestyleType: _lifestyleType,
                      currentRole: _userType ?? 'Not set',
                      wellnessGoal: _wellnessGoal,
                      usualSleepTime: _usualSleepTime,
                      usualWakeTime: _usualWakeTime,
                      workIntensity: _workIntensity,
                      waterGoal: _waterGoal,
                      exerciseTarget: _exerciseTarget,
                      burnoutLevel: _initialBurnoutLevel,
                      burnoutScore: _initialBurnoutScore,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: pageSurfaceColor(context),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: pageBorderColor(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Routine',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: pagePrimaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sleep: $_sleepSchedule',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wellness goal: $_wellnessGoal',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Water goal: $_waterGoal',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Exercise target: $_exerciseTarget',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          SizedBox(
            height: 22,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
