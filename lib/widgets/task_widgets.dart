import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class TodaysFocusCard extends StatelessWidget {
  final Task task;

  const TodaysFocusCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isBright = task.isHighPriority;
    Color bgColor = isBright ? Colors.white : const Color(0xFF1E1E1E);
    Color textColor = isBright ? Colors.black : Colors.white;
    Color subtitleColor = isBright ? Colors.black87 : Colors.white70;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isBright ? Colors.grey.shade300 : Colors.transparent,
                  ),
                  color: isBright ? Colors.transparent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.type.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (task.timeString != null)
                Text(
                  task.timeString!,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'DUE ${DateFormat('h:mm a').format(task.dueDate)}',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            task.title,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: subtitleColor),
              const SizedBox(width: 8),
              Text(
                'DUE TODAY',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpcomingTaskTile extends StatelessWidget {
  final Task task;

  const UpcomingTaskTile({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(task.dueDate).toUpperCase()} • ${task.type.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingDate = DateTime(date.year, date.month, date.day);

    if (upcomingDate == today.add(const Duration(days: 1))) {
      return 'DUE TOMORROW';
    } else {
      return 'DUE ${DateFormat('EEEE').format(date)}'; // Extends to DUE FRIDAY, etc.
    }
  }
}
