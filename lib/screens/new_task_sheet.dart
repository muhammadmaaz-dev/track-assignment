import 'dart:ui'; // Required for ImageFilter.blur
import 'package:file_picker/file_picker.dart'; // Required to pick files
import 'package:assignment_tracker/models/task_model.dart';
import 'package:assignment_tracker/services/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_filex/open_filex.dart';

class NewTaskSheet extends StatefulWidget {
  final Task? taskToEdit;

  const NewTaskSheet({super.key, this.taskToEdit});

  @override
  State<NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<NewTaskSheet> {
  String _selectedType = 'Assignment';
  final title = TextEditingController();
  final description = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();

  List<String> _selectedReminders = [];

  // NEW: Store selected file paths before creating the task
  List<String> _attachmentPaths = [];

  final List<String> _reminderOptions = [
    '5 min before',
    '10 min before',
    '20 min before',
    '40 min before',
    '1 hour before',
    '2 hours before',
    '4 hours before',
    '8 hours before',
    '16 hours before',
    '1 day before',
  ];

  @override
  void initState() {
    super.initState();

    // If we passed a task, pre-fill all the fields!
    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;
      title.text = t.title;
      description.text = t.description ?? '';

      // Match the type back to the UI segments
      if (t.type.toUpperCase() == 'ASSIGNMENT')
        _selectedType = 'Assignment';
      else if (t.type.toUpperCase() == 'QUIZ')
        _selectedType = 'Quiz';
      else if (t.type.toUpperCase() == 'PROJECT')
        _selectedType = 'Project';
      else
        _selectedType = t.type;

      _selectedDateTime = t.dueDate;

      if (t.reminders != null) {
        _selectedReminders = List.from(t.reminders!);
      }
      if (t.attachmentPaths != null) {
        _attachmentPaths = List.from(t.attachmentPaths!);
      }
    }
  }

