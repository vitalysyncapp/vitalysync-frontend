import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';
import '../../features/adaptive/data/adaptive_nudge_api.dart';
import '../notifications/local_notification_service.dart';
import '../preferences/app_preferences.dart';
import 'floating_smart_nudge_assistant.dart';
import 'overlay_assistant_controller.dart';

Future<void> runOverlayAssistantApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferencesController.instance.load();
  await LocalNotificationService.instance.initialize();
  runApp(const _OverlayAssistantApp());
}

enum _OverlayAssistantMode { bubble, panel }

class _OverlayAssistantApp extends StatelessWidget {
  const _OverlayAssistantApp();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: AppPreferencesController.instance.notifier,
      builder: (context, prefs, _) {
        Intl.defaultLocale = prefs.locale.languageCode;

        return MaterialApp(
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
          home: const _OverlayAssistantShell(),
        );
      },
    );
  }
}

class _OverlayAssistantShell extends StatefulWidget {
  const _OverlayAssistantShell();

  @override
  State<_OverlayAssistantShell> createState() => _OverlayAssistantShellState();
}

class _OverlayAssistantShellState extends State<_OverlayAssistantShell> {
  static const MethodChannel _channel = MethodChannel(
    'vitalysync/assistant_overlay/window',
  );

  _OverlayAssistantMode _mode = _OverlayAssistantMode.bubble;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (!mounted) {
      return null;
    }

    switch (call.method) {
      case 'setOverlayMode':
        final modeName = call.arguments?.toString() ?? 'bubble';
        setState(() {
          _mode = modeName == 'panel'
              ? _OverlayAssistantMode.panel
              : _OverlayAssistantMode.bubble;
        });
        break;
    }

    return null;
  }

  Future<void> _collapsePanel() async {
    setState(() {
      _mode = _OverlayAssistantMode.bubble;
    });
    await OverlayAssistantController.instance.collapseOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _mode == _OverlayAssistantMode.panel
            ? SafeArea(
                key: const ValueKey('overlay-panel'),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AssistantExperiencePanel(
                      message:
                          "You're doing well today. Log sleep and hydration to keep your streak going.",
                      emoji: '\u{1F499}',
                      onRefreshRecommendations: () async {},
                      onRefreshAdaptiveNudges: () async {
                        try {
                          final response =
                              await AdaptiveNudgeApi.fetchRecommendations(
                                limit: 3,
                              );
                          return response.recommendations;
                        } catch (_) {
                          return const [];
                        }
                      },
                      recommendations: const [],
                      adaptiveNudges: const [],
                      useSafeAreaPadding: false,
                      onClose: _collapsePanel,
                    ),
                  ),
                ),
              )
            : const Center(
                key: ValueKey('overlay-bubble'),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: AssistantFloatingBubbleVisual(),
                ),
              ),
      ),
    );
  }
}
