import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:assignment_tracker/models/task_model.dart';
import 'package:assignment_tracker/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _ringEnabledKey =
      'ring_enabled'; // Naya key add kiya ring ke liye

  // --- Notifications On/Off Logic ---
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (!enabled) {
      await AwesomeNotifications().cancelAllSchedules();
      await AwesomeNotifications().cancelAll();
      return;
    }

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    await _rescheduleAllPendingTaskNotifications();
  }

  // --- Ring On/Off Logic ---
  static Future<bool> isRingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ringEnabledKey) ?? true;
  }

  static Future<void> setRingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ringEnabledKey, enabled);

    // Agar user ring setting change karta hai, toh notifications
    // naye channel (sound/silent) ke sath reschedule karni padengi
    if (await areNotificationsEnabled()) {
      await AwesomeNotifications().cancelAllSchedules();
      await _rescheduleAllPendingTaskNotifications();
    }
  }

  // --- Scheduling Logic ---
  static Future<void> scheduleTaskNotifications(Task task) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    await _scheduleTaskNotificationsInternal(task);
  }

  static Future<void> _rescheduleAllPendingTaskNotifications() async {
    final allTasks = await DatabaseHelper.instance.getAllTasks();
    final now = DateTime.now();

    for (final task in allTasks) {
      if (task.isCompleted) continue;
      if (task.dueDate.isBefore(now)) continue;

      await _scheduleTaskNotificationsInternal(task);
    }
  }

  static Future<void> _scheduleTaskNotificationsInternal(Task task) async {
    // Basic Task ID ko integer mein convert kar rahe hain notification ID ke liye
    int baseId = task.id.hashCode;

    // Yahan check kar rahe hain ke ring enabled hai ya nahi
    final ringEnabled = await isRingEnabled();
    String activeChannelKey = ringEnabled
        ? 'task_channel_sound'
        : 'task_channel_silent';

    // 1. Due Date par Notification Schedule karna
    if (task.dueDate.isAfter(DateTime.now())) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId,
          channelKey: activeChannelKey, // NAYA CODE: Yahan channel set hoga
          title: '🚨 Deadline Reached!',
          body: 'Your ${task.type.toLowerCase()} "${task.title}" is due now!',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(date: task.dueDate),
      );
    }

    // 2. User ke custom Reminders par Notification Schedule karna
    for (int i = 0; i < task.reminders.length; i++) {
      String reminderString = task.reminders[i];
      DateTime? reminderTime = _calculateReminderTime(
        task.dueDate,
        reminderString,
      );

      if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            // Har reminder ko unique ID dene ke liye index add kiya
            id: baseId + i + 1,
            channelKey: activeChannelKey, // NAYA CODE: Yahan channel set hoga
            title: '⏰ Reminder for ${task.title}',
            body: 'Due in $reminderString.',
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar.fromDate(
            date: reminderTime, // ya task.dueDate
            preciseAlarm:
                true, // NAYA CODE: Android ko force karega exact time par bhejne ke liye
            allowWhileIdle:
                true, // NAYA CODE: Background/Sleep mode mein bhi chalega
          ),
        );
      }
    }
  }

  // String ("10 min before") ko DateTime mein convert karne ka logic
  static DateTime? _calculateReminderTime(
    DateTime dueDate,
    String reminderOption,
  ) {
    Duration duration = Duration.zero;

    if (reminderOption.contains('min')) {
      duration = Duration(minutes: int.parse(reminderOption.split(' ').first));
    } else if (reminderOption.contains('hour')) {
      duration = Duration(hours: int.parse(reminderOption.split(' ').first));
    } else if (reminderOption.contains('day')) {
      duration = Duration(days: int.parse(reminderOption.split(' ').first));
    } else {
      return null;
    }

    return dueDate.subtract(duration);
  }
}
