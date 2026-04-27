// lib/core/constants/app_constants.dart
// Central place for all app-wide constants.

class AppConstants {
  AppConstants._();

  static const String appName = 'Idea Manager';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'idea_manager.db';
  static const int dbVersion = 1;

  // Table names
  static const String ideasTable = 'ideas';
  static const String tasksTable = 'tasks';

  // SharedPreferences keys
  static const String prefDarkMode = 'dark_mode';
  static const String prefSortOrder = 'sort_order';
  static const String prefFilterStatus = 'filter_status';

  // Export
  static const String exportFileName = 'idea_manager_export';

  // UI
  static const double cardRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Idea status labels
  static const Map<String, String> ideaStatusLabels = {
    'new': 'New',
    'thinking': 'Thinking',
    'planned': 'Planned',
    'archived': 'Archived',
  };

  // Priority labels
  static const Map<String, String> priorityLabels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
  };

  // Task status labels
  static const Map<String, String> taskStatusLabels = {
    'todo': 'To-Do',
    'in_progress': 'In Progress',
    'done': 'Done',
  };
}
