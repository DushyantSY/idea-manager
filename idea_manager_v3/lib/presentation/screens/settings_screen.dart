// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../data/database/database_helper.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          children: [
            const _SectionTitle('Appearance'),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark colour scheme'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: settings.darkMode,
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleDarkMode(),
            ),
            const Divider(),
            const _SectionTitle('Data'),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export as JSON'),
              subtitle: const Text('All ideas and tasks in JSON format'),
              onTap: () => _exportJson(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export Ideas as CSV'),
              subtitle: const Text('Spreadsheet-compatible export'),
              onTap: () => _exportCsv(context, ref),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Reset All Data',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              subtitle: const Text('Permanently deletes all ideas and tasks'),
              onTap: () => _confirmReset(context, ref),
            ),
            const Divider(),
            const _SectionTitle('About'),
            ListTile(
              leading: const Icon(Icons.info_outlined),
              title: const Text('App Version'),
              trailing: Text(
                AppConstants.appVersion,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy'),
              subtitle: Text('No tracking • No ads • Fully offline'),
            ),
            const ListTile(
              leading: Icon(Icons.code_rounded),
              title: Text('Technology'),
              subtitle: Text('Built with Flutter & SQLite'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportJson(BuildContext ctx, WidgetRef ref) async {
    try {
      final data  = await DatabaseHelper.instance.exportAll();
      final ideas = data['ideas'] as List;
      final tasks = data['tasks'] as List;
      await ExportUtils.exportAsJson(ideas.cast(), tasks.cast());
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportCsv(BuildContext ctx, WidgetRef ref) async {
    try {
      final data  = await DatabaseHelper.instance.exportAll();
      final ideas = data['ideas'] as List;
      await ExportUtils.exportAsCsv(ideas.cast());
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _confirmReset(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete ALL ideas and tasks. '
          'This action cannot be undone.\n\nConsider exporting first.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearAllData();
              ref.invalidate(ideasProvider);
              ref.invalidate(allTasksProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('All data has been reset.')));
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
