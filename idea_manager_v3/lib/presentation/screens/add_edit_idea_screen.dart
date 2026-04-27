// lib/presentation/screens/add_edit_idea_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/idea_model.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class AddEditIdeaScreen extends ConsumerStatefulWidget {
  final IdeaModel? idea;
  const AddEditIdeaScreen({super.key, this.idea});

  @override
  ConsumerState<AddEditIdeaScreen> createState() => _AddEditIdeaScreenState();
}

class _AddEditIdeaScreenState extends ConsumerState<AddEditIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.idea != null;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _categoryCtrl;

  late IdeaStatus _status;
  late Priority _priority;
  late int _rating;
  late List<String> _tags;
  late List<String> _pros;
  late List<String> _cons;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final idea = widget.idea;
    _titleCtrl    = TextEditingController(text: idea?.title ?? '');
    _descCtrl     = TextEditingController(text: idea?.description ?? '');
    _notesCtrl    = TextEditingController(text: idea?.notes ?? '');
    _categoryCtrl = TextEditingController(text: idea?.category ?? '');
    _status   = idea?.status   ?? IdeaStatus.newIdea;
    _priority = idea?.priority ?? Priority.medium;
    _rating   = idea?.rating   ?? 3;
    _tags     = List.from(idea?.tags ?? []);
    _pros     = List.from(idea?.pros ?? []);
    _cons     = List.from(idea?.cons ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _notesCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final actions = ref.read(ideaActionsProvider.notifier);
      if (_isEdit) {
        await actions.update(widget.idea!.copyWith(
          title:       _titleCtrl.text,
          description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
          notes:       _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          status: _status, priority: _priority, rating: _rating,
          tags: _tags,
          category: _categoryCtrl.text.isEmpty ? null : _categoryCtrl.text,
          pros: _pros, cons: _cons,
        ));
      } else {
        await actions.create(
          title:       _titleCtrl.text,
          description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
          notes:       _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          status: _status, priority: _priority, rating: _rating,
          tags: _tags,
          category: _categoryCtrl.text.isEmpty ? null : _categoryCtrl.text,
          pros: _pros, cons: _cons,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving idea: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Idea' : 'New Idea'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _label('Title *'),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: "What's your idea?",
                prefixIcon: Icon(Icons.lightbulb_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _label('Description'),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'Describe your idea in more detail...',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Status'),
                  DropdownButtonFormField<IdeaStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12)),
                    items: IdeaStatus.values
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Priority'),
                  DropdownButtonFormField<Priority>(
                    value: _priority,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12)),
                    items: Priority.values
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Row(children: [
                                PriorityBadge(priority: p, compact: true),
                                const SizedBox(width: 6),
                                Text(p.label),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _priority = v ?? _priority),
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 16),
            _label('Rating'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(102),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withAlpha(77)),
              ),
              child: Row(children: [
                StarRatingPicker(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(width: 12),
                Text('$_rating / 5',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            _label('Category'),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Business, Health, Tech...',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _label('Tags'),
            TagInputField(
              tags: _tags,
              onChanged: (v) => setState(() => _tags = v),
            ),
            const SizedBox(height: 20),
            ProsConsSection(
              label: 'Pros',
              icon: Icons.thumb_up_outlined,
              color: AppTheme.priorityLow,
              items: _pros,
              onChanged: (v) => setState(() => _pros = v),
            ),
            const SizedBox(height: 20),
            ProsConsSection(
              label: 'Cons',
              icon: Icons.thumb_down_outlined,
              color: AppTheme.priorityHigh,
              items: _cons,
              onChanged: (v) => setState(() => _cons = v),
            ),
            const SizedBox(height: 20),
            _label('Notes'),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                hintText: 'Additional notes, bullet points...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_isEdit ? 'Update Idea' : 'Save Idea'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600)),
  );
}
