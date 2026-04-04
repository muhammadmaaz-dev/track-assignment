import 'package:flutter/material.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:assignment_tracker/utils/string_extensions.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import 'package:open_filex/open_filex.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';
import '../services/db_helper.dart'; // NEW IMPORT
import 'new_task_sheet.dart'; // NEW IMPORT

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task currentTask;

  @override
  void initState() {
    super.initState();
    // Start by showing the task passed from the Home Screen
    currentTask = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. REAL-TIME CALCULATIONS START ---
    final now = DateTime.now();
    final difference = currentTask.dueDate.difference(
      now,
    ); // Updated to currentTask

    String val1 = '';
    String unit1 = '';
    String val2 = '';
    String unit2 = '';
    String currentStatus = 'In Progress';
    Color statusIconColor = Colors.white;

    if (difference.isNegative) {
      val1 = '0';
      unit1 = 'Late';
      currentStatus = 'Overdue';
      statusIconColor = Colors.redAccent;
    } else if (difference.inDays > 0) {
      val1 = difference.inDays.toString();
      unit1 = 'd'; // Days
      int remHours = difference.inHours % 24;
      if (remHours > 0) {
        val2 = remHours.toString();
        unit2 = 'h'; // Hours
      }
    } else if (difference.inHours > 0) {
      val1 = difference.inHours.toString();
      unit1 = 'h'; // Hours
      int remMins = difference.inMinutes % 60;
      if (remMins > 0) {
        val2 = remMins.toString();
        unit2 = 'm'; // Mins
      }
    } else {
      val1 = difference.inMinutes.toString();
      unit1 = 'm'; // Mins
    }
    // --- REAL-TIME CALCULATIONS END ---

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Assignments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              // 1. Open the NewTaskSheet and pass the current task
              final Task? updatedTask = await showCupertinoModalSheet<Task>(
                context: context,
                builder: (context) => NewTaskSheet(taskToEdit: currentTask),
              );

              // 2. If the user saved changes (didn't cancel)
              if (updatedTask != null) {
                // Save the updated data directly to the database
                await DatabaseHelper.instance.updateTask(updatedTask);

                // Refresh this detail screen instantly
                if (mounted) {
                  setState(() {
                    currentTask = updatedTask;
                  });
                }
              }
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentTask.type.toSentenceCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (currentTask.isHighPriority)
                  const Text(
                    'Urgent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              currentTask.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Due Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  // Updated format: Day, Month Date, Year • Time
                  'Due ${DateFormat('EEEE, MMM d, yyyy • h:mm a').format(currentTask.dueDate)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStatus,
                            style: TextStyle(
                              color: currentStatus == 'Overdue'
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(
                        context,
                        true,
                      ); // Return true to signify completion
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: currentTask.isCompleted
                            ? Colors.green
                            : const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentTask.isCompleted
                                ? 'Completed'
                                : 'Mark as complete',
                            style: TextStyle(
                              color: currentTask.isCompleted
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_outline,
                            color: currentTask.isCompleted
                                ? Colors.white
                                : Colors.black,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time left',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              val1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unit1,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (val2.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Text(
                                val2,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                unit2,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marks',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Notes & Instructions
            const Text(
              'Notes & Instructions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                currentTask.description ?? 'No description provided.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Attachments Header
            const Text(
              'Attachments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Attachments List
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(20),
              child:
                  (currentTask.attachmentPaths == null ||
                      currentTask.attachmentPaths!.isEmpty)
                  ? Text(
                      'No attachments provided.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: currentTask.attachmentPaths!.map((filePath) {
                        String fileName = filePath.split('/').last;
                        String extension = fileName
                            .split('.')
                            .last
                            .toLowerCase();

                        IconData icon = Icons.insert_drive_file_outlined;
                        if (extension == 'pdf')
                          icon = Icons.picture_as_pdf_outlined;
                        if (['jpg', 'jpeg', 'png'].contains(extension))
                          icon = Icons.image_outlined;

                        return GestureDetector(
                          onTap: () async {
                            await OpenFilex.open(filePath);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, color: Colors.white, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.open_in_new,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isChecked) {
    return Row(
      children: [
        Icon(
          isChecked ? Icons.check_box : Icons.check_box_outline_blank,
          color: isChecked ? Colors.white : Colors.white.withOpacity(0.3),
          size: 28,
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
