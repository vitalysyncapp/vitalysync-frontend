import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
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
  static const List<String> _roleOptions = ['Student', 'Working Professional', 'Young Professional', 'Freelance', 'Self-Employed', 'Others'];
  static const List<String> _lifestyleOptions = ['Sedentary', 'Balanced', 'Active'];
  static const List<String> _workIntensityOptions = ['Low', 'Medium', 'High'];

  bool _isLoading = true, _isSaving = false, _isDemoMode = false;
  int? _userId, _age;
  String _username = 'User Name', _email = 'user@email.com';
  String? _gender, _userType;
  String _sleepSchedule = '10:30 PM - 6:30 AM', _lifestyleType = 'Balanced', _workIntensity = 'Medium', _waterGoal = '2.5 L', _exerciseTarget = '3 days/week';
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

  String _workIntensityFromHours(int hours) => hours >= 10 ? 'High' : hours >= 7 ? 'Medium' : 'Low';
  int _workHoursFromIntensity(String intensity) => intensity.toLowerCase() == 'high' ? 10 : intensity.toLowerCase() == 'low' ? 6 : 8;
  String _waterGoalFromActivity(String activity) => activity.toLowerCase() == 'active' ? '3.0 L' : activity.toLowerCase() == 'sedentary' ? '2.0 L' : '2.5 L';

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

  String _buildSleepSchedule({required String? sleepTime, required String? wakeTime, required String fallback}) {
    if (sleepTime == null || wakeTime == null) return fallback;
    return '${_formatTimeForDisplay(sleepTime)} - ${_formatTimeForDisplay(wakeTime)}';
  }

  String? _convertDisplayTimeTo24Hour(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(value.trim().toUpperCase());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!), minute = int.tryParse(match.group(2)!);
    final period = match.group(3);
    if (hour == null || minute == null || period == null) return null;
    var militaryHour = hour % 12;
    if (period == 'PM') militaryHour += 12;
    return '${militaryHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Map<String, String?> _parseSleepSchedule(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return const {'sleep': null, 'wake': null};
    return {'sleep': _convertDisplayTimeTo24Hour(parts[0]), 'wake': _convertDisplayTimeTo24Hour(parts[1])};
  }

  int _parseExerciseDays(String value) => int.tryParse(RegExp(r'(\d+)').firstMatch(value)?.group(1) ?? '') ?? 3;

  Future<void> _loadProfile() async {
    final session = await UserSessionController.instance.load();
    final prefs = await SharedPreferences.getInstance();
    var sleepSchedule = prefs.getString(_sleepScheduleKey) ?? '10:30 PM - 6:30 AM';
    var lifestyleType = 'Balanced', workIntensity = 'Medium', waterGoal = prefs.getString(_waterGoalKey) ?? '2.5 L', exerciseTarget = '3 days/week';

    if (!session.isDemoMode && session.userId != null) {
      try {
        final summary = await OnboardingApi.fetchSummary(session.userId!);
        final onboarding = Map<String, dynamic>.from(summary['onboarding'] as Map? ?? {});
        final preferences = Map<String, dynamic>.from(summary['preferences'] as Map? ?? {});
        final activity = _emptyToNull(onboarding['activity_level']?.toString()) ?? 'Balanced';
        final workHours = int.tryParse('${onboarding['work_hours_per_day'] ?? ''}') ?? 8;
        final exerciseDays = int.tryParse('${onboarding['exercise_days_per_week'] ?? ''}') ?? 3;
        lifestyleType = activity;
        workIntensity = _workIntensityFromHours(workHours);
        waterGoal = _waterGoalFromActivity(activity);
        exerciseTarget = '$exerciseDays days/week';
        sleepSchedule = _buildSleepSchedule(
          sleepTime: _emptyToNull(preferences['default_sleep_time']?.toString()),
          wakeTime: _emptyToNull(preferences['default_wake_time']?.toString()),
          fallback: sleepSchedule,
        );
        await prefs.setString(_sleepScheduleKey, sleepSchedule);
        await prefs.setString(_waterGoalKey, waterGoal);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _userId = session.userId;
      _username = session.username?.isNotEmpty == true ? session.username! : 'User Name';
      _email = session.email?.isNotEmpty == true ? session.email! : 'user@email.com';
      _age = session.age;
      _gender = _emptyToNull(session.gender);
      _userType = _emptyToNull(session.userType);
      _isDemoMode = session.isDemoMode;
      _sleepSchedule = sleepSchedule;
      _lifestyleType = lifestyleType;
      _workIntensity = workIntensity;
      _waterGoal = waterGoal;
      _exerciseTarget = exerciseTarget;
      _currentStreak = prefs.getInt('log_streak') ?? 0;
      _longestStreak = prefs.getInt('longest_log_streak') ?? 0;
      _isLoading = false;
    });
  }

  String getAvatarImage(String? gender, String? userType) {
    if (gender == null || userType == null) return 'assets/images/user.png';
    if (gender.toLowerCase() == 'male') return userType == 'Student' ? 'assets/images/male Student.png' : 'assets/images/business-man.png';
    if (gender.toLowerCase() == 'female') return userType == 'Student' ? 'assets/images/female Student.png' : 'assets/images/businesswoman.png';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile can only be edited after a session is loaded.')));
      return false;
    }
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final scheduleParts = _parseSleepSchedule(sleepSchedule);
      final normalizedSleep = _fallbackValue(sleepSchedule, '10:30 PM - 6:30 AM');
      final normalizedWater = _fallbackValue(waterGoal, '2.5 L');
      final normalizedExercise = '${_parseExerciseDays(exerciseTarget)} days/week';
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
        final existingOnboarding =
            Map<String, dynamic>.from(summary['onboarding'] as Map? ?? {});
        final existingPreferences =
            Map<String, dynamic>.from(summary['preferences'] as Map? ?? {});
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isDemoMode ? 'Profile updated locally for demo mode.' : 'Profile updated successfully.')));
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to update profile: $error')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showEditProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditProfileSheet(
        initialUsername: _username,
        initialEmail: _email,
        initialAge: _age,
        initialGender: _dropdownValueOrNull(_gender, _genderOptions),
        initialUserType: _dropdownValueOrNull(
          _userType,
          _roleOptions,
          aliases: const {
            'freelancer': 'Freelance',
            'self employed': 'Self-Employed',
            'working professional': 'Working Professional',
            'young professional': 'Young Professional',
            'other': 'Others',
          },
        ),
        initialLifestyle: _dropdownValueOrNull(_lifestyleType, _lifestyleOptions) ?? 'Balanced',
        initialWorkIntensity: _dropdownValueOrNull(_workIntensity, _workIntensityOptions) ?? 'Medium',
        initialSleepSchedule: _sleepSchedule,
        initialWaterGoal: _waterGoal,
        initialExerciseTarget: _exerciseTarget,
        onSave: ({
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
    );
  }

  Widget _buildTextField({required BuildContext context, required TextEditingController controller, required String label, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: pageBorderColor(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }

  Widget _buildDropdownField({required BuildContext context, required String label, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: pageBorderColor(context))),
      ),
      items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
    );
  }

  Widget _infoTile({required BuildContext context, required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: iconColor, size: 24)),
      title: Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: pagePrimaryTextColor(context))),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: TextStyle(fontSize: 13.5, color: pageSecondaryTextColor(context))),
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
          leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: pagePrimaryTextColor(context)), onPressed: () => Navigator.pop(context)),
          title: Text('Profile', style: TextStyle(color: pagePrimaryTextColor(context), fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            pageBottomContentPadding(context),
          ),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2F6BFF), Color(0xFF3B82F6), Color(0xFF0891B2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.20), blurRadius: 18, offset: const Offset(0, 10))],
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 92, height: 92,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.14), border: Border.all(color: Colors.white.withOpacity(0.35), width: 2)),
                    child: ClipOval(child: Padding(padding: const EdgeInsets.all(10), child: Image.asset(avatarPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 42, color: Colors.white)))),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(_email, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.92))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(30)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const CircleAvatar(radius: 4, backgroundColor: Color(0xFF4CFF8F)),
                        const SizedBox(width: 8),
                        Text(_isDemoMode ? 'Demo Mode' : 'Profile Active', style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ])),
                ]),
                const SizedBox(height: 22),
                Divider(color: Colors.white.withOpacity(0.22), thickness: 1),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _StatItem(value: '$_currentStreak', label: 'Current Streak'),
                  _StatItem(value: '$_longestStreak', label: 'Best Streak'),
                  _StatItem(value: _age?.toString() ?? '--', label: 'Age'),
                ]),
              ]),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: pageSurfaceColor(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: pageBorderColor(context)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.06), blurRadius: 16, offset: const Offset(0, 8))]),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: pagePrimaryTextColor(context)))),
                ),
                Divider(height: 1, thickness: 1, color: pageBorderColor(context)),
                _infoTile(context: context, icon: Icons.person_outline, iconBg: const Color(0xFFE8F0FF), iconColor: const Color(0xFF2F6BFF), title: 'Profile Details', subtitle: '${_gender ?? 'Gender not set'} - ${_userType ?? 'Role not set'}'),
                Divider(height: 1, thickness: 1, color: pageBorderColor(context)),
                _infoTile(context: context, icon: Icons.nightlight_round, iconBg: const Color(0xFFE0F2FE), iconColor: const Color(0xFF0891B2), title: 'Sleep Schedule', subtitle: _sleepSchedule),
                Divider(height: 1, thickness: 1, color: pageBorderColor(context)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _showEditProfileSheet,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, side: BorderSide(color: pageBorderColor(context)), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            WellnessProfileCard(lifestyleType: _lifestyleType, currentRole: _userType ?? 'Not set', workIntensity: _workIntensity, waterGoal: _waterGoal, exerciseTarget: _exerciseTarget),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: pageSurfaceColor(context), borderRadius: BorderRadius.circular(22), border: Border.all(color: pageBorderColor(context))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Saved Routine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: pagePrimaryTextColor(context))),
                const SizedBox(height: 12),
                Text('Sleep: $_sleepSchedule', style: TextStyle(color: pageSecondaryTextColor(context))),
                const SizedBox(height: 8),
                Text('Water goal: $_waterGoal', style: TextStyle(color: pageSecondaryTextColor(context))),
                const SizedBox(height: 8),
                Text('Exercise target: $_exerciseTarget', style: TextStyle(color: pageSecondaryTextColor(context))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

typedef _SaveProfileCallback = Future<bool> Function({
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
});

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.initialUsername,
    required this.initialEmail,
    required this.initialAge,
    required this.initialGender,
    required this.initialUserType,
    required this.initialLifestyle,
    required this.initialWorkIntensity,
    required this.initialSleepSchedule,
    required this.initialWaterGoal,
    required this.initialExerciseTarget,
    required this.onSave,
  });

  final String initialUsername;
  final String initialEmail;
  final int? initialAge;
  final String? initialGender;
  final String? initialUserType;
  final String initialLifestyle;
  final String initialWorkIntensity;
  final String initialSleepSchedule;
  final String initialWaterGoal;
  final String initialExerciseTarget;
  final _SaveProfileCallback onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _roleOptions = ['Student', 'Working Professional', 'Young Professional', 'Freelance', 'Self-Employed', 'Others'];
  static const List<String> _lifestyleOptions = ['Sedentary', 'Balanced', 'Active'];
  static const List<String> _workIntensityOptions = ['Low', 'Medium', 'High'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _sleepController;
  late final TextEditingController _waterGoalController;
  late final TextEditingController _exerciseTargetController;

  late String? _selectedGender;
  late String? _selectedUserType;
  late String _selectedLifestyle;
  late String _selectedIntensity;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
    _ageController = TextEditingController(text: widget.initialAge?.toString() ?? '');
    _sleepController = TextEditingController(text: widget.initialSleepSchedule);
    _waterGoalController = TextEditingController(text: widget.initialWaterGoal);
    _exerciseTargetController = TextEditingController(text: widget.initialExerciseTarget);
    _selectedGender = widget.initialGender;
    _selectedUserType = widget.initialUserType;
    _selectedLifestyle = widget.initialLifestyle;
    _selectedIntensity = widget.initialWorkIntensity;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _sleepController.dispose();
    _waterGoalController.dispose();
    _exerciseTargetController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final didSave = await widget.onSave(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        userType: _selectedUserType,
        lifestyleType: _selectedLifestyle,
        workIntensity: _selectedIntensity,
        sleepSchedule: _sleepController.text.trim(),
        waterGoal: _waterGoalController.text.trim(),
        exerciseTarget: _exerciseTargetController.text.trim(),
      );

      if (didSave && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162033) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              pageBottomContentPadding(context),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: isDark ? Colors.white24 : const Color(0xFFD3DAE6), borderRadius: BorderRadius.circular(20)))),
                  const SizedBox(height: 18),
                  Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: pagePrimaryTextColor(context))),
                  const SizedBox(height: 18),
                  _buildSheetTextField(context: context, controller: _usernameController, label: 'Username', validator: (value) => value == null || value.trim().isEmpty ? 'Enter a username' : null),
                  const SizedBox(height: 12),
                  _buildSheetTextField(
                    context: context,
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter an email';
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(text)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSheetTextField(context: context, controller: _ageController, label: 'Age', keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildSheetDropdownField(
                    context: context,
                    label: 'Gender',
                    value: _selectedGender,
                    items: _genderOptions,
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                  const SizedBox(height: 12),
                  _buildSheetDropdownField(
                    context: context,
                    label: 'Current Role',
                    value: _selectedUserType,
                    items: _roleOptions,
                    onChanged: (value) => setState(() => _selectedUserType = value),
                  ),
                  const SizedBox(height: 12),
                  _buildSheetDropdownField(
                    context: context,
                    label: 'Lifestyle Type',
                    value: _selectedLifestyle,
                    items: _lifestyleOptions,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedLifestyle = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSheetDropdownField(
                    context: context,
                    label: 'Work Intensity',
                    value: _selectedIntensity,
                    items: _workIntensityOptions,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedIntensity = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSheetTextField(context: context, controller: _sleepController, label: 'Sleep Schedule'),
                  const SizedBox(height: 12),
                  _buildSheetTextField(context: context, controller: _waterGoalController, label: 'Daily Water Goal'),
                  const SizedBox(height: 12),
                  _buildSheetTextField(context: context, controller: _exerciseTargetController, label: 'Exercise Target'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSave,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSubmitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTextField({required BuildContext context, required TextEditingController controller, required String label, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: pageBorderColor(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }

  Widget _buildSheetDropdownField({required BuildContext context, required String label, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: pageBorderColor(context))),
      ),
      items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 13.5, color: Colors.white.withOpacity(0.88), fontWeight: FontWeight.w500)),
    ]);
  }
}
