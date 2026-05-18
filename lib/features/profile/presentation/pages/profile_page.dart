import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import 'edit_profile_page.dart';
import 'personal_information_page.dart';
import '../widgets/wellness_profile_card.dart';

part 'profile_page_widgets.dart';
part 'profile_page_helpers.dart';

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

  bool _isLoading = true, _isSaving = false;
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

    if (session.userId != null) {
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
    if (gender.toLowerCase() == 'male') {
      return userType == 'Student'
          ? 'assets/images/male Student.png'
          : 'assets/images/business-man.png';
    }
    if (gender.toLowerCase() == 'female') {
      return userType == 'Student'
          ? 'assets/images/female Student.png'
          : 'assets/images/businesswoman.png';
    }
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
      );
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
          'preferred_nudge_style': existingPreferences['preferred_nudge_style'],
          'primary_goal': existingPreferences['primary_goal'],
          'busy_days': (summary['busy_days'] as List? ?? const []),
        },
      );
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
        ),
      ),
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
                    _ProfileHeaderCard(
                      avatarPath: avatarPath,
                      username: _username,
                      email: _email,
                      role: _userType,
                      currentStreak: _currentStreak,
                      longestStreak: _longestStreak,
                      age: _age,
                      gender: _gender,
                    ),
                    const SizedBox(height: 18),
                    _PersonalInformationCard(
                      gender: _gender,
                      role: _userType,
                      sleepSchedule: _sleepSchedule,
                      isSaving: _isSaving,
                      onOpenDetails: _openPersonalInformationPage,
                      onEditProfile: _openEditProfilePage,
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
                    _SavedRoutineCard(
                      sleepSchedule: _sleepSchedule,
                      wellnessGoal: _wellnessGoal,
                      waterGoal: _waterGoal,
                      exerciseTarget: _exerciseTarget,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
