// lib/presentation/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/idea_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/idea_repository.dart';
import '../../core/constants/app_constants.dart';

// ─── Repository Providers ─────────────────────────────────────────────────────

final ideaRepositoryProvider = Provider<IdeaRepository>((_) => IdeaRepository());
final taskRepositoryProvider = Provider<TaskRepository>((_) => TaskRepository());

// ─── Settings Provider ────────────────────────────────────────────────────────

class SettingsState {
  final bool darkMode;
  final String sortBy;
  final String statusFilter;

  const SettingsState({
    required this.darkMode,
    required this.sortBy,
    required this.statusFilter,
  });

  SettingsState copyWith({
    bool? darkMode,
    String? sortBy,
    String? statusFilter,
  }) =>
      SettingsState(
        darkMode:     darkMode     ?? this.darkMode,
        sortBy:       sortBy       ?? this.sortBy,
        statusFilter: statusFilter ?? this.statusFilter,
      );
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return SettingsState(
        darkMode:     prefs.getBool(AppConstants.prefDarkMode)       ?? false,
        sortBy:       prefs.getString(AppConstants.prefSortOrder)    ?? 'created_at',
        statusFilter: prefs.getString(AppConstants.prefFilterStatus) ?? 'all',
      );
    } catch (e) {
      debugPrint('Settings load error: $e');
      return const SettingsState(
        darkMode: false,
        sortBy: 'created_at',
        statusFilter: 'all',
      );
    }
  }

  Future<void> toggleDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = !(state.value?.darkMode ?? false);
      await prefs.setBool(AppConstants.prefDarkMode, val);
      state = AsyncData(state.value!.copyWith(darkMode: val));
    } catch (e) {
      debugPrint('toggleDarkMode error: $e');
    }
  }

  Future<void> setSortBy(String sortBy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefSortOrder, sortBy);
      state = AsyncData(state.value!.copyWith(sortBy: sortBy));
    } catch (e) {
      debugPrint('setSortBy error: $e');
    }
  }

  Future<void> setStatusFilter(String filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefFilterStatus, filter);
      state = AsyncData(state.value!.copyWith(statusFilter: filter));
    } catch (e) {
      debugPrint('setStatusFilter error: $e');
    }
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(
        SettingsNotifier.new);

// ─── Search Query ─────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((_) => '');

// ─── Ideas Provider ───────────────────────────────────────────────────────────

final ideasProvider = FutureProvider<List<IdeaModel>>((ref) async {
  try {
    final repo     = ref.watch(ideaRepositoryProvider);
    final query    = ref.watch(searchQueryProvider);
    final settings = await ref.watch(settingsProvider.future);

    return repo.getAll(
      search:       query.isEmpty ? null : query,
      statusFilter: settings.statusFilter,
      sortBy:       settings.sortBy,
      descending:   true,
    );
  } catch (e) {
    debugPrint('ideasProvider error: $e');
    return [];
  }
});

// ─── Tasks Providers ──────────────────────────────────────────────────────────

final taskStatusFilterProvider = StateProvider<String>((_) => 'all');

final allTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try {
    final repo   = ref.watch(taskRepositoryProvider);
    final filter = ref.watch(taskStatusFilterProvider);
    return repo.getAll(statusFilter: filter == 'all' ? null : filter);
  } catch (e) {
    debugPrint('allTasksProvider error: $e');
    return [];
  }
});

final ideaTasksProvider =
    FutureProvider.family<List<TaskModel>, String>((ref, ideaId) async {
  try {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.getForIdea(ideaId);
  } catch (e) {
    debugPrint('ideaTasksProvider error: $e');
    return [];
  }
});

// ─── Idea Actions ─────────────────────────────────────────────────────────────

class IdeaActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  IdeaRepository get _repo => ref.read(ideaRepositoryProvider);

  Future<IdeaModel> create({
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
    final idea = await _repo.createIdea(
      title: title, description: description, notes: notes,
      status: status, priority: priority, rating: rating,
      tags: tags, category: category, pros: pros, cons: cons,
    );
    ref.invalidate(ideasProvider);
    return idea;
  }

  Future<IdeaModel> update(IdeaModel idea) async {
    final updated = await _repo.updateIdea(idea);
    ref.invalidate(ideasProvider);
    return updated;
  }

  Future<void> delete(String id) async {
    await _repo.deleteIdea(id);
    ref.invalidate(ideasProvider);
    ref.invalidate(allTasksProvider);
  }
}

final ideaActionsProvider =
    NotifierProvider<IdeaActionsNotifier, void>(IdeaActionsNotifier.new);

// ─── Task Actions ─────────────────────────────────────────────────────────────

class TaskActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  void _invalidate(String ideaId) {
    ref.invalidate(allTasksProvider);
    ref.invalidate(ideaTasksProvider(ideaId));
  }

  Future<TaskModel> create({
    required String ideaId,
    required String ideaTitle,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
  }) async {
    final task = await _repo.createTask(
      ideaId: ideaId, ideaTitle: ideaTitle, title: title,
      description: description, status: status, dueDate: dueDate,
    );
    _invalidate(ideaId);
    return task;
  }

  Future<TaskModel> update(TaskModel task) async {
    final updated = await _repo.updateTask(task);
    _invalidate(task.ideaId);
    return updated;
  }

  Future<TaskModel> cycleStatus(TaskModel task) async {
    final updated = await _repo.cycleStatus(task);
    _invalidate(task.ideaId);
    return updated;
  }

  Future<void> delete(TaskModel task) async {
    await _repo.deleteTask(task.id);
    _invalidate(task.ideaId);
  }
}

final taskActionsProvider =
    NotifierProvider<TaskActionsNotifier, void>(TaskActionsNotifier.new);
