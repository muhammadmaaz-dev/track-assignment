import 'package:flutter/material.dart';
import 'package:assignment_tracker/theme/constants.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- 1. REAL-TIME CALCULATIONS START ---
    final now = DateTime.now();
    final difference = task.dueDate.difference(now);

    String val1 = '';
    String unit1 = '';
    String val2 = '';
    String unit2 = '';
    String currentStatus = 'In Progress';
    Color statusIconColor = Colors.white;

    if (difference.isNegative) {
      val1 = '0';
      unit1 = 'LATE';
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
            onPressed: () {},
            child: const Text(
              'EDIT',
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
                    task.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (task.isHighPriority)
                  const Text(
                    'URGENT',
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
              task.title,
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
                  'Due ${DateFormat('MMM d, yyyy').format(task.dueDate)}',
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
                            // <-- REMOVE 'const' keyword here
                            currentStatus, // <-- USE DYNAMIC VARIABLE
                            style: TextStyle(
                              // <-- REMOVE 'const' keyword here
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'MARK AS COMPLETE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.black,
                          size: 20,
                        ),
                      ],
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
                          'TIME LEFT',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Inside the TIME LEFT container:
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            // FIRST BIG NUMBER
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
                            // FIRST SMALL TEXT
                            Text(
                              unit1,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // SECOND BIG NUMBER & TEXT (Only shows if there is a remainder)
                            if (val2.isNotEmpty) ...[
                              const SizedBox(width: 12), // Space between groups
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
                          'MARKS',
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                task.description ?? 'No description provided.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Attachments
            const Text(
              'Attachments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAttachmentItem(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Integration_Review.pdf',
              subtitle: '2.4 MB • PDF Document',
            ),
            const SizedBox(height: 12),
            _buildAttachmentItem(
              icon: Icons.image_outlined,
              title: 'Equation_Sheet_v2.jpg',
              subtitle: '850 KB • Image',
            ),
            const SizedBox(height: 32),

            // Checklist
            const Text(
              'Checklist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildChecklistItem('Review Lecture 12 Notes', true),
            const SizedBox(height: 16),
            _buildChecklistItem('Complete Problem Set Draft', false),
            const SizedBox(height: 16),
            _buildChecklistItem('Proofread Final Submission', false),

            const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, color: Colors.white, size: 20),
        ],
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
