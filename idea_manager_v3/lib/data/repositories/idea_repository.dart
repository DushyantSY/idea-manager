// lib/data/repositories/idea_repository.dart
// Repository layer — decouples UI/providers from raw database calls.
// All business logic exceptions are caught here.

import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/idea_model.dart';
import '../models/task_model.dart';

const _uuid = Uuid();

// ─── Idea Repository ─────────────────────────────────────────────────────────

class IdeaRepository {
  final DatabaseHelper _db;
  IdeaRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  /// Creates a new idea and persists it.
  Future<IdeaModel> createIdea({
    required String title,
    String? description,
    String? notes,
    IdeaStatus status = IdeaStatus.newIdea,
    Priority priority = Priority.medium,
    int rating = 3,
    List<String> tags = const [],
    String? category,
    List<String> pros = const [],
    List<String> cons = const [],
  }) async {
    final now  = DateTime.now();
    final idea = IdeaModel(
      id:          _uuid.v4(),
      title:       title.trim(),
      description: description?.trim(),
      notes:       notes?.trim(),
      status:      status,
      priority:    priority,
      rating:      rating,
      tags:        tags,
      category:    category?.trim(),
      pros:        pros,
      cons:        cons,
      createdAt:   now,
      updatedAt:   now,
    );
    await _db.insertIdea(idea);
    return idea;
  }

  Future<IdeaModel> updateIdea(IdeaModel idea) async {
    final updated = IdeaModel(
      id:          idea.id,
      title:       idea.title.trim(),
      description: idea.description?.trim(),
      notes:       idea.notes?.trim(),
      status:      idea.status,
      priority:    idea.priority,
      rating:      idea.rating,
      tags:        idea.tags,
      category:    idea.category?.trim(),
      pros:        idea.pros,
      cons:        idea.cons,
      createdAt:   idea.createdAt,
      updatedAt:   DateTime.now(),
    );
    await _db.updateIdea(updated);
    return updated;
  }

  Future<void> deleteIdea(String id) => _db.deleteIdea(id);

  Future<IdeaModel?> getById(String id) => _db.getIdeaById(id);

  Future<List<IdeaModel>> getAll({
    String? search,
    String? statusFilter,
    String sortBy = 'created_at',
    bool descending = true,
  }) =>
      _db.getAllIdeas(
        searchQuery:  search,
        statusFilter: statusFilter,
        sortBy:       sortBy,
        descending:   descending,
      );
}

// ─── Task Repository ─────────────────────────────────────────────────────────

class TaskRepository {
  final DatabaseHelper _db;
  TaskRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  /// Creates and persists a new task linked to an idea.
  Future<TaskModel> createTask({
    required String ideaId,
    required String ideaTitle,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
  }) async {
    final now  = DateTime.now();
    final task = TaskModel(
      id:          _uuid.v4(),
      ideaId:      ideaId,
      ideaTitle:   ideaTitle,
      title:       title.trim(),
      description: description?.trim(),
      status:      status,
      dueDate:     dueDate,
      createdAt:   now,
      updatedAt:   now,
    );
    await _db.insertTask(task);
    return task;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final updated = task.copyWith();      // updatedAt refreshed in copyWith
    await _db.updateTask(updated);
    return updated;
  }

  /// Shortcut to toggle status cycle: todo → in_progress → done → todo
  Future<TaskModel> cycleStatus(TaskModel task) async {
    final next = switch (task.status) {
      TaskStatus.todo       => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.done,
      TaskStatus.done       => TaskStatus.todo,
    };
    return updateTask(task.copyWith(status: next));
  }

  Future<void> deleteTask(String id) => _db.deleteTask(id);

  Future<List<TaskModel>> getForIdea(String ideaId) =>
      _db.getTasksForIdea(ideaId);

  Future<List<TaskModel>> getAll({String? statusFilter}) =>
      _db.getAllTasks(statusFilter: statusFilter);
}
