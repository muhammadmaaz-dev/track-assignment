import 'package:assignment_tracker/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:assignment_tracker/theme/constants.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class NewTaskSheet extends StatefulWidget {
  const NewTaskSheet({super.key});

  @override
  State<NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<NewTaskSheet> {
  String _selectedType = 'Assignment';
  final title = TextEditingController();
  final description = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();

  // NAYA LOGIC: Single string ki jagah humne ek List bana di hai
  List<String> _selectedReminders = [];

  final List<String> _reminderOptions = [
    '5 minutes before',
    '10 minutes before',
    '20 minutes before',
    '40 minutes before',
    '1 hour before',
    '2 hours before',
    '4 hours before',
    '1 day before',
    'Custom...',
  ];

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
      initialDateTime: _selectedDateTime,
      minimumDateTime: DateTime(2000),
      maximumDateTime: DateTime(2100),
      mode: CupertinoCalendarMode.dateTime,
    );

    if (picked != null) {
      if (picked.isBefore(stableCurrentTime)) {
        setState(() {
          _selectedDateTime = stableCurrentTime;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot select a past time. Adjusted to current time.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        setState(() {
          _selectedDateTime = picked;
        });
      }
    }
  }

  void _showCustomReminderDialog() {
    final TextEditingController customValueController = TextEditingController();
    String selectedUnit = 'minutes';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Custom Reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customValueController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'e.g. 15',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: selectedUnit,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    items: ['minutes', 'hours', 'days'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedUnit = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    int? val = int.tryParse(customValueController.text.trim());
                    if (val == null || val <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid number'),
                        ),
                      );
                      return;
                    }

                    Duration requiredDuration;
                    if (selectedUnit == 'minutes') {
                      requiredDuration = Duration(minutes: val);
                    } else if (selectedUnit == 'hours') {
                      requiredDuration = Duration(hours: val);
                    } else {
                      requiredDuration = Duration(days: val);
                    }

                    Duration timeUntilDue = _selectedDateTime.difference(
                      DateTime.now(),
                    );

                    if (timeUntilDue <= requiredDuration) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task is due in less than $val $selectedUnit.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    } else {
                      String displayUnit = val == 1
                          ? selectedUnit.substring(0, selectedUnit.length - 1)
                          : selectedUnit;

                      String newReminder = '$val $displayUnit before';

                      // List me add karein (Agar pehle se nahi hai)
                      setState(() {
                        if (!_selectedReminders.contains(newReminder)) {
                          _selectedReminders.add(newReminder);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

                        if (chosenOption == 'Custom...') {
                          Navigator.pop(context);
                          _showCustomReminderDialog();
                          return;
                        }

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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cannot set this reminder. Task is due in less than ${chosenOption.replaceAll(' before', '')}.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } else {
                          // List me add karein (Agar pehle se nahi hai)
                          setState(() {
                            if (!_selectedReminders.contains(chosenOption)) {
                              _selectedReminders.add(chosenOption);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reminder already added!'),
                                  backgroundColor: Colors.orange,
                                ),
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

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
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
                                'Attach File',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF, JPG, or DOCX (Max 20MB)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.add, color: Colors.white.withOpacity(0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

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

                  // DYNAMIC LIST RENDERER FOR MULTIPLE REMINDERS
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a task title'),
                      ),
                    );
                    return;
                  }

                  Task userCreatedTask = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title.text.trim(),
                    type: _selectedType.toUpperCase(),
                    dueDate: _selectedDateTime,
                    description: description.text.trim(),
                    // Reminders list save karni ho toh aapko apne Task model mein add karna padega pehle
                  );

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
                child: const Text(
                  'Save Task',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
}
