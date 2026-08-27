import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const HomeScreen({super.key});

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

  Future<void> _openNewTaskSheet() async {
    HapticFeedback.lightImpact();
    final Task? newTask = await showCupertinoModalSheet<Task>(
      context: context,
      builder: (context) => const NewTaskSheet(),
    );

    if (newTask != null) {
      await ref.read(homeTasksControllerProvider.notifier).addTask(newTask);
    }
  }

  Future<bool> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Delete Task?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Remove "${task.title}"? You can undo this right after.',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.pop(context, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _deleteTaskWithUndo(Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(homeTasksControllerProvider.notifier).deleteTask(task);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            DatabaseHelper.instance.restoreTasks([task]);
          },
        ),
      ),
    );
  }

  Future<void> _completeTaskFromSwipe(Task task) async {
    HapticFeedback.mediumImpact();
    await ref
        .read(homeTasksControllerProvider.notifier)
        .markTaskCompleted(task.id);
  }

  Widget _swipeBackground({required bool isDelete, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: isDelete ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(20.r),
      ),
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      child: Icon(
        isDelete ? Icons.delete_outline : Icons.check_circle_outline,
        color: Colors.white,
        size: 26.sp,
      ),
    );
  }

  /// confirmDismiss handler. Right-to-left asks to delete (returns the dialog
  /// result; the actual delete + undo runs in onDismissed). Left-to-right
  /// toggles completion instantly and returns false so the widget stays in the
  /// tree — the list rebuild reflects the new state, avoiding the "dismissed
  /// widget still in tree" assertion.
  Future<bool> _onSwipe(DismissDirection direction, Task task) async {
    if (direction == DismissDirection.endToStart) {
      return _confirmDelete(task);
    } else {
      await _completeTaskFromSwipe(task);
      return false;
    }
  }

  void _showTaskActionSheet(BuildContext context, Task task) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Task Options'),
        message: Text(task.title),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final Task? updatedTask = await showCupertinoModalSheet<Task>(
                context: context,
                builder: (context) => NewTaskSheet(taskToEdit: task),
              );
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
              _deleteTaskWithUndo(task);
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
        padding: EdgeInsets.only(bottom: 88.h),
        child: FloatingActionButton(
          onPressed: _openNewTaskSheet,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          child: Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.4.w,
                  vertical: 13.6.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (todaysFocusTasks.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: const EmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'All caught up!',
                          subtitle: 'No tasks left for today.',
                        ),
                      )
                    else
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
                            marks: originalTask.marks,
                          );

                          return Dismissible(
                            key: ValueKey(originalTask.id),
                            background: _swipeBackground(
                              isDelete: false,
                              margin: EdgeInsets.only(bottom: 13.6.h),
                            ),
                            secondaryBackground: _swipeBackground(
                              isDelete: true,
                              margin: EdgeInsets.only(bottom: 13.6.h),
                            ),
                            confirmDismiss: (direction) =>
                                _onSwipe(direction, originalTask),
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                _deleteTaskWithUndo(originalTask);
                              }
                            },
                            child: GestureDetector(
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
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 32.h),
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
                    if (upcomingTasks.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: const EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'Clear horizon.',
                          subtitle: 'No upcoming assignments scheduled.',
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcomingTasks.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey.shade800, height: 1),
                        itemBuilder: (context, index) {
                          final Task originalTask = upcomingTasks[index];

                          return Dismissible(
                            key: ValueKey(originalTask.id),
                            background: _swipeBackground(isDelete: false),
                            secondaryBackground: _swipeBackground(
                              isDelete: true,
                            ),
                            confirmDismiss: (direction) =>
                                _onSwipe(direction, originalTask),
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                _deleteTaskWithUndo(originalTask);
                              }
                            },
                            child: GestureDetector(
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
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
      ),
    );
  }
}