  // NEW: Method to pick files
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        List<String> validPaths = result.paths.whereType<String>().toList();
        for (var path in validPaths) {
          if (!_attachmentPaths.contains(path)) {
            _attachmentPaths.add(path);
          }
        }
      });
    }
  }

  void _openDatePicker(BuildContext btnContext) async {
    final RenderBox? renderBox = btnContext.findRenderObject() as RenderBox?;

    DateTime now = DateTime.now();
    DateTime stableCurrentTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    final DateTime? picked = await showCupertinoCalendarPicker(
      context,
      widgetRenderBox: renderBox,
      initialDateTime: _selectedDateTime.isBefore(stableCurrentTime)
          ? stableCurrentTime
          : _selectedDateTime,
      minimumDateTime: stableCurrentTime,
      maximumDateTime: DateTime(2100),
      mode: CupertinoCalendarMode.dateTime,
    );

    if (picked != null) {
      if (picked.isBefore(stableCurrentTime)) {
        setState(() {
          _selectedDateTime = stableCurrentTime;
        });
        Fluttertoast.showToast(
          msg: 'Cannot select a past time. Adjusted to current time.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
      } else {
        setState(() {
          _selectedDateTime = picked;
        });
      }
    }
  }

  void _showReminderPicker() {
    int tempSelectedIndex = 2; // Default to '20 minutes before'

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Reminder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        String chosenOption =
                            _reminderOptions[tempSelectedIndex];

                        Duration requiredDuration = Duration.zero;
                        if (chosenOption.contains('minute')) {
                          requiredDuration = Duration(
                            minutes: int.parse(chosenOption.split(' ').first),
                          );
                        } else if (chosenOption.contains('hour')) {
                          requiredDuration = Duration(
                            hours: int.parse(chosenOption.split(' ').first),
                          );
                        } else if (chosenOption.contains('day')) {
                          requiredDuration = Duration(
                            days: int.parse(chosenOption.split(' ').first),
                          );
                        }

                        Duration timeUntilDue = _selectedDateTime.difference(
                          DateTime.now(),
                        );

                        if (timeUntilDue <= requiredDuration) {
                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg:
                                'Task is due in less than ${chosenOption.replaceAll(' before', '')}.',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.redAccent,
                            textColor: Colors.white,
                          );
                        } else {
                          setState(() {
                            if (!_selectedReminders.contains(chosenOption)) {
                              _selectedReminders.add(chosenOption);
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Reminder already added!',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.orange,
                                textColor: Colors.white,
                              );
                            }
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: AppColors.surface,
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: tempSelectedIndex,
                  ),
                  onSelectedItemChanged: (int index) {
                    tempSelectedIndex = index;
                  },
                  children: _reminderOptions.map((String option) {
                    return Center(
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    ],
                  ),
                ),
                const Text(
                  'New Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          _buildTypeSegment('Assignment'),
                          _buildTypeSegment('Quiz'),
                          _buildTypeSegment('Project'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Builder(
                    builder: (btnContext) {
                      return _buildActionCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Due Date',
                        value: DateFormat(
                          'MMM d, yyyy - h:mm a',
                        ).format(_selectedDateTime),
                        onTap: () => _openDatePicker(btnContext),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'NOTES / QUESTIONS',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: description,
                          maxLines: 4,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add questions or notes',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap:
                        _pickFiles, // Now the ENTIRE container opens the file picker
                    behavior: HitTestBehavior
                        .opaque, // Ensures tapping on empty space works
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.attach_file,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attachments',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Dynamic Attachments List with Cross Buttons
                                if (_attachmentPaths.isEmpty)
                                  Text(
                                    'Tap anywhere to add files', // Updated UX text
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  )
                                else
                                  ..._attachmentPaths.map((filePath) {
                                    String fileName = filePath.split('/').last;
                                    String extension = fileName
                                        .split('.')
                                        .last
                                        .toLowerCase();

                                    IconData icon =
                                        Icons.insert_drive_file_outlined;
                                    if (extension == 'pdf')
                                      icon = Icons.picture_as_pdf_outlined;
                                    if ([
                                      'jpg',
                                      'jpeg',
                                      'png',
                                    ].contains(extension))
                                      icon = Icons.image_outlined;

                                    return Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(
                                          0.2,
                                        ), // Dark inset background
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.05),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            icon,
                                            color: Colors.white,
                                            size: 18,
                                          ),
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
                                          // Cross button to remove the attachment
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _attachmentPaths.remove(
                                                  filePath,
                                                );
                                              });
                                            },
                                            child: Container(
                                              color: Colors
                                                  .transparent, // Increases touch target size
                                              padding: const EdgeInsets.all(
                                                4.0,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reminders Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showReminderPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _selectedReminders.isEmpty
                      ? Center(
                          child: Text(
                            'Empty',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : Column(
                          children: _selectedReminders.map((reminder) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_active,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        reminder,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedReminders.remove(reminder);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              top: 10,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) {
                    Fluttertoast.showToast(
                      msg: 'Please enter a task title',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                    );
                    return;
                  }

                  if (_selectedDateTime.isBefore(DateTime.now())) {
                    Fluttertoast.showToast(
                      msg: 'Cannot save a task in the past.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                    );
                    return;
                  }

                  Task userCreatedTask;

                  // If editing, use copyWith to preserve the ID and other original states
                  if (widget.taskToEdit != null) {
                    userCreatedTask = widget.taskToEdit!.copyWith(
                      title: title.text.trim(),
                      type: _selectedType.toUpperCase(),
                      dueDate: _selectedDateTime,
                      description: description.text.trim(),
                      reminders: _selectedReminders,
                      attachmentPaths: _attachmentPaths,
                    );
                  } else {
                    // Create brand new task
                    userCreatedTask = Task(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title.text.trim(),
                      type: _selectedType.toUpperCase(),
                      dueDate: _selectedDateTime,
                      description: description.text.trim(),
                      reminders: _selectedReminders,
                      attachmentPaths: _attachmentPaths,
                    );
                  }

                  NotificationHelper.scheduleTaskNotifications(userCreatedTask);

                  Navigator.pop(context, userCreatedTask);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  // Dynamically changes button text!
                  widget.taskToEdit != null ? 'Update Task' : 'Save Task',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment(String titleStr) {
    bool isSelected = _selectedType == titleStr;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = titleStr;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            titleStr,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  // Moved inside the State class so it can be used properly
  Widget _buildAttachmentItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
