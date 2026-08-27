import 'package:assignment_tracker/models/task_model.dart';
import 'package:assignment_tracker/services/db_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeDatabaseHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

final homeTasksControllerProvider =
    NotifierProvider<HomeTasksController, HomeTasksState>(
      HomeTasksController.new,
    );

class HomeTasksState {
  final List<Task> allTasks;
  final List<Task> todaysFocusTasks;
  final List<Task> upcomingTasks;
  final bool isLoading;

  const HomeTasksState({
    this.allTasks = const [],
    this.todaysFocusTasks = const [],
    this.upcomingTasks = const [],
    this.isLoading = true,
  });

  HomeTasksState copyWith({
    List<Task>? allTasks,
    List<Task>? todaysFocusTasks,
    List<Task>? upcomingTasks,
    bool? isLoading,
  }) {
    return HomeTasksState(
      allTasks: allTasks ?? this.allTasks,
      todaysFocusTasks: todaysFocusTasks ?? this.todaysFocusTasks,
      upcomingTasks: upcomingTasks ?? this.upcomingTasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HomeTasksController extends Notifier<HomeTasksState> {
  DatabaseHelper get _databaseHelper => ref.read(homeDatabaseHelperProvider);

  @override
  HomeTasksState build() => const HomeTasksState();

  Future<void> loadTasks() async {
    final tasks = await _databaseHelper.getAllTasks();
    _setTasks(tasks, isLoading: false);
  }

  Future<void> addTask(Task task) async {
    await _databaseHelper.insertTask(task);
    final updated = [...state.allTasks, task];
    _setTasks(updated, isLoading: false);
  }

  Future<void> updateTask(Task task) async {
    await _databaseHelper.updateTask(task);
    final updated = List<Task>.from(state.allTasks);
    final index = updated.indexWhere((t) => t.id == task.id);

    if (index == -1) {
      updated.add(task);
    } else {
      updated[index] = task;
    }

    _setTasks(updated, isLoading: false);
  }

  Future<void> deleteTask(Task task) async {
    await _databaseHelper.deleteTask(task.id);
    final updated = state.allTasks.where((t) => t.id != task.id).toList();
    _setTasks(updated, isLoading: false);
  }

  Future<void> markTaskCompleted(String taskId) async {
    final index = state.allTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final updatedTask = state.allTasks[index].copyWith(isCompleted: true);
    await _databaseHelper.updateTask(updatedTask);

    final updated = List<Task>.from(state.allTasks);
    updated[index] = updatedTask;
    _setTasks(updated, isLoading: false);
  }

  void refreshTaskBucketsForCurrentTime() {
    final organized = _organizeTasks(state.allTasks, DateTime.now());

    final sameToday = _sameTaskIds(
      state.todaysFocusTasks,
      organized.todaysFocusTasks,
    );
    final sameUpcoming = _sameTaskIds(
      state.upcomingTasks,
      organized.upcomingTasks,
    );

    if (sameToday && sameUpcoming) {
      return;
    }

    state = state.copyWith(
      todaysFocusTasks: organized.todaysFocusTasks,
      upcomingTasks: organized.upcomingTasks,
    );
  }

  void _setTasks(List<Task> tasks, {required bool isLoading}) {
    final organized = _organizeTasks(tasks, DateTime.now());
    state = state.copyWith(
      allTasks: tasks,
      todaysFocusTasks: organized.todaysFocusTasks,
      upcomingTasks: organized.upcomingTasks,
      isLoading: isLoading,
    );
  }

  _OrganizedHomeTasks _organizeTasks(List<Task> tasks, DateTime now) {
    final todaysFocusTasks = <Task>[];
    final upcomingTasks = <Task>[];

    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    for (final task in tasks) {
      if (task.isCompleted) continue;

      // Bucket by calendar day, not by exact time, so a task due earlier
      // today still stays in "Today's Focus" instead of silently vanishing
      // the moment its due time passes. Tasks whose day is already past are
      // overdue and surface on the History screen instead of the home feed.
      if (task.dueDate.isBefore(startOfToday)) {
        continue;
      } else if (task.dueDate.isBefore(startOfTomorrow)) {
        todaysFocusTasks.add(task);
      } else {
        upcomingTasks.add(task);
      }
    }

    todaysFocusTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return _OrganizedHomeTasks(
      todaysFocusTasks: List<Task>.unmodifiable(todaysFocusTasks),
      upcomingTasks: List<Task>.unmodifiable(upcomingTasks),
    );
  }

  bool _sameTaskIds(List<Task> first, List<Task> second) {
    if (first.length != second.length) return false;

    for (var i = 0; i < first.length; i++) {
      if (first[i].id != second[i].id) {
        return false;
      }
    }

    return true;
  }
}

class _OrganizedHomeTasks {
  const _OrganizedHomeTasks({
    required this.todaysFocusTasks,
    required this.upcomingTasks,
  });

  final List<Task> todaysFocusTasks;
  final List<Task> upcomingTasks;
}
