import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/home_tasks_provider.dart';
import '../widgets/task_widgets.dart';
import '../services/db_helper.dart';
import 'new_task_sheet.dart';
import 'task_detail_screen.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final DatabaseHelper _databaseHelper;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _databaseHelper = ref.read(homeDatabaseHelperProvider);
    ref.read(homeTasksControllerProvider.notifier).loadTasks();
    _databaseHelper.onDatabaseChanged.addListener(_onDbChanged);

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        ref
            .read(homeTasksControllerProvider.notifier)
            .refreshTaskBucketsForCurrentTime();
      }
    });
  }

  void _onDbChanged() {
    if (mounted) {
      ref.read(homeTasksControllerProvider.notifier).loadTasks();
    }
  }

  @override
  void dispose() {
    _databaseHelper.onDatabaseChanged.removeListener(_onDbChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _deleteTask(Task task) async {
    await ref.read(homeTasksControllerProvider.notifier).deleteTask(task);
  }

  void _showTaskActionSheet(BuildContext context, Task task) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Task Options'),
        message: Text(task.title),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            // 1. Make this onPressed async
            onPressed: () async {
              Navigator.pop(context); // Close the Cupertino action sheet first

              // 2. Open the NewTaskSheet and pass the selected task to edit
              final Task? updatedTask = await showCupertinoModalSheet<Task>(
                context: context,
                builder: (context) => NewTaskSheet(taskToEdit: task),
              );

              // 3. If the user saved changes, update the DB and UI
              if (updatedTask != null) {
                await ref
                    .read(homeTasksControllerProvider.notifier)
                    .updateTask(updatedTask);
              }
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
    final isLoading = ref.watch(
      homeTasksControllerProvider.select((state) => state.isLoading),
    );
    final todaysFocusTasks = ref.watch(
      homeTasksControllerProvider.select((state) => state.todaysFocusTasks),
    );
    final upcomingTasks = ref.watch(
      homeTasksControllerProvider.select((state) => state.upcomingTasks),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          // 1. Is function ko 'async' banayein
          onPressed: () async {
            // 2. Naya task aane ka wait karein
            final Task? newTask = await showCupertinoModalSheet<Task>(
              context: context,
              builder: (context) => const NewTaskSheet(),
            );

            // 3. Agar user ne task add kiya hai (cancel nahi kiya) to list me daal dein
            if (newTask != null) {
              await ref
                  .read(homeTasksControllerProvider.notifier)
                  .addTask(newTask);
            }
          },
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const SizedBox.shrink()
            : (todaysFocusTasks.isEmpty &&
                  upcomingTasks.isEmpty) // <--- Updated line
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
                        final bool isTopTask = index == 0;
                        final Task originalTask = todaysFocusTasks[index];

                        final Task displayTask = Task(
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
                              await ref
                                  .read(homeTasksControllerProvider.notifier)
                                  .markTaskCompleted(originalTask.id);
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
                        final Task originalTask = upcomingTasks[index];

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskDetailScreen(task: originalTask),
                              ),
                            );

                            if (result == true) {
                              await ref
                                  .read(homeTasksControllerProvider.notifier)
                                  .markTaskCompleted(originalTask.id);
                            }
                          },
                          onLongPress: () {
                            _showTaskActionSheet(context, originalTask);
                          },
                          child: UpcomingTaskTile(task: originalTask),
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
