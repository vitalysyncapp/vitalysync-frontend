import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../preferences/app_preferences.dart';

/// Prunes locally cached offline wellness logs that exceed the configured
/// retention window ([AppPreferencesState.dataRetentionDays]).
///
/// Call [pruneIfNeeded] once during app startup. A value of `0` means
/// "keep everything" (unlimited retention).
class LocalDataRetentionService {
  LocalDataRetentionService._();

  static final LocalDataRetentionService instance =
      LocalDataRetentionService._();

  /// Scans the offline log cache directory and deletes files older than the
  /// configured retention window.
  Future<void> pruneIfNeeded() async {
    try {
      final prefs = AppPreferencesController.instance.notifier.value;
      final retentionDays = prefs.dataRetentionDays;

      // 0 means unlimited — keep everything.
      if (retentionDays <= 0) {
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/offline_logs');

      if (!cacheDir.existsSync()) {
        return;
      }

      final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
      int pruned = 0;

      for (final entity in cacheDir.listSync()) {
        if (entity is File) {
          final modified = entity.lastModifiedSync();
          if (modified.isBefore(cutoff)) {
            entity.deleteSync();
            pruned++;
          }
        }
      }

      if (pruned > 0) {
        debugPrint(
          'LocalDataRetentionService: pruned $pruned offline log(s) older '
          'than $retentionDays day(s)',
        );
      }
    } catch (error) {
      debugPrint('LocalDataRetentionService: prune failed — $error');
    }
  }
}
