import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import 'notification_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  final ValueNotifier<bool> onDatabaseChanged = ValueNotifier(false);

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  void _notifyListeners() {
    onDatabaseChanged.value = !onDatabaseChanged.value;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        timeString TEXT,
        isHighPriority INTEGER NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL,
        reminders TEXT,
        attachmentPaths TEXT,
        marks REAL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v2 introduced per-task marks/weightage. Add the column without dropping
    // existing rows so previously saved tasks are preserved.
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN marks REAL');
    }
  }

  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await NotificationHelper.scheduleTaskNotifications(task);
    _notifyListeners();
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    final result = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    // Reschedule so edits (new due date / reminders / completion) never leave
    // stale alarms armed.
    await NotificationHelper.scheduleTaskNotifications(task);
    _notifyListeners();
    return result;
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    final result = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await NotificationHelper.cancelTaskNotificationsById(id);
    _notifyListeners();
    return result;
  }

  /// Deletes a specific set of tasks by id (batched in one transaction) and
  /// cancels their pending notifications. Used by "Clear History".
  Future<void> deleteTasks(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete('tasks', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    for (final id in ids) {
      await NotificationHelper.cancelTaskNotificationsById(id);
    }
    _notifyListeners();
  }

  /// Re-inserts previously deleted tasks (used to support "Undo").
  Future<void> restoreTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    final db = await instance.database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    for (final task in tasks) {
      await NotificationHelper.scheduleTaskNotifications(task);
    }
    _notifyListeners();
  }

  Future<void> deleteAllTasks() async {
    final db = await instance.database;
    await db.delete('tasks');
    await AwesomeNotifications().cancelAll();
    await AwesomeNotifications().cancelAllSchedules();
    _notifyListeners();
  }
}
