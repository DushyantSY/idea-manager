// lib/presentation/widgets/widgets.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/idea_model.dart';
import '../../data/models/task_model.dart';

// ─── Priority Badge ───────────────────────────────────────────────────────────

class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool compact;
  const PriorityBadge({super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.priorityColor(priority.key);
    final icon = switch (priority) {
      Priority.high   => Icons.arrow_upward_rounded,
      Priority.medium => Icons.remove_rounded,
      Priority.low    => Icons.arrow_downward_rounded,
    };
    if (compact) return Icon(icon, size: 16, color: color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(priority.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─── Status Chips ─────────────────────────────────────────────────────────────

class IdeaStatusChip extends StatelessWidget {
  final IdeaStatus status;
  const IdeaStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.ideaStatusColor(status.key);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class TaskStatusChip extends StatelessWidget {
  final TaskStatus status;
  const TaskStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.taskStatusColor(status.key);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── Star Rating ──────────────────────────────────────────────────────────────

class StarRatingDisplay extends StatelessWidget {
  final int rating;
  final double size;
  const StarRatingDisplay({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: i < rating ? Colors.amber : Colors.grey.shade400,
      )),
    );
  }
}

class StarRatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarRatingPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 32,
              color: i < value ? Colors.amber : Colors.grey.shade400,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Idea Card ────────────────────────────────────────────────────────────────

class IdeaCard extends StatelessWidget {
  final IdeaModel idea;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const IdeaCard({super.key, required this.idea, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(idea.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                PriorityBadge(priority: idea.priority, compact: true),
              ]),
              if (idea.description != null && idea.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(idea.description!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurface.withAlpha(153)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(children: [
                IdeaStatusChip(status: idea.status),
                const SizedBox(width: 8),
                StarRatingDisplay(rating: idea.rating),
                const Spacer(),
                Text(AppDateUtils.formatRelative(idea.createdAt),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurface.withAlpha(115))),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18, color: cs.error.withAlpha(179)),
                  ),
                ),
              ]),
              if (idea.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: idea.tags.take(4).map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Task Card ────────────────────────────────────────────────────────────────

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onStatusTap;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusTap,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final done = task.status == TaskStatus.done;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            GestureDetector(
              onTap: onStatusTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppTheme.taskDone
                      : AppTheme.taskStatusColor(task.status.key).withAlpha(38),
                  border: Border.all(
                      color: AppTheme.taskStatusColor(task.status.key), width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? cs.onSurface.withAlpha(102) : cs.onSurface,
                      )),
                  if (task.ideaTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('↳ ${task.ideaTitle}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.primary.withAlpha(179))),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.schedule_rounded,
                          size: 12,
                          color: task.isOverdue
                              ? cs.error
                              : cs.onSurface.withAlpha(128)),
                      const SizedBox(width: 3),
                      Text(AppDateUtils.formatShort(task.dueDate!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: task.isOverdue
                                ? cs.error
                                : cs.onSurface.withAlpha(128),
                            fontWeight: task.isOverdue
                                ? FontWeight.w700
                                : FontWeight.normal,
                          )),
                    ]),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: cs.error.withAlpha(179)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: cs.primary.withAlpha(64)),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withAlpha(153),
                    ),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurface.withAlpha(102)),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Text(title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary,
                )),
        if (trailing != null) ...[const Spacer(), trailing!],
      ]),
    );
  }
}

// ─── Pros / Cons ──────────────────────────────────────────────────────────────

class ProsConsSection extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  const ProsConsSection({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
    required this.onChanged,
  });

  @override
  State<ProsConsSection> createState() => _ProsConsSectionState();
}

class _ProsConsSectionState extends State<ProsConsSection> {
  final _ctrl = TextEditingController();

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onChanged([...widget.items, text]);
    _ctrl.clear();
  }

  void _remove(int index) {
    final updated = List<String>.from(widget.items)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(widget.icon, size: 18, color: widget.color),
          const SizedBox(width: 6),
          Text(widget.label,
              style: TextStyle(fontWeight: FontWeight.w700, color: widget.color)),
        ]),
        const SizedBox(height: 8),
        ...widget.items.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(Icons.circle, size: 6, color: widget.color),
            const SizedBox(width: 8),
            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14))),
            GestureDetector(
              onTap: () => _remove(e.key),
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
            ),
          ]),
        )),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Add ${widget.label.toLowerCase()}...',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _add(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _add,
            icon: const Icon(Icons.add, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              minimumSize: const Size(36, 36),
            ),
          ),
        ]),
      ],
    );
  }
}

// ─── Tag Input ────────────────────────────────────────────────────────────────

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  const TagInputField({super.key, required this.tags, required this.onChanged});

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _ctrl = TextEditingController();

  void _add() {
    final text = _ctrl.text.trim().toLowerCase();
    if (text.isEmpty || widget.tags.contains(text)) return;
    widget.onChanged([...widget.tags, text]);
    _ctrl.clear();
  }

  void _remove(String tag) =>
      widget.onChanged(widget.tags.where((t) => t != tag).toList());

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: widget.tags.map((tag) => Chip(
            label: Text(tag, style: const TextStyle(fontSize: 12)),
            onDeleted: () => _remove(tag),
            deleteIconColor: Colors.grey.shade600,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          )).toList(),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Add tag and press ↵',
                isDense: true,
                prefixIcon: Icon(Icons.tag, size: 16),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _add(),
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _add,
            icon: const Icon(Icons.add, size: 18),
            style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
          ),
        ]),
      ],
    );
  }
}
