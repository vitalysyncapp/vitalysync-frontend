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
    final usernameController = TextEditingController(text: _username), emailController = TextEditingController(text: _email), ageController = TextEditingController(text: _age == null ? '' : _age.toString()), sleepController = TextEditingController(text: _sleepSchedule), waterGoalController = TextEditingController(text: _waterGoal), exerciseTargetController = TextEditingController(text: _exerciseTarget);
    String? selectedGender = _gender, selectedUserType = _userType;
    var selectedLifestyle = _lifestyleType, selectedIntensity = _workIntensity;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(color: isDark ? const Color(0xFF162033) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Form(
                    key: formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: isDark ? Colors.white24 : const Color(0xFFD3DAE6), borderRadius: BorderRadius.circular(20)))),
                      const SizedBox(height: 18),
                      Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: pagePrimaryTextColor(context))),
                      const SizedBox(height: 18),
                      _buildTextField(context: context, controller: usernameController, label: 'Username', validator: (value) => value == null || value.trim().isEmpty ? 'Enter a username' : null),
                      const SizedBox(height: 12),
                      _buildTextField(
                        context: context,
                        controller: emailController,
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
                      _buildTextField(context: context, controller: ageController, label: 'Age', keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildDropdownField(context: context, label: 'Gender', value: selectedGender, items: const ['Male', 'Female', 'Other'], onChanged: (value) => setModalState(() => selectedGender = value)),
                      const SizedBox(height: 12),
                      _buildDropdownField(context: context, label: 'Current Role', value: selectedUserType, items: const ['Student', 'Working Professional', 'Young Professional', 'Freelance', 'Self-Employed', 'Others'], onChanged: (value) => setModalState(() => selectedUserType = value)),
                      const SizedBox(height: 12),
                      _buildDropdownField(context: context, label: 'Lifestyle Type', value: selectedLifestyle, items: const ['Sedentary', 'Balanced', 'Active'], onChanged: (value) { if (value != null) setModalState(() => selectedLifestyle = value); }),
                      const SizedBox(height: 12),
                      _buildDropdownField(context: context, label: 'Work Intensity', value: selectedIntensity, items: const ['Low', 'Medium', 'High'], onChanged: (value) { if (value != null) setModalState(() => selectedIntensity = value); }),
                      const SizedBox(height: 12),
                      _buildTextField(context: context, controller: sleepController, label: 'Sleep Schedule'),
                      const SizedBox(height: 12),
                      _buildTextField(context: context, controller: waterGoalController, label: 'Daily Water Goal'),
                      const SizedBox(height: 12),
                      _buildTextField(context: context, controller: exerciseTargetController, label: 'Exercise Target'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            final didSave = await _saveProfileChanges(
                              username: usernameController.text.trim(),
                              email: emailController.text.trim(),
                              age: int.tryParse(ageController.text.trim()),
                              gender: selectedGender,
                              userType: selectedUserType,
                              lifestyleType: selectedLifestyle,
                              workIntensity: selectedIntensity,
                              sleepSchedule: sleepController.text.trim(),
                              waterGoal: waterGoalController.text.trim(),
                              exerciseTarget: exerciseTargetController.text.trim(),
                            );
                            if (didSave && mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    usernameController.dispose(); emailController.dispose(); ageController.dispose(); sleepController.dispose(); waterGoalController.dispose(); exerciseTargetController.dispose();
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
          padding: const EdgeInsets.all(16),
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
