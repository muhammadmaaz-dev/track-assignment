import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        title: Text('Task Options'),
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
            child: Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            child: Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
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
        padding: EdgeInsets.only(bottom: 58.h),
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
          child: Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? SizedBox.shrink()
            : (todaysFocusTasks.isEmpty &&
                  upcomingTasks.isEmpty) // <--- Updated line
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 64.sp,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No task...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.4.w,
                  vertical: 13.6.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Focus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${todaysFocusTasks.length} TASKS',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
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
                    SizedBox(height: 32.h),
                    // Upcoming Header
                    Text(
                      'Upcoming',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
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
                    SizedBox(height: 80.h), // Fab space
                  ],
                ),
              ),
      ),
    );
  }
}
