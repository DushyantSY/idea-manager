// lib/core/utils/app_utils.dart
// Date formatting helpers and export helpers.

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../data/models/idea_model.dart';
import '../../data/models/task_model.dart';

// ─── Date Utils ─────────────────────────────────────────────────────────────

class AppDateUtils {
  AppDateUtils._();

  static final _full   = DateFormat('MMM d, yyyy • h:mm a');
  static final _short  = DateFormat('MMM d, yyyy');
  static final _time   = DateFormat('h:mm a');
  static final _iso    = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static String formatFull(DateTime dt)  => _full.format(dt);
  static String formatShort(DateTime dt) => _short.format(dt);
  static String formatTime(DateTime dt)  => _time.format(dt);
  static String formatIso(DateTime dt)   => _iso.format(dt);

  /// Returns a human-friendly relative label: "Today", "Yesterday", or date.
  static String formatRelative(DateTime dt) {
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return 'Today, ${_time.format(dt)}';
    if (diff == 1) return 'Yesterday';
    return _short.format(dt);
  }
}

// ─── Export Utils ────────────────────────────────────────────────────────────

class ExportUtils {
  ExportUtils._();

  /// Exports ideas + tasks as a JSON file and shares it via system share sheet.
  static Future<void> exportAsJson(
    List<IdeaModel> ideas,
    List<TaskModel> tasks,
  ) async {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'ideas': ideas.map((e) => e.toMap()).toList(),
      'tasks': tasks.map((e) => e.toMap()).toList(),
    };
    final json     = const JsonEncoder.withIndent('  ').convert(payload);
    final dir      = await getTemporaryDirectory();
    final fileName = 'idea_manager_${DateTime.now().millisecondsSinceEpoch}.json';
    final file     = File('${dir.path}/$fileName');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)], text: 'Idea Manager Export');
  }

  /// Exports ideas as a CSV file and shares it.
  static Future<void> exportAsCsv(List<IdeaModel> ideas) async {
    final header = [
      'ID', 'Title', 'Description', 'Status', 'Priority',
      'Rating', 'Tags', 'Category', 'CreatedAt', 'UpdatedAt',
    ];
    final rows = ideas.map((idea) => [
      idea.id,
      _escape(idea.title),
      _escape(idea.description ?? ''),
      idea.status,
      idea.priority,
      idea.rating.toString(),
      idea.tags.join(';'),
      idea.category ?? '',
      idea.createdAt.toIso8601String(),
      idea.updatedAt.toIso8601String(),
    ]).toList();

    final buffer = StringBuffer();
    buffer.writeln(header.join(','));
    for (final row in rows) {
      buffer.writeln(row.join(','));
    }

    final dir      = await getTemporaryDirectory();
    final fileName = 'ideas_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file     = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Ideas CSV Export');
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
