import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../features/auth/presentation/pages/loading_screen.dart';
import '../shared/assistant/overlay_assistant_controller.dart';
import '../shared/notifications/local_notification_service.dart';
import '../shared/notifications/notification_payload_router.dart';
import '../shared/preferences/app_preferences.dart';
import '../shared/preferences/user_session.dart';
import 'app_theme.dart';
import 'main_navigation.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppPreferencesController _preferences =
      AppPreferencesController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preferences.load();
    _preferences.notifier.addListener(_handlePreferencesChanged);
    LocalNotificationService.instance.onNotificationPayload =
        _handleNotificationPayload;
    _handlePreferencesChanged();
    OverlayAssistantController.instance.syncAppLifecycle(
      isForeground: true,
      prefs: _preferences.notifier.value,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _preferences.notifier.removeListener(_handlePreferencesChanged);
    LocalNotificationService.instance.onNotificationPayload = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = _preferences.notifier.value;
    final isForeground = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive => false,
      AppLifecycleState.hidden => false,
      AppLifecycleState.paused => false,
      AppLifecycleState.detached => false,
    };

    OverlayAssistantController.instance.syncAppLifecycle(
      isForeground: isForeground,
      prefs: prefs,
    );
  }

  void _handlePreferencesChanged() {
    OverlayAssistantController.instance.syncSettings(
      _preferences.notifier.value,
    );
  }

  Future<void> _handleNotificationPayload(String payload) async {
    final session = await UserSessionController.instance.load();
    if (!session.isDemoMode && session.userId == null) {
      return;
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      LocalNotificationService.instance.rememberPendingPayload(payload);
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigation(
          initialIndex: tabIndexForNotificationPayload(payload),
          openNutritionLogOnStart: shouldOpenNutritionLog(payload),
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: _preferences.notifier,
      builder: (context, prefs, _) {
        Intl.defaultLocale = prefs.locale.languageCode;

        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'VitalySync',
          debugShowCheckedModeBanner: false,
          locale: prefs.locale,
          supportedLocales: const [Locale('en'), Locale('fil')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: prefs.themeMode,
          theme: buildVitalySyncLightTheme(),
          darkTheme: buildVitalySyncDarkTheme(),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(prefs.textScaleFactor),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const LoadingScreen(),
        );
      },
    );
  }
}
