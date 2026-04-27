// lib/data/models/idea_model.dart
// Immutable data model for an Idea, with full SQLite (de)serialization.

import 'dart:convert';

/// Status lifecycle of an idea.
enum IdeaStatus { newIdea, thinking, planned, archived }

extension IdeaStatusX on IdeaStatus {
  String get key {
    switch (this) {
      case IdeaStatus.thinking: return 'thinking';
      case IdeaStatus.planned:  return 'planned';
      case IdeaStatus.archived: return 'archived';
      default:                  return 'new';
    }
  }

  String get label {
    switch (this) {
      case IdeaStatus.thinking: return 'Thinking';
      case IdeaStatus.planned:  return 'Planned';
      case IdeaStatus.archived: return 'Archived';
      default:                  return 'New';
    }
  }

  static IdeaStatus fromKey(String key) {
    switch (key) {
      case 'thinking': return IdeaStatus.thinking;
      case 'planned':  return IdeaStatus.planned;
      case 'archived': return IdeaStatus.archived;
      default:         return IdeaStatus.newIdea;
    }
  }
}

/// Priority level of an idea.
enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get key {
    switch (this) {
      case Priority.medium: return 'medium';
      case Priority.high:   return 'high';
      default:              return 'low';
    }
  }

  String get label {
    switch (this) {
      case Priority.medium: return 'Medium';
      case Priority.high:   return 'High';
      default:              return 'Low';
    }
  }

  static Priority fromKey(String key) {
    switch (key) {
      case 'medium': return Priority.medium;
      case 'high':   return Priority.high;
      default:       return Priority.low;
    }
  }
}

/// Core idea entity stored in SQLite.
class IdeaModel {
  final String id;
  final String title;
  final String? description;
  final String? notes;
  final IdeaStatus status;
  final Priority priority;
  final int rating;           // 1–5
  final List<String> tags;
  final String? category;
  final List<String> pros;
  final List<String> cons;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IdeaModel({
    required this.id,
    required this.title,
    this.description,
    this.notes,
    this.status = IdeaStatus.newIdea,
    this.priority = Priority.medium,
    this.rating = 3,
    this.tags = const [],
    this.category,
    this.pros = const [],
    this.cons = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Serialization ──────────────────────────────────────────────────────────

  /// Converts model to a Map suitable for SQLite insertion.
  Map<String, dynamic> toMap() => {
        'id':          id,
        'title':       title,
        'description': description,
        'notes':       notes,
        'status':      status.key,
        'priority':    priority.key,
        'rating':      rating,
        // Lists stored as JSON strings in SQLite TEXT columns
        'tags':        jsonEncode(tags),
        'category':    category,
        'pros':        jsonEncode(pros),
        'cons':        jsonEncode(cons),
        'created_at':  createdAt.toIso8601String(),
        'updated_at':  updatedAt.toIso8601String(),
      };

  /// Reconstructs model from a SQLite row map.
  factory IdeaModel.fromMap(Map<String, dynamic> map) => IdeaModel(
        id:          map['id'] as String,
        title:       map['title'] as String,
        description: map['description'] as String?,
        notes:       map['notes'] as String?,
        status:      IdeaStatusX.fromKey(map['status'] as String? ?? 'new'),
        priority:    PriorityX.fromKey(map['priority'] as String? ?? 'medium'),
        rating:      (map['rating'] as int?) ?? 3,
        tags:        _decodeList(map['tags']),
        category:    map['category'] as String?,
        pros:        _decodeList(map['pros']),
        cons:        _decodeList(map['cons']),
        createdAt:   DateTime.parse(map['created_at'] as String),
        updatedAt:   DateTime.parse(map['updated_at'] as String),
      );

  static List<String> _decodeList(dynamic raw) {
    if (raw == null || raw == '') return [];
    try {
      return List<String>.from(jsonDecode(raw as String));
    } catch (_) {
      return [];
    }
  }

  // ── Immutable updates ──────────────────────────────────────────────────────

  IdeaModel copyWith({
    String? title,
    String? description,
    String? notes,
    IdeaStatus? status,
    Priority? priority,
    int? rating,
    List<String>? tags,
    String? category,
    List<String>? pros,
    List<String>? cons,
  }) =>
      IdeaModel(
        id:          id,
        title:       title       ?? this.title,
        description: description ?? this.description,
        notes:       notes       ?? this.notes,
        status:      status      ?? this.status,
        priority:    priority    ?? this.priority,
        rating:      rating      ?? this.rating,
        tags:        tags        ?? this.tags,
        category:    category    ?? this.category,
        pros:        pros        ?? this.pros,
        cons:        cons        ?? this.cons,
        createdAt:   createdAt,
        updatedAt:   DateTime.now(),
      );

  @override
  String toString() => 'IdeaModel(id: $id, title: $title, status: ${status.key})';
}
