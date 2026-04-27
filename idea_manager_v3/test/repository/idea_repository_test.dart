// test/repository/idea_repository_test.dart
// Integration tests for IdeaRepository + TaskRepository using sqflite_common_ffi
// (in-memory SQLite — no Android device needed).

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:idea_manager/data/database/database_helper.dart';
import 'package:idea_manager/data/models/idea_model.dart';
import 'package:idea_manager/data/models/task_model.dart';
import 'package:idea_manager/data/repositories/idea_repository.dart';

// ─── Helper: open an isolated in-memory DB for each test ─────────────────────

Future<DatabaseHelper> _makeDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // Bypass the singleton by opening a named in-memory DB
  final db = DatabaseHelper();
  await db.database; // triggers _onCreate
  return db;
}

void main() {
  // Use FFI (desktop/CI compatible) SQLite
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── IdeaRepository ─────────────────────────────────────────────────────────

  group('IdeaRepository', () {
    late IdeaRepository repo;

    setUp(() async {
      repo = IdeaRepository(db: await _makeDb());
    });

    test('createIdea() persists and returns idea with id', () async {
      final idea = await repo.createIdea(
        title:    'Test Idea',
        priority: Priority.high,
      );

      expect(idea.id,       isNotEmpty);
      expect(idea.title,    equals('Test Idea'));
      expect(idea.priority, equals(Priority.high));
      expect(idea.status,   equals(IdeaStatus.newIdea));
    });

    test('getAll() returns all created ideas', () async {
      await repo.createIdea(title: 'Alpha');
      await repo.createIdea(title: 'Beta');
      await repo.createIdea(title: 'Gamma');

      final all = await repo.getAll();
      expect(all.length, equals(3));
    });

    test('getAll() with search filters by title', () async {
      await repo.createIdea(title: 'Flutter app idea');
      await repo.createIdea(title: 'Python script');

      final results = await repo.getAll(search: 'flutter');
      expect(results.length, equals(1));
      expect(results.first.title, contains('Flutter'));
    });

    test('getAll() with statusFilter returns only matching ideas', () async {
      await repo.createIdea(title: 'A', status: IdeaStatus.planned);
      await repo.createIdea(title: 'B', status: IdeaStatus.thinking);
      await repo.createIdea(title: 'C', status: IdeaStatus.planned);

      final planned = await repo.getAll(statusFilter: 'planned');
      expect(planned.length, equals(2));
      expect(planned.every((i) => i.status == IdeaStatus.planned), isTrue);
    });

    test('updateIdea() persists changes', () async {
      final idea    = await repo.createIdea(title: 'Original');
      final updated = await repo.updateIdea(
        idea.copyWith(title: 'Updated', priority: Priority.high),
      );

      final fetched = await repo.getById(idea.id);
      expect(fetched?.title,    equals('Updated'));
      expect(fetched?.priority, equals(Priority.high));
    });

    test('deleteIdea() removes the idea', () async {
      final idea = await repo.createIdea(title: 'To delete');
      await repo.deleteIdea(idea.id);

      final fetched = await repo.getById(idea.id);
      expect(fetched, isNull);
    });

    test('getAll() sortBy rating descending orders correctly', () async {
      await repo.createIdea(title: 'Low',  rating: 1);
      await repo.createIdea(title: 'High', rating: 5);
      await repo.createIdea(title: 'Mid',  rating: 3);

      final sorted = await repo.getAll(sortBy: 'rating', descending: true);
      expect(sorted.map((i) => i.rating).toList(), equals([5, 3, 1]));
    });
  });

  // ── TaskRepository ─────────────────────────────────────────────────────────

  group('TaskRepository', () {
    late IdeaRepository ideaRepo;
    late TaskRepository taskRepo;

    setUp(() async {
      final db = await _makeDb();
      ideaRepo = IdeaRepository(db: db);
      taskRepo = TaskRepository(db: db);
    });

    test('createTask() links to idea', () async {
      final idea = await ideaRepo.createIdea(title: 'Parent Idea');
      final task = await taskRepo.createTask(
        ideaId:    idea.id,
        ideaTitle: idea.title,
        title:     'Sub-task',
      );

      expect(task.ideaId, equals(idea.id));
      expect(task.status, equals(TaskStatus.todo));
    });

    test('getForIdea() returns only tasks for that idea', () async {
      final a = await ideaRepo.createIdea(title: 'Idea A');
      final b = await ideaRepo.createIdea(title: 'Idea B');

      await taskRepo.createTask(ideaId: a.id, ideaTitle: a.title, title: 'A1');
      await taskRepo.createTask(ideaId: a.id, ideaTitle: a.title, title: 'A2');
      await taskRepo.createTask(ideaId: b.id, ideaTitle: b.title, title: 'B1');

      final aTasks = await taskRepo.getForIdea(a.id);
      expect(aTasks.length, equals(2));
      expect(aTasks.every((t) => t.ideaId == a.id), isTrue);
    });

    test('cycleStatus() advances through the lifecycle', () async {
      final idea = await ideaRepo.createIdea(title: 'Lifecycle Idea');
      var task = await taskRepo.createTask(
        ideaId:    idea.id,
        ideaTitle: idea.title,
        title:     'Cycle me',
      );

      expect(task.status, equals(TaskStatus.todo));

      task = await taskRepo.cycleStatus(task);
      expect(task.status, equals(TaskStatus.inProgress));

      task = await taskRepo.cycleStatus(task);
      expect(task.status, equals(TaskStatus.done));

      task = await taskRepo.cycleStatus(task);
      expect(task.status, equals(TaskStatus.todo)); // wraps around
    });

    test('deleteTask() removes only the specified task', () async {
      final idea = await ideaRepo.createIdea(title: 'Idea');
      final t1   = await taskRepo.createTask(
          ideaId: idea.id, ideaTitle: idea.title, title: 'Keep');
      final t2   = await taskRepo.createTask(
          ideaId: idea.id, ideaTitle: idea.title, title: 'Delete');

      await taskRepo.deleteTask(t2.id);

      final remaining = await taskRepo.getForIdea(idea.id);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals(t1.id));
    });

    test('getAll() with statusFilter returns matching tasks only', () async {
      final idea = await ideaRepo.createIdea(title: 'Idea');
      final t1 = await taskRepo.createTask(
          ideaId: idea.id, ideaTitle: idea.title, title: 'Todo task');
      await taskRepo.cycleStatus(t1); // → in_progress

      final t2 = await taskRepo.createTask(
          ideaId: idea.id, ideaTitle: idea.title, title: 'Done task');
      final t2ip = await taskRepo.cycleStatus(t2); // → in_progress
      await taskRepo.cycleStatus(t2ip);             // → done

      final todoTasks = await taskRepo.getAll(statusFilter: 'todo');
      expect(todoTasks.length, equals(0));

      final doneTasks = await taskRepo.getAll(statusFilter: 'done');
      expect(doneTasks.length, equals(1));
      expect(doneTasks.first.title, equals('Done task'));
    });
  });
}
