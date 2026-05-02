import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:assignment_tracker/models/task_model.dart';
import 'package:assignment_tracker/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _ringEnabledKey = 'ring_enabled';

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

  static Future<bool> isRingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ringEnabledKey) ?? true;
  }

  static Future<void> setRingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ringEnabledKey, enabled);

    if (await areNotificationsEnabled()) {
      await AwesomeNotifications().cancelAllSchedules();
      await _rescheduleAllPendingTaskNotifications();
    }
  }

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
    int baseId = task.id.hashCode;

    final ringEnabled = await isRingEnabled();
    String activeChannelKey = ringEnabled
        ? 'task_channel_sound'
        : 'task_channel_silent';

    if (task.dueDate.isAfter(DateTime.now())) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId,
          channelKey: activeChannelKey,
          title: '🚨 Deadline Reached!',
          body: 'Your ${task.type.toLowerCase()} "${task.title}" is due now!',
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          icon: 'resource://drawable/notification_icon',
          largeIcon: 'asset://assets/images/orb_icon.png',
        ),
        schedule: NotificationCalendar.fromDate(
          date: task.dueDate,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    }

    for (int i = 0; i < task.reminders.length; i++) {
      String reminderString = task.reminders[i];
      DateTime? reminderTime = _calculateReminderTime(
        task.dueDate,
        reminderString,
      );

      if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: baseId + i + 1,
            channelKey: activeChannelKey,
            title: '⏰ Reminder for ${task.title}',
            body: 'Due in $reminderString.',
            notificationLayout: NotificationLayout.Default,
            displayOnForeground: true,
            icon: 'resource://drawable/notification_icon',
            largeIcon: 'asset://assets/images/orb_icon.png',
          ),
          schedule: NotificationCalendar.fromDate(
            date: reminderTime,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

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
