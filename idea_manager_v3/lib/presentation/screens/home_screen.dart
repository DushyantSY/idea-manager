// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'add_edit_idea_screen.dart';
import 'idea_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Idea?'),
        content: Text('Delete "$title"? All linked tasks will also be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(ideaActionsProvider.notifier).delete(id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    final settings = ref.read(settingsProvider).value;
    showModalBottomSheet(
      context: context,
      builder: (_) => _SortFilterSheet(
        currentSort: settings?.sortBy ?? 'created_at',
        currentFilter: settings?.statusFilter ?? 'all',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ideasAsync = ref.watch(ideasProvider);
    final settings = ref.watch(settingsProvider).value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search ideas...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) =>
                    ref.read(searchQueryProvider.notifier).state = val,
              )
            : const Text('Ideas'),
        actions: [
          IconButton(
            icon: Icon(_searchVisible
                ? Icons.close_rounded
                : Icons.search_rounded),
            onPressed: () {
              setState(() => _searchVisible = !_searchVisible);
              if (!_searchVisible) {
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Sort & Filter',
            onPressed: _showSortSheet,
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: 'All Tasks',
            onPressed: () => Navigator.pushNamed(context, '/tasks'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (settings != null && settings.statusFilter != 'all')
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Filter: ${settings.statusFilter}',
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .setStatusFilter('all'),
                    child: Icon(Icons.close, size: 14, color: cs.primary),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ideasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (ideas) {
                if (ideas.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'No ideas yet',
                    subtitle: 'Tap the + button to capture your first idea!',
                    action: FilledButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AddEditIdeaScreen())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Idea'),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(ideasProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: ideas.length,
                    itemBuilder: (ctx, i) {
                      final idea = ideas[i];
                      return IdeaCard(
                        idea: idea,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  IdeaDetailScreen(ideaId: idea.id)),
                        ),
                        onDelete: () =>
                            _confirmDelete(idea.id, idea.title),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddEditIdeaScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Idea'),
      ),
    );
  }
}

class _SortFilterSheet extends ConsumerWidget {
  final String currentSort;
  final String currentFilter;
  const _SortFilterSheet(
      {required this.currentSort, required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sort By',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: const [
              ('created_at', 'Date'),
              ('priority', 'Priority'),
              ('rating', 'Rating'),
            ].map((item) => ChoiceChip(
                  label: Text(item.$2),
                  selected: currentSort == item.$1,
                  onSelected: (_) {
                    notifier.setSortBy(item.$1);
                    Navigator.pop(context);
                  },
                )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Filter by Status',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ('all', 'All', null),
              ('new', 'New', AppTheme.statusNew),
              ('thinking', 'Thinking', AppTheme.statusThinking),
              ('planned', 'Planned', AppTheme.statusPlanned),
              ('archived', 'Archived', AppTheme.statusArchived),
            ].map((item) => ChoiceChip(
                  label: Text(item.$2),
                  selected: currentFilter == item.$1,
                  selectedColor: item.$3?.withAlpha(51),
                  onSelected: (_) {
                    notifier.setStatusFilter(item.$1);
                    Navigator.pop(context);
                  },
                )).toList(),
          ),
        ],
      ),
    );
  }
}
