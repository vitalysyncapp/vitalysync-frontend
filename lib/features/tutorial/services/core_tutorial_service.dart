import 'package:shared_preferences/shared_preferences.dart';

class CoreTutorialService {
  CoreTutorialService._();

  static final CoreTutorialService instance = CoreTutorialService._();

  static const String storageKeyPrefix = 'core_tutorial_';

  String _pendingKey(int userId) => '${storageKeyPrefix}pending_$userId';
  String _completedKey(int userId) => '${storageKeyPrefix}completed_$userId';

  Future<void> markPendingForUser(int userId) async {
    if (userId <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_completedKey(userId)) ?? false;
    if (completed) {
      return;
    }

    await prefs.setBool(_pendingKey(userId), true);
  }

  Future<bool> shouldShowForUser(int userId) async {
    if (userId <= 0) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingKey(userId)) ?? false;
    final completed = prefs.getBool(_completedKey(userId)) ?? false;
    return pending && !completed;
  }

  Future<void> completeForUser(int userId) async {
    if (userId <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey(userId), true);
    await prefs.remove(_pendingKey(userId));
  }
}
