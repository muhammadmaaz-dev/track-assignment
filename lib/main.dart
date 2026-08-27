import 'package:assignment_tracker/screens/main_screen.dart';
import 'package:assignment_tracker/screens/onboarding_screen.dart';
import 'package:assignment_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize('resource://drawable/notification_icon', [
    NotificationChannel(
      channelKey: 'task_channel_sound',
      channelName: 'Task Alerts with Sound',
      channelDescription: 'Plays sound even on silent',
      playSound: true,
      criticalAlerts: true,
      importance: NotificationImportance.Max,
      defaultColor: Colors.deepPurple,
      ledColor: Colors.white,
      enableVibration: true,
      enableLights: true,
      icon: 'resource://drawable/notification_icon',
    ),
    NotificationChannel(
      channelKey: 'task_channel_silent',
      channelName: 'Task Alerts Silent',
      channelDescription: 'Notifications without sound',
      playSound: false,
      importance: NotificationImportance.High,
      defaultColor: Colors.deepPurple,
      ledColor: Colors.white,
      enableVibration: true,
      enableLights: true,
      icon: 'resource://drawable/notification_icon',
    ),
  ]);

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(ProviderScope(
    child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
  ));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, this.hasSeenOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'Kato',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        theme: AppTheme.darkTheme,
        home: hasSeenOnboarding
            ? const MainScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
