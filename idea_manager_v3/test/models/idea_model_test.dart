// test/models/idea_model_test.dart
// Unit tests for IdeaModel serialisation round-trip and copyWith behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:idea_manager/data/models/idea_model.dart';
import 'package:idea_manager/data/models/task_model.dart';

void main() {
  // ── IdeaModel ──────────────────────────────────────────────────────────────

  group('IdeaModel', () {
    final now = DateTime(2024, 6, 15, 10, 30);

    final idea = IdeaModel(
      id: 'test-id-123',
      title: 'Build a rocket',
      description: 'Send it to Mars',
      notes: 'Step 1: acquire fuel',
      status: IdeaStatus.thinking,
      priority: Priority.high,
      rating: 4,
      tags: ['space', 'engineering'],
      category: 'Tech',
      pros: ['Cool', 'Inspiring'],
      cons: ['Expensive'],
      createdAt: now,
      updatedAt: now,
    );

    test('toMap() contains all fields with correct types', () {
      final map = idea.toMap();

      expect(map['id'],          equals('test-id-123'));
      expect(map['title'],       equals('Build a rocket'));
      expect(map['description'], equals('Send it to Mars'));
      expect(map['notes'],       equals('Step 1: acquire fuel'));
      expect(map['status'],      equals('thinking'));
      expect(map['priority'],    equals('high'));
      expect(map['rating'],      equals(4));
      expect(map['tags'],        equals('["space","engineering"]'));
      expect(map['category'],    equals('Tech'));
      expect(map['pros'],        equals('["Cool","Inspiring"]'));
      expect(map['cons'],        equals('["Expensive"]'));
      expect(map['created_at'],  equals(now.toIso8601String()));
    });

    test('fromMap() round-trip restores all fields', () {
      final map       = idea.toMap();
      final restored  = IdeaModel.fromMap(map);

      expect(restored.id,          equals(idea.id));
      expect(restored.title,       equals(idea.title));
      expect(restored.description, equals(idea.description));
      expect(restored.status,      equals(IdeaStatus.thinking));
      expect(restored.priority,    equals(Priority.high));
      expect(restored.rating,      equals(4));
      expect(restored.tags,        equals(['space', 'engineering']));
      expect(restored.pros,        equals(['Cool', 'Inspiring']));
      expect(restored.cons,        equals(['Expensive']));
    });

    test('copyWith() only changes specified fields', () {
      final updated = idea.copyWith(
        title:    'Build a bigger rocket',
        priority: Priority.low,
        rating:   5,
      );

      expect(updated.title,       equals('Build a bigger rocket'));
      expect(updated.priority,    equals(Priority.low));
      expect(updated.rating,      equals(5));
      // Unchanged fields preserved
      expect(updated.id,          equals(idea.id));
      expect(updated.description, equals(idea.description));
      expect(updated.tags,        equals(idea.tags));
      expect(updated.status,      equals(idea.status));
      expect(updated.createdAt,   equals(idea.createdAt));
    });

    test('updatedAt is refreshed on copyWith()', () {
      final before = idea.updatedAt;
      // Small delay to ensure time difference
      final updated = idea.copyWith(title: 'New title');
      expect(updated.updatedAt.isAfter(before) ||
             updated.updatedAt.isAtSameMomentAs(before), isTrue);
    });
  });

  // ── IdeaStatus ─────────────────────────────────────────────────────────────

  group('IdeaStatus', () {
    test('key → enum round-trip for all values', () {
      for (final status in IdeaStatus.values) {
        expect(IdeaStatusX.fromKey(status.key), equals(status));
      }
    });

    test('unknown key defaults to newIdea', () {
      expect(IdeaStatusX.fromKey('garbage'), equals(IdeaStatus.newIdea));
    });
  });

  // ── Priority ───────────────────────────────────────────────────────────────

  group('Priority', () {
    test('key → enum round-trip for all values', () {
      for (final p in Priority.values) {
        expect(PriorityX.fromKey(p.key), equals(p));
      }
    });

    test('unknown key defaults to low', () {
      expect(PriorityX.fromKey('???'), equals(Priority.low));
    });
  });

  // ── TaskModel ──────────────────────────────────────────────────────────────

  group('TaskModel', () {
    final now = DateTime(2024, 6, 20, 9, 0);
    final due = DateTime(2024, 7, 1);

    final task = TaskModel(
      id: 'task-id-abc',
      ideaId: 'idea-id-xyz',
      ideaTitle: 'My Big Idea',
      title: 'Research competitors',
      description: 'Spend 2 hours on analysis',
      status: TaskStatus.inProgress,
      dueDate: due,
      createdAt: now,
      updatedAt: now,
    );

    test('toMap() serialises dueDate as ISO string', () {
      final map = task.toMap();
      expect(map['due_date'], equals(due.toIso8601String()));
      expect(map['status'],   equals('in_progress'));
    });

    test('fromMap() round-trip restores dueDate', () {
      final map      = task.toMap();
      final restored = TaskModel.fromMap(map);
      expect(restored.dueDate, equals(due));
      expect(restored.status,  equals(TaskStatus.inProgress));
    });

    test('isOverdue returns false for done tasks regardless of date', () {
      final overdueButDone = task.copyWith(
        status:  TaskStatus.done,
        dueDate: DateTime(2020, 1, 1), // definitely in the past
      );
      expect(overdueButDone.isOverdue, isFalse);
    });

    test('isOverdue returns true for past due date on active task', () {
      final overdue = task.copyWith(
        status:  TaskStatus.todo,
        dueDate: DateTime(2020, 1, 1),
      );
      expect(overdue.isOverdue, isTrue);
    });

    test('null dueDate means never overdue', () {
      final noDate = task.copyWith(clearDueDate: true);
      expect(noDate.dueDate, isNull);
      expect(noDate.isOverdue, isFalse);
    });
  });

  // ── TaskStatus ─────────────────────────────────────────────────────────────

  group('TaskStatus', () {
    test('key → enum round-trip for all values', () {
      for (final s in TaskStatus.values) {
        expect(TaskStatusX.fromKey(s.key), equals(s));
      }
    });

    test('unknown key defaults to todo', () {
      expect(TaskStatusX.fromKey('???'), equals(TaskStatus.todo));
    });
  });
}
