import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../features/auth/presentation/pages/loading_screen.dart';
import '../features/tutorial/services/core_tutorial_service.dart';
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
  static const MethodChannel _appLaunchChannel = MethodChannel(
    'vitalysync/app_launch',
  );

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
    _appLaunchChannel.setMethodCallHandler(_handleAppLaunchMethodCall);
    unawaited(_consumeInitialAppLaunchPayload());
    _handlePreferencesChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _preferences.notifier.removeListener(_handlePreferencesChanged);
    LocalNotificationService.instance.onNotificationPayload = null;
    _appLaunchChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = _preferences.notifier.value;
    if (!prefs.isLoaded) {
      return;
    }

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
    final prefs = _preferences.notifier.value;
    if (!prefs.isLoaded) {
      return;
    }

    OverlayAssistantController.instance.syncSettings(prefs);
  }

  Future<void> _consumeInitialAppLaunchPayload() async {
    try {
      final payload = await _appLaunchChannel.invokeMethod<String>(
        'consumeInitialPayload',
      );
      final normalized = payload?.trim();
      if (normalized == null || normalized.isEmpty) {
        return;
      }

      LocalNotificationService.instance.rememberPendingPayload(normalized);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<dynamic> _handleAppLaunchMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'launchPayload':
        final payload = call.arguments?.toString().trim() ?? '';
        if (payload.isNotEmpty) {
          await _handleNotificationPayload(payload);
        }
        break;
    }

    return null;
  }

  Future<void> _handleNotificationPayload(String payload) async {
    final session = await UserSessionController.instance.load();
    if (!session.isLoggedIn ||
        !session.hasAuthToken ||
        session.userId == null) {
      return;
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      LocalNotificationService.instance.rememberPendingPayload(payload);
      return;
    }

    final userId = session.userId!;
    final showTutorialOnStart = await CoreTutorialService.instance
        .shouldShowForUser(userId);

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigation(
          initialTab: tabForNotificationPayload(payload),
          openNutritionLogOnStart: shouldOpenNutritionLog(payload),
          tutorialUserId: userId,
          showTutorialOnStart: showTutorialOnStart,
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
