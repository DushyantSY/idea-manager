// lib/data/database/database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../core/constants/app_constants.dart';
import '../models/idea_model.dart';
import '../models/task_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.dbName);
      debugPrint('DB path: $path');

      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        // NOTE: Do NOT use db.execute() for PRAGMA in onOpen —
        // sqflite requires rawQuery for PRAGMA statements.
        onOpen: (db) async {
          await db.rawQuery('PRAGMA journal_mode=WAL');
          debugPrint('DB opened successfully');
        },
      );
    } catch (e, stack) {
      debugPrint('❌ _initDb failed: $e\n$stack');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.ideasTable} (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        description TEXT,
        notes       TEXT,
        status      TEXT NOT NULL DEFAULT 'new',
        priority    TEXT NOT NULL DEFAULT 'medium',
        rating      INTEGER NOT NULL DEFAULT 3,
        tags        TEXT NOT NULL DEFAULT '[]',
        category    TEXT,
        pros        TEXT NOT NULL DEFAULT '[]',
        cons        TEXT NOT NULL DEFAULT '[]',
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tasksTable} (
        id          TEXT PRIMARY KEY,
        idea_id     TEXT NOT NULL,
        idea_title  TEXT NOT NULL DEFAULT '',
        title       TEXT NOT NULL,
        description TEXT,
        status      TEXT NOT NULL DEFAULT 'todo',
        due_date    TEXT,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        FOREIGN KEY (idea_id) REFERENCES ${AppConstants.ideasTable}(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ideas_status ON ${AppConstants.ideasTable}(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_idea_id ON ${AppConstants.tasksTable}(idea_id)',
    );
    debugPrint('✅ Tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  // ── Ideas CRUD ─────────────────────────────────────────────────────────────

  Future<String> insertIdea(IdeaModel idea) async {
    final db = await database;
    await db.insert(
      AppConstants.ideasTable,
      idea.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return idea.id;
  }

  Future<int> updateIdea(IdeaModel idea) async {
    final db = await database;
    return db.update(
      AppConstants.ideasTable,
      idea.toMap(),
      where: 'id = ?',
      whereArgs: [idea.id],
    );
  }

  Future<int> deleteIdea(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.tasksTable,
      where: 'idea_id = ?',
      whereArgs: [id],
    );
    return db.delete(
      AppConstants.ideasTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<IdeaModel?> getIdeaById(String id) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.ideasTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : IdeaModel.fromMap(rows.first);
  }

  Future<List<IdeaModel>> getAllIdeas({
    String? searchQuery,
    String? statusFilter,
    String sortBy = 'created_at',
    bool descending = true,
  }) async {
    final db = await database;
    String? where;
    final List<dynamic> args = [];

    if (statusFilter != null && statusFilter != 'all') {
      where = 'status = ?';
      args.add(statusFilter);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      final sc = '(title LIKE ? OR description LIKE ? OR tags LIKE ?)';
      where = where == null ? sc : '$where AND $sc';
      args.addAll([q, q, q]);
    }

    final col = {
          'priority':
              "CASE priority WHEN 'high' THEN 3 WHEN 'medium' THEN 2 ELSE 1 END",
          'rating': 'rating',
        }[sortBy] ??
        'created_at';

    final order = descending ? 'DESC' : 'ASC';
    final rows = await db.query(
      AppConstants.ideasTable,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: '$col $order',
    );
    return rows.map(IdeaModel.fromMap).toList();
  }

  // ── Tasks CRUD ─────────────────────────────────────────────────────────────

  Future<String> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert(
      AppConstants.tasksTable,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return task.id;
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return db.update(
      AppConstants.tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return db.delete(
      AppConstants.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TaskModel>> getTasksForIdea(String ideaId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tasksTable,
      where: 'idea_id = ?',
      whereArgs: [ideaId],
      orderBy: 'created_at ASC',
    );
    return rows.map(TaskModel.fromMap).toList();
  }

  Future<List<TaskModel>> getAllTasks({String? statusFilter}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (statusFilter != null && statusFilter != 'all') {
      where = 'status = ?';
      args = [statusFilter];
    }
    final rows = await db.query(
      AppConstants.tasksTable,
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(TaskModel.fromMap).toList();
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.tasksTable);
    await db.delete(AppConstants.ideasTable);
  }

  Future<Map<String, dynamic>> exportAll() async {
    final ideas = await getAllIdeas();
    final tasks = await getAllTasks();
    return {'ideas': ideas, 'tasks': tasks};
  }
}
