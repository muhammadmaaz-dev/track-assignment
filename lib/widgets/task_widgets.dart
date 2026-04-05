import 'package:assignment_tracker/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      margin: EdgeInsets.only(bottom: 13.6.h),
      padding: EdgeInsets.all(17.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.5.w,
                  vertical: 3.4.h,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isBright ? Colors.grey.shade300 : Colors.transparent,
                  ),
                  color: isBright ? Colors.transparent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  task.type.toSentenceCase(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11.sp,
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
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'DUE ${DateFormat('h:mm a').format(task.dueDate)}',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            task.title,
            style: TextStyle(
              color: textColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),

          SizedBox(height: 20.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 14.sp, color: subtitleColor),
              SizedBox(width: 8.w),
              Text(
                'Due today',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11.sp,
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
      padding: EdgeInsets.symmetric(vertical: 13.6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_formatDate(task.dueDate).toSentenceCase()} • ${task.type.toSentenceCase()}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingDate = DateTime(date.year, date.month, date.day);

    if (upcomingDate == today.add(const Duration(days: 1))) {
      return 'Due tomorrow';
    } else {
      return 'DUE ${DateFormat('EEEE').format(date)}'; // Extends to DUE FRIDAY, etc.
    }
  }
}
