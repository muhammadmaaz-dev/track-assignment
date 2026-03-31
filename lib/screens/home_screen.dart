import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/task_model.dart';
import '../widgets/task_widgets.dart';
import 'new_task_sheet.dart';
import 'task_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dummy data representing real-time data
  List<Task> allTasks = [];

  List<Task> todaysFocusTasks = [];
  List<Task> upcomingTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('saved_tasks');

    if (tasksString != null) {
      final List<dynamic> decodedTasks = jsonDecode(tasksString);
      setState(() {
        allTasks = decodedTasks.map((task) => Task.fromJson(task)).toList();
      });
    }
    _organizetask(); // Organize after loading
  }

  // 4. NAYA LOGIC: Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedTasks = jsonEncode(
      allTasks.map((t) => t.toJson()).toList(),
    );
    await prefs.setString('saved_tasks', encodedTasks);
  }

  void _organizetask() {
    final now = DateTime.now();

    todaysFocusTasks.clear();
    upcomingTasks.clear();

    for (var task in allTasks) {
      if (task.isCompleted) continue; // Skip completed tasks

      bool isToday =
          task.dueDate.year == now.year &&
          task.dueDate.month == now.month &&
          task.dueDate.day == now.day;

      // A strict overdue check - if the due date is before exactly NOW, it's overdue completely
      if (task.dueDate.isBefore(now)) {
        continue; // Skip it entirely from home screen, it will go to history
      } else if (isToday) {
        // meaning it's today but in the future
        todaysFocusTasks.add(task);
      } else if (task.dueDate.isAfter(now)) {
        upcomingTasks.add(task);
      }
    }

    todaysFocusTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    setState(() {});
  }

  void _deleteTask(Task task) {
    setState(() {
      // Remove the task from the main list using its unique ID
      allTasks.removeWhere((t) => t.id == task.id);
    });

    // Save the updated list to local storage
    _saveTasks();

    // Reorganize the Today and Upcoming lists
    _organizetask();
  }

  void _showTaskActionSheet(BuildContext context, Task task) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Task Options'),
        message: Text(task.title),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement edit functionality
            },
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          // 1. Is function ko 'async' banayein
          onPressed: () async {
            // 2. Naya task aane ka wait karein
            final Task? newTask = await showModalBottomSheet<Task>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              useSafeArea: true,
              builder: (context) => const NewTaskSheet(),
            );

            // 3. Agar user ne task add kiya hai (cancel nahi kiya) to list me daal dein
            if (newTask != null) {
              setState(() {
                allTasks.add(newTask); // Main list me add karein
                _organizetask(); // Dobara sort aur filter karein
              });
              _saveTasks();
            }
          },
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black),
          shape: const CircleBorder(),
        ),
      ),
      body: SafeArea(
        child: allTasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 64,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No task...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Focus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${todaysFocusTasks.length} TASKS',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Today's Focus List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todaysFocusTasks.length,
                      itemBuilder: (context, index) {
                        bool isTopTask = index == 0;
                        Task originalTask = todaysFocusTasks[index];

                        Task displayTask = Task(
                          id: originalTask.id,
                          title: originalTask.title,
                          type: originalTask.type,
                          dueDate: originalTask.dueDate,
                          timeString: originalTask.timeString,
                          isHighPriority: isTopTask,
                          description: originalTask.description,
                        );

                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskDetailScreen(task: originalTask),
                              ),
                            );

                            if (result == true) {
                              // Task was marked as completed
                              setState(() {
                                final index = allTasks.indexWhere(
                                  (t) => t.id == originalTask.id,
                                );
                                if (index != -1) {
                                  allTasks[index] = allTasks[index].copyWith(
                                    isCompleted: true,
                                  );
                                }
                              });
                              _saveTasks();
                              _organizetask();
                            }
                          },
                          onLongPress: () {
                            _showTaskActionSheet(context, originalTask);
                          },
                          child: TodaysFocusCard(task: displayTask),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Upcoming Header
                    const Text(
                      'Upcoming',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Upcoming List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingTasks.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.shade800, height: 1),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetailScreen(
                                  task: upcomingTasks[index],
                                ),
                              ),
                            );

                            if (result == true) {
                              setState(() {
                                final originalId = upcomingTasks[index].id;
                                final allIndex = allTasks.indexWhere(
                                  (t) => t.id == originalId,
                                );
                                if (allIndex != -1) {
                                  allTasks[allIndex] = allTasks[allIndex]
                                      .copyWith(isCompleted: true);
                                }
                              });
                              _saveTasks();
                              _organizetask();
                            }
                          },
                          onLongPress: () {
                            _showTaskActionSheet(context, upcomingTasks[index]);
                          },
                          child: UpcomingTaskTile(task: upcomingTasks[index]),
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Fab space
                  ],
                ),
              ),
      ),
    );
  }
}
