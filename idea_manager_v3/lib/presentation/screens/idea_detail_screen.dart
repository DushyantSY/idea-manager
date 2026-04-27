// lib/presentation/screens/idea_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/idea_model.dart';
import '../../data/models/task_model.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'add_edit_idea_screen.dart';

class IdeaDetailScreen extends ConsumerWidget {
  final String ideaId;
  const IdeaDetailScreen({super.key, required this.ideaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideaAsync = ref.watch(ideasProvider).whenData(
          (list) => list.firstWhere(
            (i) => i.id == ideaId,
            orElse: () => throw StateError('Idea not found'),
          ),
        );
    final tasksAsync = ref.watch(ideaTasksProvider(ideaId));

    return ideaAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Idea not found: $e'))),
      data: (idea) => _IdeaDetailBody(idea: idea, tasksAsync: tasksAsync),
    );
  }
}

class _IdeaDetailBody extends ConsumerStatefulWidget {
  final IdeaModel idea;
  final AsyncValue<List<TaskModel>> tasksAsync;
  const _IdeaDetailBody({required this.idea, required this.tasksAsync});

  @override
  ConsumerState<_IdeaDetailBody> createState() => _IdeaDetailBodyState();
}

class _IdeaDetailBodyState extends ConsumerState<_IdeaDetailBody> {
  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Task to Idea',
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Task title *',
                    prefixIcon: Icon(Icons.check_box_outline_blank_rounded)),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_rounded)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSt(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(dueDate == null
                    ? 'Set due date (optional)'
                    : 'Due: ${AppDateUtils.formatShort(dueDate!)}'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    await ref.read(taskActionsProvider.notifier).create(
                          ideaId: widget.idea.id,
                          ideaTitle: widget.idea.title,
                          title: title,
                          description: descCtrl.text.isEmpty
                              ? null
                              : descCtrl.text,
                          dueDate: dueDate,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => AddEditIdeaScreen(idea: idea))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          Text(idea.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  )),
          const SizedBox(height: 10),
          Row(children: [
            IdeaStatusChip(status: idea.status),
            const SizedBox(width: 8),
            PriorityBadge(priority: idea.priority),
            const SizedBox(width: 8),
            StarRatingDisplay(rating: idea.rating, size: 16),
          ]),
          const SizedBox(height: 6),
          Text(
            'Created ${AppDateUtils.formatFull(idea.createdAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(115),
                ),
          ),

          if (idea.tags.isNotEmpty || idea.category != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (idea.category != null)
                  Chip(
                    avatar: const Icon(Icons.folder_outlined, size: 14),
                    label: Text(idea.category!),
                    visualDensity: VisualDensity.compact,
                  ),
                ...idea.tags.map((t) => Chip(
                      avatar: const Icon(Icons.tag, size: 12),
                      label: Text(t,
                          style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    )),
              ],
            ),
          ],

          if (idea.description != null && idea.description!.isNotEmpty) ...[
            const Divider(height: 32),
            const SectionHeader(title: 'Description'),
            const SizedBox(height: 6),
            Text(idea.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.55)),
          ],

          if (idea.notes != null && idea.notes!.isNotEmpty) ...[
            const Divider(height: 32),
            const SectionHeader(title: 'Notes'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(idea.notes!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.55)),
            ),
          ],

          if (idea.pros.isNotEmpty || idea.cons.isNotEmpty) ...[
            const Divider(height: 32),
            const SectionHeader(title: 'Evaluation'),
            const SizedBox(height: 12),
            if (idea.pros.isNotEmpty) ...[
              _prosConsList(context, idea.pros, 'Pros',
                  Icons.thumb_up_outlined, AppTheme.priorityLow),
              const SizedBox(height: 16),
            ],
            if (idea.cons.isNotEmpty)
              _prosConsList(context, idea.cons, 'Cons',
                  Icons.thumb_down_outlined, AppTheme.priorityHigh),
          ],

          const Divider(height: 32),
          SectionHeader(
            title: 'Tasks',
            trailing: TextButton.icon(
              onPressed: _showAddTaskDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add'),
            ),
          ),

          widget.tasksAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (tasks) {
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.checklist_rounded,
                          size: 40, color: cs.onSurface.withAlpha(51)),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks yet — convert this idea into actions!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: cs.onSurface.withAlpha(102),
                            fontSize: 13),
                      ),
                    ]),
                  ),
                );
              }
              return Column(
                children: tasks
                    .map((task) => TaskCard(
                          task: task,
                          onStatusTap: () => ref
                              .read(taskActionsProvider.notifier)
                              .cycleStatus(task),
                          onDelete: () => ref
                              .read(taskActionsProvider.notifier)
                              .delete(task),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _prosConsList(BuildContext context, List<String> items,
      String label, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(item,
                          style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )),
      ],
    );
  }
}
