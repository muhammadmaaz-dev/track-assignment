import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:assignment_tracker/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final marks = TextEditingController();

  // Configured maximum marks per type, sourced from the Set Marks screen.
  final Map<String, int> _configuredMarks = {
    'Assignment': 0,
    'Quiz': 0,
    'Project': 0,
  };
  // Once the user types their own value we stop auto-filling from the
  // configured defaults on type switches.
  bool _marksManuallyEdited = false;

  DateTime _selectedDateTime = DateTime.now();

  List<String> _selectedReminders = [];

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

    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;
      title.text = t.title;
      description.text = t.description ?? '';

      if (t.type.toUpperCase() == 'ASSIGNMENT') {
        _selectedType = 'Assignment';
      } else if (t.type.toUpperCase() == 'QUIZ') {
        _selectedType = 'Quiz';
      } else if (t.type.toUpperCase() == 'PROJECT') {
        _selectedType = 'Project';
      } else {
        _selectedType = t.type;
      }

      _selectedDateTime = t.dueDate;

      _selectedReminders = List.from(t.reminders);
      if (t.attachmentPaths != null) {
        _attachmentPaths = List.from(t.attachmentPaths!);
      }
      if (t.marks != null) {
        marks.text = _formatMarks(t.marks!);
        _marksManuallyEdited = true;
      }
    }

    _loadConfiguredMarks();
  }

  /// Reads the per-type maximum marks configured on the Set Marks screen and,
  /// for a fresh task, pre-fills the field with the default for the current
  /// type so weightage stays linked to the user's global configuration.
  Future<void> _loadConfiguredMarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _configuredMarks['Assignment'] = prefs.getInt('marks_ASSIGNMENT') ?? 0;
      _configuredMarks['Quiz'] = prefs.getInt('marks_QUIZ') ?? 0;
      _configuredMarks['Project'] = prefs.getInt('marks_PROJECT') ?? 0;

      if (!_marksManuallyEdited && marks.text.trim().isEmpty) {
        final def = _configuredMarks[_selectedType] ?? 0;
        if (def > 0) marks.text = def.toString();
      }
    });
  }

  // Renders 90.0 as "90" but preserves genuine decimals like "87.5".
  String _formatMarks(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    marks.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final destinationDir = Directory('${appDir.path}/task_attachments');
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      List<String> stablePaths = [];

      for (var file in result.files) {
        if (file.path != null) {
          final File tempFile = File(file.path!);
          final String uniqueFileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final String stablePath = p.join(destinationDir.path, uniqueFileName);

          try {
            final File newFile = await tempFile.copy(stablePath);
            stablePaths.add(newFile.path);
          } catch (e) {
            debugPrint('Error copying file: $e');
          }
        }
      }

      setState(() {
        for (var path in stablePaths) {
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
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 250.0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Reminder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        String chosenOption =
                            _reminderOptions[tempSelectedIndex];

                        Duration requiredDuration = Duration.zero;
                        if (chosenOption.contains('min')) {
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
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
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
                  itemExtent: 34,
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
                        style: TextStyle(color: Colors.white, fontSize: 18.sp),
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
    return Material(
      color: Colors.transparent,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 40),
                child: child,
              ),
            );
          },
          child: Container(
            // Keep height somewhat shorter to visually show it's a sheet,
            // the cupertino modal sheet already leaves a gap naturally.
            constraints: const BoxConstraints(maxWidth: 600),
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24.0,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'New Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: title,
                        autofocus: widget.taskToEdit == null,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter task title',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      Container(
                        height: 42.h,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(21.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.0.w),
                          child: Row(
                            children: [
                              _buildTypeSegment('Assignment'),
                              _buildTypeSegment('Quiz'),
                              _buildTypeSegment('Project'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

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
                      SizedBox(height: 24.h),

                      _buildMarksCard(),
                      SizedBox(height: 24.h),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notes,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'NOTES / QUESTIONS',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            TextField(
                              controller: description,
                              maxLines: 4,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add questions or notes',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 16.sp,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      GestureDetector(
                        onTap:
                            _pickFiles, // Now the ENTIRE container opens the file picker
                        behavior: HitTestBehavior
                            .opaque, // Ensures tapping on empty space works
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Icon(
                                  Icons.attach_file,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attachments',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),

                                    // Dynamic Attachments List with Cross Buttons
                                    if (_attachmentPaths.isEmpty)
                                      Text(
                                        'Tap anywhere to add files', // Updated UX text
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      )
                                    else
                                      ..._attachmentPaths.map((filePath) {
                                        String fileName = filePath
                                            .split('/')
                                            .last;
                                        String extension = fileName
                                            .split('.')
                                            .last
                                            .toLowerCase();

                                        IconData icon =
                                            Icons.insert_drive_file_outlined;
                                        if (extension == 'pdf') {
                                          icon = Icons.picture_as_pdf_outlined;
                                        }
                                        if ([
                                          'jpg',
                                          'jpeg',
                                          'png',
                                        ].contains(extension)) {
                                          icon = Icons.image_outlined;
                                        }

                                        return Container(
                                          margin: EdgeInsets.only(bottom: 8.0),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 
                                              0.2,
                                            ), // Dark inset background
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 
                                                0.05,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                icon,
                                                color: Colors.white,
                                                size: 18.sp,
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Text(
                                                  fileName,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.sp,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
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
                                                  padding: EdgeInsets.all(4.0),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    size: 20.sp,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                      SizedBox(height: 24.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reminders Schedule',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showReminderPicker,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      _selectedReminders.isEmpty
                          ? Center(
                              child: Text(
                                'Empty',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  fontSize: 16.sp,
                                ),
                              ),
                            )
                          : Column(
                              children: _selectedReminders.map((reminder) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(24.r),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_active,
                                          color: Colors.white.withValues(alpha: 0.8),
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Text(
                                            reminder,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedReminders.remove(
                                                reminder,
                                              );
                                            });
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white.withValues(alpha: 
                                              0.5,
                                            ),
                                            size: 20.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                      SizedBox(height: 100.h),
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
                  height: 51.h,
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

                      final double? parsedMarks = marks.text.trim().isEmpty
                          ? null
                          : double.tryParse(marks.text.trim());

                      // If editing, use copyWith to preserve the ID and other original states
                      if (widget.taskToEdit != null) {
                        userCreatedTask = widget.taskToEdit!.copyWith(
                          title: title.text.trim(),
                          type: _selectedType.toUpperCase(),
                          dueDate: _selectedDateTime,
                          description: description.text.trim(),
                          reminders: _selectedReminders,
                          attachmentPaths: _attachmentPaths,
                          marks: parsedMarks,
                        );
                      } else {
                        userCreatedTask = Task(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title.text.trim(),
                          type: _selectedType.toUpperCase(),
                          dueDate: _selectedDateTime,
                          description: description.text.trim(),
                          reminders: _selectedReminders,
                          attachmentPaths: _attachmentPaths,
                          marks: parsedMarks,
                        );
                      }

                      // Notification scheduling is handled centrally by the
                      // data layer (DatabaseHelper) when the task is persisted,
                      // so every create/edit path stays consistent.
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, userCreatedTask);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.taskToEdit != null ? 'Update Task' : 'Save Task',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment(String titleStr) {
    bool isSelected = _selectedType == titleStr;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedType = titleStr;
            // Keep the weightage aligned with the newly selected type's
            // configured default unless the user has customised it.
            if (!_marksManuallyEdited) {
              final def = _configuredMarks[_selectedType] ?? 0;
              marks.text = def > 0 ? def.toString() : '';
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
          ),
          alignment: Alignment.center,
          child: Text(
            titleStr,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarksCard() {
    final int configuredMax = _configuredMarks[_selectedType] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.grade_outlined, color: Colors.white, size: 17.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marks / Weightage',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: marks,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => _marksManuallyEdited = true,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: configuredMax > 0
                        ? 'Out of $configuredMax (optional)'
                        : 'Optional',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(25.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: Colors.white, size: 17.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
