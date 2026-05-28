import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/activity/data/activity_service.dart';
import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../features/onboarding/services/onboarding_service.dart';
import '../../../../shared/goals/user_goals.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import 'edit_profile_page.dart';
import 'edit_goals_page.dart';
import 'edit_wellness_profile_page.dart';
import 'history_page.dart';
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
  bool _isSavingWellness = false, _isSavingGoals = false;
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
  UserGoalsSnapshot _goals = UserGoalsSnapshot.defaults();

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
    var goals = UserGoalsSnapshot.defaults();

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
        final preferenceSleepTime = _emptyToNull(
          preferences['default_sleep_time']?.toString(),
        );
        final preferenceWakeTime = _emptyToNull(
          preferences['default_wake_time']?.toString(),
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
          sleepTime: profileSleepTime ?? preferenceSleepTime,
          wakeTime: profileWakeTime ?? preferenceWakeTime,
          fallback: sleepSchedule,
        );
        goals = await UserGoalsService.fetch(
          userId: session.userId!,
          defaults: UserGoalsSnapshot.defaults(
            wellnessGoal: wellnessGoal,
            sleepHours: OnboardingService.sleepHoursBetween(
              profileSleepTime ?? preferenceSleepTime,
              profileWakeTime ?? preferenceWakeTime,
              fallback: 8,
            ),
            hydrationLiters: _parseLiters(waterGoal),
            activityDaysPerWeek: _parseExerciseDays(exerciseTarget),
            dailySteps: ActivityService.instance.notifier.value.log.goalSteps,
          ),
        );
        wellnessGoal = goals.wellnessGoal;
        waterGoal = _formatLiters(goals.hydrationLiters);
        exerciseTarget = '${goals.activityDaysPerWeek} days/week';
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
      _goals = goals;
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
      await OnboardingApi.updateWellnessProfile(
        userId: _userId!,
        profile: {
          'role': userType ?? 'Other',
          'lifestyle_type': lifestyleType,
          'usual_sleep_time': scheduleParts['sleep'],
          'usual_wake_time': scheduleParts['wake'],
          'workload_level': _workloadLevelFromIntensity(workIntensity),
        },
      );
      final updatedGoals = _goals.copyWith(
        hydrationLiters: _parseLiters(normalizedWater),
        activityDaysPerWeek: _parseExerciseDays(normalizedExercise),
      );
      final savedGoals = await UserGoalsService.save(
        userId: _userId!,
        goals: updatedGoals,
      );
      await prefs.setString(_sleepScheduleKey, normalizedSleep);
      await prefs.setString(
        _waterGoalKey,
        _formatLiters(savedGoals.hydrationLiters),
      );
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
        _waterGoal = _formatLiters(savedGoals.hydrationLiters);
        _exerciseTarget = '${savedGoals.activityDaysPerWeek} days/week';
        _wellnessGoal = savedGoals.wellnessGoal;
        _goals = savedGoals;
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

  Future<bool> _saveWellnessProfileChanges({
    required String role,
    required String lifestyleType,
    required String workIntensity,
    required String sleepSchedule,
  }) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Wellness profile can only be edited after a session is loaded.',
          ),
        ),
      );
      return false;
    }

    final scheduleParts = _parseSleepSchedule(sleepSchedule);
    if (scheduleParts['sleep'] == null || scheduleParts['wake'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use a valid sleep schedule.')),
      );
      return false;
    }

    setState(() => _isSavingWellness = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await OnboardingApi.updateWellnessProfile(
        userId: _userId!,
        profile: {
          'role': role,
          'lifestyle_type': lifestyleType,
          'usual_sleep_time': scheduleParts['sleep'],
          'usual_wake_time': scheduleParts['wake'],
          'workload_level': _workloadLevelFromIntensity(workIntensity),
        },
      );
      final profile = Map<String, dynamic>.from(
        response['profile'] as Map? ?? {},
      );
      await OnboardingService.saveDefaultsFromProfile(profile);
      await UserSessionController.instance.saveSupplementalProfile(
        age: _age,
        gender: _gender,
        userType: role,
      );
      await prefs.setString(_sleepScheduleKey, sleepSchedule);

      if (!mounted) return false;
      setState(() {
        _userType = role;
        _lifestyleType = lifestyleType;
        _workIntensity = workIntensity;
        _sleepSchedule = sleepSchedule;
        _usualSleepTime = _formatTimeForDisplay(scheduleParts['sleep']!);
        _usualWakeTime = _formatTimeForDisplay(scheduleParts['wake']!);
      });
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update wellness profile: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSavingWellness = false);
    }
  }

  Future<bool> _saveGoalChanges(UserGoalsSnapshot goals) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals can only be edited after a session is loaded.'),
        ),
      );
      return false;
    }

    setState(() => _isSavingGoals = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final previousStepGoal = _goals.dailySteps;
      final savedGoals = await UserGoalsService.save(
        userId: _userId!,
        goals: goals,
      );

      if (savedGoals.dailySteps != previousStepGoal) {
        await ActivityService.instance.updateGoalSteps(savedGoals.dailySteps);
      }

      await prefs.setString(
        _waterGoalKey,
        _formatLiters(savedGoals.hydrationLiters),
      );

      if (!mounted) return false;
      setState(() {
        _goals = savedGoals;
        _wellnessGoal = savedGoals.wellnessGoal;
        _waterGoal = _formatLiters(savedGoals.hydrationLiters);
        _exerciseTarget = '${savedGoals.activityDaysPerWeek} days/week';
      });
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update goals: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSavingGoals = false);
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

  Future<void> _openEditWellnessProfilePage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditWellnessProfilePage(
          initialRole: _dropdownValueOrNull(
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
          onSave:
              ({
                required String role,
                required String lifestyleType,
                required String workIntensity,
                required String sleepSchedule,
              }) {
                return _saveWellnessProfileChanges(
                  role: role,
                  lifestyleType: lifestyleType,
                  workIntensity: workIntensity,
                  sleepSchedule: sleepSchedule,
                );
              },
        ),
      ),
    );
  }

  Future<void> _openEditGoalsPage() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditGoalsPage(initialGoals: _goals, onSave: _saveGoalChanges),
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

  void _openHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryPage()),
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
                      onOpenHistory: _openHistoryPage,
                      onEditProfile: _openEditProfilePage,
                    ),
                    const SizedBox(height: 18),
                    WellnessProfileCard(
                      lifestyleType: _lifestyleType,
                      currentRole: _userType ?? 'Not set',
                      usualSleepTime: _usualSleepTime,
                      usualWakeTime: _usualWakeTime,
                      workIntensity: _workIntensity,
                      burnoutLevel: _initialBurnoutLevel,
                      burnoutScore: _initialBurnoutScore,
                      isSaving: _isSavingWellness,
                      onEdit: _openEditWellnessProfilePage,
                    ),
                    const SizedBox(height: 18),
                    MyGoalsCard(
                      goals: _goals,
                      isSaving: _isSavingGoals,
                      onEdit: _openEditGoalsPage,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
