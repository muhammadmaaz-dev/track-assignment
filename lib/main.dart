import 'package:assignment_tracker/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // NAYA IMPORT

void main() async {
  // NAYA CODE: Async setup ke liye ensureInitialized zaroori hai
  WidgetsFlutterBinding.ensureInitialized();

  // NAYA CODE: Notification Initialize karein
  AwesomeNotifications().initialize(
    null, // Default app icon use karega
    [
      NotificationChannel(
        channelGroupKey: 'task_group',
        channelKey: 'task_channel',
        channelName: 'Task Notifications',
        channelDescription:
            'Notification channel for task deadlines and reminders',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
      ),
    ],
  );

  runApp(const MyApp());
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
      title: 'Assignment Tracker',
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
