// lib/presentation/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_model.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  static const _filters = [
    ('all', 'All'),
    ('todo', 'To-Do'),
    ('in_progress', 'In Progress'),
    ('done', 'Done'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(taskStatusFilterProvider);
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Tasks')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: _filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.$2),
                          selected: selectedFilter == f.$1,
                          onSelected: (_) => ref
                              .read(taskStatusFilterProvider.notifier)
                              .state = f.$1,
                          showCheckmark: true,
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.checklist_rounded,
                    title: selectedFilter == 'all'
                        ? 'No tasks yet'
                        : 'No ${_filters.firstWhere((f) => f.$1 == selectedFilter).$2} tasks',
                    subtitle: "Add tasks from an idea's detail screen.",
                  );
                }

                final todo =
                    tasks.where((t) => t.status == TaskStatus.todo).toList();
                final inProg = tasks
                    .where((t) => t.status == TaskStatus.inProgress)
                    .toList();
                final done =
                    tasks.where((t) => t.status == TaskStatus.done).toList();

                return ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    if (todo.isNotEmpty && selectedFilter == 'all') ...[
                      SectionHeader(title: 'To-Do (${todo.length})'),
                      ..._taskCards(ref, todo),
                    ],
                    if (inProg.isNotEmpty && selectedFilter == 'all') ...[
                      SectionHeader(
                          title: 'In Progress (${inProg.length})'),
                      ..._taskCards(ref, inProg),
                    ],
                    if (done.isNotEmpty && selectedFilter == 'all') ...[
                      SectionHeader(title: 'Done (${done.length})'),
                      ..._taskCards(ref, done),
                    ],
                    if (selectedFilter != 'all') ..._taskCards(ref, tasks),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _taskCards(WidgetRef ref, List<TaskModel> tasks) {
    return tasks
        .map((task) => TaskCard(
              task: task,
              onStatusTap: () =>
                  ref.read(taskActionsProvider.notifier).cycleStatus(task),
              onDelete: () =>
                  ref.read(taskActionsProvider.notifier).delete(task),
            ))
        .toList();
  }
}
