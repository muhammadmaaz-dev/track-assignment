import 'package:assignment_tracker/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'Ordo',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.white,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
