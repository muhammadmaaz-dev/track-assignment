import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // A simple ValueNotifier to trigger a reload across all subscribed screens.
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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
        attachmentPaths TEXT
      )
    ''');
    // NAYA CODE: 'reminders TEXT' add kar diya gaya hai
  }

  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    _notifyListeners();
    return result;
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    final result = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    _notifyListeners();
    return result;
  }
}
