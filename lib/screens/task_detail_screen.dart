import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:assignment_tracker/utils/string_extensions.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';
import '../services/db_helper.dart';
import 'new_task_sheet.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final bool isFromHistory;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    this.isFromHistory = false,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task currentTask;
  int _marks = 0;

  @override
  void initState() {
    super.initState();
    currentTask = widget.task;
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final prefs = await SharedPreferences.getInstance();
    int marks = 0;
    if (currentTask.type.toUpperCase() == 'ASSIGNMENT') {
      marks = prefs.getInt('marks_ASSIGNMENT') ?? 0;
    } else if (currentTask.type.toUpperCase() == 'QUIZ') {
      marks = prefs.getInt('marks_QUIZ') ?? 0;
    } else if (currentTask.type.toUpperCase() == 'PROJECT') {
      marks = prefs.getInt('marks_PROJECT') ?? 0;
    }

    if (mounted) {
      setState(() {
        _marks = marks;
      });
    }
  }

  Future<void> _shareToAI() async {
    final type = currentTask.type.toUpperCase();
    String aiPrompt = '';

    if (type == 'ASSIGNMENT') {
      aiPrompt =
          'I have an assignment to complete. Please review the title, description, and any attached files. Generate an outline, suggest key points, and provide resources or step-by-step guidance to solve this assignment effectively.';
    } else if (type == 'QUIZ') {
      aiPrompt =
          'I have a quiz coming up. Please review the provided topics, title, and files. Generate a study guide, practice questions, and flashcard concepts to help me prepare for this quiz.';
    } else if (type == 'PROJECT') {
      aiPrompt =
          'I am working on a project. Please analyze the project goal, description, and attached files. Provide a structured project plan, timeline, tech stack recommendations, or architecture ideas to execute this project successfully.';
    } else {
      aiPrompt =
          'Please review the details and provide insights related to this task.';
    }

    final String textToShare =
        '''
Title: ${currentTask.title}
Desc: ${currentTask.description ?? 'No description'}
Due Date: ${DateFormat('yyyy-MM-dd').format(currentTask.dueDate)}
Marks: $_marks
Type: ${currentTask.type.toSentenceCase()}

Detailed Prompts:
$aiPrompt''';

    if (currentTask.attachmentPaths != null &&
        currentTask.attachmentPaths!.isNotEmpty) {
      try {
        // Copy text to clipboard to ensure AI tools get it as a fallback
        await Clipboard.setData(ClipboardData(text: textToShare));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Prompt copied to clipboard. You can paste it if the app only reads the file!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        final List<XFile> validFiles = [];
        for (var path in currentTask.attachmentPaths!) {
          try {
            // Check if file physically exists before attempting to share securely
            final f = File(path);
            if (await f.exists()) {
              validFiles.add(XFile(path));
            }
          } catch (e) {}
        }

        if (validFiles.isNotEmpty) {
          await Share.shareXFiles(validFiles, text: textToShare);
        } else {
          // Provide fallback warning if OS auto-deleted the temp file since creation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Attachments expired or missing on this device. Just sending text prompt.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          await Share.share(textToShare);
        }
      } catch (e) {
        debugPrint('File sharing failed: $e');
        // Fallback or just share text
        await Share.share(textToShare);
      }
    } else {
      await Share.share(textToShare);
    }
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
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 27.w),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assignments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!widget.isFromHistory)
            TextButton(
              onPressed: () async {
                final Task? updatedTask = await showCupertinoModalSheet<Task>(
                  context: context,
                  builder: (context) => NewTaskSheet(taskToEdit: currentTask),
                );

                if (updatedTask != null) {
                  await DatabaseHelper.instance.updateTask(updatedTask);

                  if (mounted) {
                    setState(() {
                      currentTask = updatedTask;
                    });
                    _loadMarks();
                  }
                }
              },
              child: Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.1.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    currentTask.type.toSentenceCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                if (currentTask.isHighPriority)
                  Text(
                    'Urgent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // Title
            Text(
              currentTask.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 16.h),

            // Due Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  // Updated format: Day, Month Date, Year • Time
                  'Due ${DateFormat('EEEE, MMM d, yyyy • h:mm a').format(currentTask.dueDate)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // Status Card
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.r),
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
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_turned_in_outlined,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(
                        context,
                        true,
                      ); // Return true to signify completion
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 13.6.h),
                      decoration: BoxDecoration(
                        color: currentTask.isCompleted
                            ? Colors.green
                            : const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(30.r),
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.check_circle_outline,
                            color: currentTask.isCompleted
                                ? Colors.white
                                : Colors.black,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time left',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              val1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44.sp,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              unit1,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (val2.isNotEmpty) ...[
                              SizedBox(width: 12.w),
                              Text(
                                val2,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 44.sp,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                unit2,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14.sp,
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
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marks',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '$_marks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44.sp,
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
            SizedBox(height: 32.h),

            // Notes & Instructions
            Text(
              'Notes & Instructions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                currentTask.description ?? 'No description provided.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15.sp,
                  height: 1.6,
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // Attachments Header
            Text(
              'Attachments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            // Dynamic Attachments List
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.r),
              ),
              padding: EdgeInsets.all(20.w),
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
                            margin: EdgeInsets.only(bottom: 6.8.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, color: Colors.white, size: 15.3.w),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.open_in_new,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 18.sp,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            SizedBox(height: 32.h),

            // Share to AI Button
            GestureDetector(
              onTap: _shareToAI,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 13.6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Share to AI',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.ios_share,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 48.h),
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
          size: 28.sp,
        ),
        SizedBox(width: 16.w),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            decoration: isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
