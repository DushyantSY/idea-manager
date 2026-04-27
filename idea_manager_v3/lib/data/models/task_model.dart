// lib/data/models/task_model.dart
// Task data model — each task is linked to an IdeaModel via ideaId.

/// Lifecycle status of a task.
enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get key {
    switch (this) {
      case TaskStatus.inProgress: return 'in_progress';
      case TaskStatus.done:       return 'done';
      default:                    return 'todo';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.done:       return 'Done';
      default:                    return 'To-Do';
    }
  }

  static TaskStatus fromKey(String key) {
    switch (key) {
      case 'in_progress': return TaskStatus.inProgress;
      case 'done':        return TaskStatus.done;
      default:            return TaskStatus.todo;
    }
  }
}

/// Task model — stored in the `tasks` SQLite table.
class TaskModel {
  final String id;
  final String ideaId;      // FK → ideas.id
  final String ideaTitle;   // Denormalised for display (avoids join)
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.ideaId,
    required this.ideaTitle,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id':          id,
        'idea_id':     ideaId,
        'idea_title':  ideaTitle,
        'title':       title,
        'description': description,
        'status':      status.key,
        'due_date':    dueDate?.toIso8601String(),
        'created_at':  createdAt.toIso8601String(),
        'updated_at':  updatedAt.toIso8601String(),
      };

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id:          map['id'] as String,
        ideaId:      map['idea_id'] as String,
        ideaTitle:   (map['idea_title'] as String?) ?? '',
        title:       map['title'] as String,
        description: map['description'] as String?,
        status:      TaskStatusX.fromKey(map['status'] as String? ?? 'todo'),
        dueDate:     map['due_date'] != null
            ? DateTime.parse(map['due_date'] as String)
            : null,
        createdAt:   DateTime.parse(map['created_at'] as String),
        updatedAt:   DateTime.parse(map['updated_at'] as String),
      );

  // ── Immutable updates ──────────────────────────────────────────────────────

  TaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) =>
      TaskModel(
        id:          id,
        ideaId:      ideaId,
        ideaTitle:   ideaTitle,
        title:       title       ?? this.title,
        description: description ?? this.description,
        status:      status      ?? this.status,
        dueDate:     clearDueDate ? null : (dueDate ?? this.dueDate),
        createdAt:   createdAt,
        updatedAt:   DateTime.now(),
      );

  bool get isOverdue =>
      dueDate != null &&
      status != TaskStatus.done &&
      dueDate!.isBefore(DateTime.now());

  @override
  String toString() => 'TaskModel(id: $id, title: $title, status: ${status.key})';
}
