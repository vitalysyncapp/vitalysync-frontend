import 'package:flutter/material.dart';
import 'app/app.dart';
import 'shared/assistant/overlay_assistant_entry.dart';
import 'shared/background/background_wellness_entry.dart';
import 'shared/notifications/local_notification_service.dart';
import 'shared/preferences/web_preferences_repair.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await repairWebSharedPreferencesStorage();  
  _initializeStartupServices();
  runApp(const MyApp());
}

Future<void> _initializeStartupServices() async {
  try {
    await LocalNotificationService.instance.initialize();
    await LocalNotificationService.instance
        .refreshReminderScheduleFromPreferences();
  } catch (error, stackTrace) {
    debugPrint('Unable to initialize startup services: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

@pragma('vm:entry-point')
Future<void> overlayAssistantMain() async {
  await runOverlayAssistantApp();
}

@pragma('vm:entry-point')
Future<void> backgroundWellnessMain() async {
  await runBackgroundWellnessCollection();
}
