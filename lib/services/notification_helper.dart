import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:assignment_tracker/models/task_model.dart';

class NotificationHelper {
  static Future<void> scheduleTaskNotifications(Task task) async {
    // Basic Task ID ko integer mein convert kar rahe hain notification ID ke liye
    int baseId = task.id.hashCode;

    // 1. Due Date par Notification Schedule karna
    if (task.dueDate.isAfter(DateTime.now())) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId,
          channelKey: 'task_channel',
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
            channelKey: 'task_channel',
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
