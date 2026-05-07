import 'package:flutter/material.dart';
import 'app/app.dart';
import 'shared/assistant/overlay_assistant_entry.dart';
import 'shared/notifications/local_notification_service.dart';
import 'shared/preferences/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferencesController.instance.load();
  await LocalNotificationService.instance.initialize();
  await LocalNotificationService.instance
      .refreshReminderScheduleFromPreferences();

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> overlayAssistantMain() async {
  await runOverlayAssistantApp();
}  
 