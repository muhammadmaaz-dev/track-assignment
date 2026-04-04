import 'package:assignment_tracker/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // NAYA IMPORT
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  // NAYA CODE: Async setup ke liye ensureInitialized zaroori hai
  WidgetsFlutterBinding.ensureInitialized();

  // NAYA CODE: Notification Initialize karein
  AwesomeNotifications().initialize(
    // aapka icon yahan hoga (e.g., 'resource://drawable/res_app_icon')
    null,
    [
      // 1. Channel for Sound (Bypasses Silent Mode if permission granted)
      NotificationChannel(
        channelKey: 'task_channel_sound',
        channelName: 'Task Alerts with Sound',
        channelDescription: 'Plays sound even on silent',
        playSound: true,
        criticalAlerts:
            true, // Yeh silent mode bypass karne ke liye zaroori hai
        importance: NotificationImportance.Max,
        defaultColor: Colors.deepPurple,
        ledColor: Colors.white,
      ),
      // 2. Channel for Silent
      NotificationChannel(
        channelKey: 'task_channel_silent',
        channelName: 'Task Alerts Silent',
        channelDescription: 'Notifications without sound',
        playSound: false, // Yahan sound off hai
        importance: NotificationImportance.High,
        defaultColor: Colors.deepPurple,
        ledColor: Colors.white,
      ),
    ],
  );

  runApp(const ProviderScope(child: MyApp()));
}

// NAYA CODE: StatelessWidget se StatefulWidget mein convert kiya
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // NAYA CODE: App open hotay hi notification permission check aur request karega
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
    return MaterialApp(
      title: 'Ordo',
      debugShowCheckedModeBanner: false,

      // Cupertino Widgets (iOS date picker) ko support karne ke liye
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English support
      ],

      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
